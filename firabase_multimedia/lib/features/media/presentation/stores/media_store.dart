import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:firabase_multimedia/features/media/domain/models/media_item.dart';
import 'package:firabase_multimedia/features/media/domain/repositories/i_media_repository.dart';
import 'package:firabase_multimedia/features/media/domain/usecases/get_media.dart';

/// Representa el estado actual de la operación de subida.
enum UploadStatus {
  /// Sin actividad — estado inicial o post-reset.
  idle,

  /// Seleccionando imagen de la galería.
  picking,

  /// Comprimiendo la imagen seleccionada.
  compressing,

  /// Imagen seleccionada, pendiente de compresión.
  selected,

  /// Imagen comprimida y lista para subir.
  compressed,

  /// Subiendo bytes a Cloud Storage.
  uploading,

  /// Guardando documento en Firestore.
  saving,

  /// Operación completada exitosamente.
  success,

  /// Ocurrió un error en algún paso.
  error,
}

/// Store (ChangeNotifier) que orquesta el flujo completo de selección,
/// compresión y subida de imágenes multimedia.
///
/// Gestiona un pipeline reactivo:
/// 1. **Pick** → `image_picker` (sin permisos invasivos)
/// 2. **Compress** → `flutter_image_compress` → `Uint8List`
/// 3. **Upload** → `IMediaRepository.uploadImageBytes`
/// 4. **Save** → `IMediaRepository.saveMediaDocument`
class MediaStore extends ChangeNotifier {
  static const int maxUploadBytes = 2 * 1024 * 1024;

  final IMediaRepository _mediaRepository;
  final ImagePicker _imagePicker;
  final Uuid _uuid;
  final GetMediaUseCase _getMedia;

  MediaStore(
    this._mediaRepository,
    this._imagePicker,
    this._uuid,
    this._getMedia,
  );

  List<MediaItem> _galleryItems = [];
  List<MediaItem> get galleryItems => _galleryItems;
  bool _isLoadingGallery = false;
  bool get isLoadingGallery => _isLoadingGallery;

