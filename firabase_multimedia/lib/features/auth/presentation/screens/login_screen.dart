import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firabase_multimedia/features/auth/presentation/stores/auth_store.dart';

/// Pantalla de login con diseño elegante y moderno.
///
/// Utiliza autenticación con Google para crear una sesión segura.
/// Al autenticarse exitosamente, navega a [MediaScreen].
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondary,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  minHeight: size.height * 0.6,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ─── Logo / Icono ─────────────────────────
                    _buildLogo(theme),
                    const SizedBox(height: 16),

                    // ─── Título ───────────────────────────────
                    Text(
                      'Firebase Multimedia',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestión inteligente de medios en la nube',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // ─── Card de Login ────────────────────────
                    _buildLoginCard(context, theme),

                    const SizedBox(height: 24),

                    // ─── Footer ───────────────────────────────
                    Text(
                      'Clean Architecture · Firebase · Flutter',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white38,
                        letterSpacing: 1.5,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.cloud_upload_rounded,
        size: 48,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, ThemeData theme) {
    return Consumer<AuthStore>(
      builder: (context, authStore, _) {
        return Card(
          elevation: 12,
          shadowColor: Colors.black38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono decorativo
                Icon(
                  Icons.lock_open_rounded,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),

                Text(
                  'Bienvenido',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Accede para gestionar tu contenido multimedia de forma segura.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // ─── Mensaje de error ──────────
                if (authStore.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authStore.errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ─── Botón de Login ────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: authStore.isLoading
                        ? null
                        : () => _handleLogin(context, authStore),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: authStore.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_circle_rounded, size: 20),
                              SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  'Continuar con Google',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogin(BuildContext context, AuthStore authStore) async {
    final success = await authStore.signIn();

    if (success && context.mounted) {
      Navigator.of(context).pushReplacementNamed('/media');
    }
  }
}
