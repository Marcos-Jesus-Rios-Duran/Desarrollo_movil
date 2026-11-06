import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:firabase_multimedia/features/media/domain/models/media_item.dart';
import 'package:firabase_multimedia/features/media/domain/repositories/i_media_repository.dart';

/// Representa el estado actual de la operación de subida.
enum UploadStatus {
  /// Sin actividad — estado inicial o post-reset.
  idle,

  /// Seleccionando imagen de la galería.
  picking,

  /// Comprimiendo la imagen seleccionada.
  compressing,

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
  final IMediaRepository _mediaRepository;
  final ImagePicker _imagePicker;
  final Uuid _uuid;

  MediaStore(this._mediaRepository, this._imagePicker, this._uuid);

  List<MediaItem> _galleryItems = [];
  List<MediaItem> get galleryItems => _galleryItems;
  bool _isLoadingGallery = false;
  bool get isLoadingGallery => _isLoadingGallery;
  
  Future<void> loadGallery(GetMediaUseCase getMedia) async {
  _isLoadingGallery = true;
  notifyListeners();
  try {
    _galleryItems = await getMedia.call();
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

  double _progress = 0.0;
  double get progress => _progress;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _lastUploadedUrl;
  String? get lastUploadedUrl => _lastUploadedUrl;

  MediaItem? _lastMediaItem;
  MediaItem? get lastMediaItem => _lastMediaItem;

  bool get isWorking =>
      _status == UploadStatus.picking ||
      _status == UploadStatus.compressing ||
      _status == UploadStatus.uploading ||
      _status == UploadStatus.saving;

  // ─── Pipeline principal ────────────────────────────────────────

  /// Orquesta el flujo completo: pick → compress → upload → save.
  ///
  /// [userId] es requerido para construir la ruta segura en Storage:
  /// `users/{userId}/photos/{uuid.jpg}`
  Future<void> pickAndUploadImage(String userId) async {
    try {
      // ── Paso 1: Seleccionar imagen ──
      _updateStatus(UploadStatus.picking, 0.0);

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        // El usuario canceló la selección
        _updateStatus(UploadStatus.idle, 0.0);
        return;
      }

      // ── Paso 2: Comprimir ──
      _updateStatus(UploadStatus.compressing, 0.25);

      final Uint8List originalBytes = await pickedFile.readAsBytes();
      final Uint8List compressedBytes = await _compressImage(originalBytes);

      // ── Paso 3: Subir a Cloud Storage ──
      _updateStatus(UploadStatus.uploading, 0.50);

      final String downloadUrl = await _mediaRepository.uploadImageBytes(
        compressedBytes,
        userId,
      );

      // ── Paso 4: Guardar documento en Firestore ──
      _updateStatus(UploadStatus.saving, 0.75);

      final mediaItem = MediaItem(
        id: _uuid.v4(),
        name: pickedFile.name,
        imageUrl: downloadUrl,
      );

      await _mediaRepository.saveMediaDocument(mediaItem);

      // ── Éxito ──
      _lastUploadedUrl = downloadUrl;
      _lastMediaItem = mediaItem;
      _updateStatus(UploadStatus.success, 1.0);
    } catch (e) {
      _errorMessage = e.toString();
      _updateStatus(UploadStatus.error, 0.0);
    }
  }

  /// Resetea el estado a [UploadStatus.idle] para permitir
  /// una nueva operación.
  void reset() {
    _status = UploadStatus.idle;
    _progress = 0.0;
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Helpers privados ──────────────────────────────────────────

  void _updateStatus(UploadStatus newStatus, double newProgress) {
    _status = newStatus;
    _progress = newProgress;
    _errorMessage = null;
    notifyListeners();
  }

  /// Comprime la imagen a JPEG con calidad 70 y dimensiones máximas
  /// de 1920px para reducir el payload antes de subir a Storage.
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 1920,
      minHeight: 1080,
      quality: 70,
      format: CompressFormat.jpeg,
    );
    return result;
  }
}