  Future<void> loadGallery(String ownerId) async {
    _isLoadingGallery = true;
    notifyListeners();
    try {
      _galleryItems = await _getMedia.call(ownerId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingGallery = false;
      notifyListeners();
    }
  }

  // ─── Estado reactivo ───────────────────────────────────────────

  UploadStatus _status = UploadStatus.idle;
  UploadStatus get status => _status;

  /// Fracción 0.0–1.0 de la transferencia real.
  /// `null` mientras no hay bytes en vuelo (selección, compresión o guardado).
  double? _progress;
  double? get progress => _progress;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _lastUploadedUrl;
  String? get lastUploadedUrl => _lastUploadedUrl;

  int? _originalSizeBytes;
  int? get originalSizeBytes => _originalSizeBytes;

  int? _compressedSizeBytes;
  int? get compressedSizeBytes => _compressedSizeBytes;

  Uint8List? _selectedBytes;
  Uint8List? _compressedBytes;
  String? _selectedFileName;

  bool get canUpload =>
      _compressedBytes != null &&
      _compressedBytes!.length < maxUploadBytes &&
      !isWorking;

  MediaItem? _lastMediaItem;
  MediaItem? get lastMediaItem => _lastMediaItem;

  bool get isWorking =>
      _status == UploadStatus.picking ||
      _status == UploadStatus.compressing ||
      _status == UploadStatus.uploading ||
      _status == UploadStatus.saving;

  // ─── Pipeline principal ────────────────────────────────────────

  /// Selecciona y mide el archivo original sin subirlo ni comprimirlo.
  Future<void> pickImage({required ImageSource source}) async {
    try {
      _updateStatus(UploadStatus.picking, null);

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
      );

      if (pickedFile == null) {
        reset();
        return;
      }

      final Uint8List originalBytes = await pickedFile.readAsBytes();
      _selectedBytes = originalBytes;
      _selectedFileName = pickedFile.name;
      _originalSizeBytes = originalBytes.length;
      _compressedSizeBytes = null;
      _compressedBytes = null;
      _lastUploadedUrl = null;
      _lastMediaItem = null;
      _updateStatus(UploadStatus.selected, null);
    } catch (e) {
      _updateStatus(UploadStatus.error, 0);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Comprime el archivo seleccionado y deja listo el resultado para subir.
  Future<void> compressSelectedImage() async {
    if (_selectedBytes == null || isWorking) return;

    try {
      _updateStatus(UploadStatus.compressing, null);
      final compressedBytes = await _compressImage(_selectedBytes!);
      _compressedBytes = compressedBytes;
      _compressedSizeBytes = compressedBytes.length;

      if (compressedBytes.length >= maxUploadBytes) {
        _updateStatus(UploadStatus.error, 0);
        _errorMessage = 'La imagen comprimida todavía supera el límite de 2 MB '
            '(${_formatBytes(compressedBytes.length)}).';
        notifyListeners();
        return;
      }

      _updateStatus(UploadStatus.compressed, null);
    } catch (e) {
      _updateStatus(UploadStatus.error, 0);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Sube únicamente una imagen ya comprimida y validada.
  Future<void> uploadCompressedImage(String userId) async {
    if (!canUpload || _compressedBytes == null || _selectedFileName == null) {
      return;
    }

    try {
      _updateStatus(UploadStatus.uploading, 0);
      final downloadUrl = await _mediaRepository.uploadImageBytes(
        _compressedBytes!,
        userId,
        onProgress: (fraction) {
          _updateStatus(
            UploadStatus.uploading,
            fraction.clamp(0.0, 1.0),
          );
        },
      );

      _updateStatus(UploadStatus.saving, null);
      final mediaItem = MediaItem(
        id: _uuid.v4(),
        name: _selectedFileName!,
        imageUrl: downloadUrl,
        ownerId: userId,
      );

      try {
        await _mediaRepository.saveMediaDocument(mediaItem);
      } catch (saveError) {
        await _rollbackUpload(downloadUrl, saveError);
        return;
      }

      _lastUploadedUrl = downloadUrl;
      _lastMediaItem = mediaItem;
      _updateStatus(UploadStatus.success, 1.0);
      await loadGallery(userId);
    } catch (e) {
      _updateStatus(UploadStatus.error, 0);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Si Firestore rechaza el documento, elimina el binario ya subido.
  Future<void> _rollbackUpload(String downloadUrl, Object saveError) async {
    try {
      await _mediaRepository.deleteUploadedImage(downloadUrl);
      _updateStatus(UploadStatus.error, 0);
      _errorMessage =
          'No se pudo guardar el registro. La imagen se eliminó del almacenamiento. $saveError';
    } catch (deleteError) {
      _updateStatus(UploadStatus.error, 0);
      _errorMessage =
          'No se pudo guardar el registro ni eliminar el archivo. $saveError / $deleteError';
    }
    notifyListeners();
  }

  /// Resetea el estado a [UploadStatus.idle] para permitir
  /// una nueva operación.
  void reset() {
    _status = UploadStatus.idle;
    _progress = null;
    _errorMessage = null;
    _originalSizeBytes = null;
    _compressedSizeBytes = null;
    _selectedBytes = null;
    _compressedBytes = null;
    _selectedFileName = null;
    notifyListeners();
  }

  /// Limpia los datos visuales de la cuenta anterior antes de cambiar de usuario.
  void clearSessionData() {
    _galleryItems = [];
    _status = UploadStatus.idle;
    _progress = null;
    _errorMessage = null;
    _lastUploadedUrl = null;
    _lastMediaItem = null;
    _originalSizeBytes = null;
    _compressedSizeBytes = null;
    _selectedBytes = null;
    _compressedBytes = null;
    _selectedFileName = null;
    notifyListeners();
  }

  String _formatBytes(int bytes) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // ─── Helpers privados ──────────────────────────────────────────

  void _updateStatus(UploadStatus newStatus, double? newProgress) {
    _status = newStatus;
    _progress = newProgress;
    _errorMessage = null;
    notifyListeners();
  }

  /// Comprime a JPEG 1080 px y calidad 75 para quedar bajo el límite
  /// de 2 MB que imponen las reglas de Storage.
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 1080,
      minHeight: 1080,
      quality: 75,
      format: CompressFormat.jpeg,
    );
    return result;
  }
}
