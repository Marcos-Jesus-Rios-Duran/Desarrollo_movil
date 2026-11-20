import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth;
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  // Client ID web (client_type 3 de tu google-services.json).
  static const String _webClientId =
      '528637650617-kjbuviustbg424jgkvi0cmaiufc304di.apps.googleusercontent.com';
  static bool _googleReady = false;

  Stream<User?> get authState => _auth.authStateChanges();

  Future<void> signInWithGoogle() async {
    if (!_googleReady) {
      await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
      _googleReady = true;
    }
    final GoogleSignInAccount account = await GoogleSignIn.instance
        .authenticate();
    final String? idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Google no devolvió idToken.',
      );
    }
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  /// Traduce los códigos de FirebaseAuth a mensajes para el usuario.
  static String message(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Sin conexión. El primer inicio de sesión requiere internet.';
      case 'account-exists-with-different-credential':
        return 'Esa cuenta ya existe con otro método de acceso.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      default:
        return 'Error de autenticación (${e.code}).';
    }
  }
}
