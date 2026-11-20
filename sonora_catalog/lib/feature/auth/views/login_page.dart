import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sonora_catalog/feature/auth/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final AuthService auth;
  const LoginPage({super.key, required this.auth});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _busy = false;
  String _error = '';

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      await widget.auth.signInWithGoogle();
      // AuthGate cambia solo a la pantalla del catálogo.
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled && mounted) {
        setState(() => _error = 'No se pudo entrar con Google.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = AuthService.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Sonora Catalog',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _google,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Continuar con Google'),
                  ),
                ),
                if (_error.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    _error,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
