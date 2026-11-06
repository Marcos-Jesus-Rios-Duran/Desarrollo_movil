import 'package:flutter/foundation.dart';
import 'package:firabase_multimedia/features/auth/domain/repositories/i_auth_repository.dart';

/// Store (ChangeNotifier) que gestiona el estado de autenticación.
///
/// Encapsula la lógica de login y expone estados reactivos
/// ([isLoading], [userId], [errorMessage]) para que la UI
/// se reconstruya automáticamente vía [Provider].
class AuthStore extends ChangeNotifier {
  final IAuthRepository _authRepository;

  AuthStore(this._authRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _userId;
  String? get userId => _userId;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _userId != null;

  /// Ejecuta el flujo de login anónimo.
  ///
  /// Actualiza [isLoading] durante la operación y notifica
  /// a los listeners en cada cambio de estado.
  Future<bool> signIn() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userId = await _authRepository.signIn();

      if (_userId == null) {
        _errorMessage = 'No se pudo iniciar sesión. Intenta de nuevo.';
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _userId = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return isAuthenticated;
  }

  /// Intenta restaurar la sesión existente sin re-autenticar.
  void tryRestoreSession() {
    _userId = _authRepository.getCurrentUserId();
    notifyListeners();
  }
}

