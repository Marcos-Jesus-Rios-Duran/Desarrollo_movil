import 'package:firebase_auth/firebase_auth.dart';
import 'package:firabase_multimedia/features/auth/domain/repositories/i_auth_repository.dart';

/// Implementación concreta de [IAuthRepository] usando Firebase Auth.
///
/// Utiliza autenticación anónima para un onboarding rápido.
/// La instancia de [FirebaseAuth] se inyecta por constructor
/// (Inversión de Dependencias).
class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository(this._firebaseAuth);

  @override
  Future<String?> signIn() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      return credential.user?.uid;
    } on FirebaseAuthException catch (_) {
      return null;
    }
  }

  @override
  String? getCurrentUserId() {
    return _firebaseAuth.currentUser?.uid;
  }
}

