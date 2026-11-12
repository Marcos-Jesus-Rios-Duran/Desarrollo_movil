import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firabase_multimedia/features/auth/domain/repositories/i_auth_repository.dart';

/// Implementación concreta de [IAuthRepository] usando Firebase Auth.
///
/// Utiliza autenticación con Google para crear una sesión identificable.
/// La instancia de [FirebaseAuth] se inyecta por constructor
/// (Inversión de Dependencias).
class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository(this._firebaseAuth);

  @override
  Future<String?> signIn() async {
    try {
      if (kIsWeb) {
        final userCredential = await _firebaseAuth.signInWithPopup(
          GoogleAuthProvider(),
        );
        return userCredential.user?.uid;
      }

      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final userCredential = await _firebaseAuth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: googleAuth.idToken),
      );

      return userCredential.user?.uid;
    } on FirebaseAuthException catch (_) {
      return null;
    } on GoogleSignInException catch (_) {
      return null;
    } on UnsupportedError catch (_) {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }
  }

  @override
  String? getCurrentUserId() {
    return _firebaseAuth.currentUser?.uid;
  }
}
