/// Contrato abstracto para el repositorio de autenticación.
///
/// Siguiendo el principio de Inversión de Dependencias (SOLID-D),
/// la capa de dominio define la interfaz; la capa de datos la implementa.
abstract class IAuthRepository {
  /// Inicia sesión de forma anónima.
  ///
  /// Retorna el `userId` (UID) si el login fue exitoso,
  /// o `null` si falló.
  Future<String?> signIn();

  /// Obtiene el UID del usuario actualmente autenticado.
  ///
  /// Retorna `null` si no hay sesión activa.
  String? getCurrentUserId();
}

