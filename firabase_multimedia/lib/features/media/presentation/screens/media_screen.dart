import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firabase_multimedia/features/auth/presentation/stores/auth_store.dart';
import 'package:firabase_multimedia/features/media/presentation/stores/media_store.dart';

/// Pantalla principal de gestión multimedia.
///
/// Diseño elegante y responsivo que incluye:
/// - Botón moderno para abrir la galería.
/// - Indicador visual de progreso reactivo al [MediaStore].
/// - Previsualización de la imagen subida con [CachedNetworkImage]
///   y placeholder tipo shimmer.
class MediaScreen extends StatelessWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context, theme),
      body: SafeArea(
        child: Consumer<MediaStore>(
          builder: (context, mediaStore, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── Header informativo ──────────────────
                      _buildHeaderSection(theme),
                      const SizedBox(height: 24),

                      // ─── Indicador de progreso ───────────────
                      if (mediaStore.isWorking)
                        _buildProgressSection(theme, mediaStore),

                      // ─── Mensaje de error ────────────────────
                      if (mediaStore.status == UploadStatus.error)
                        _buildErrorSection(theme, mediaStore),

                      // ─── Mensaje de éxito ────────────────────
                      if (mediaStore.status == UploadStatus.success)
                        _buildSuccessSection(theme),

                      // ─── Previsualización de imagen ──────────
                      if (mediaStore.lastUploadedUrl != null)
                        _buildImagePreview(theme, mediaStore),

                      const SizedBox(height: 32),

                      // ─── Botón de acción principal ───────────
                      _buildUploadButton(context, theme, mediaStore),

                      const SizedBox(height: 16),

                      // ─── Botón de reset ──────────────────────
                      if (mediaStore.status == UploadStatus.success ||
                          mediaStore.status == UploadStatus.error)
                        _buildResetButton(theme, mediaStore),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 2,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.perm_media_rounded,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            'Multimedia',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ),
      ],
    );
  }

  // ─── Secciones de la UI ──────────────────────────────────────────

  Widget _buildHeaderSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subir Contenido',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selecciona una imagen de tu galería. Se comprimirá y subirá de forma segura a la nube.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme, MediaStore store) {
    final statusLabels = {
      UploadStatus.picking: 'Seleccionando imagen…',
      UploadStatus.compressing: 'Comprimiendo…',
      UploadStatus.uploading: 'Subiendo a la nube…',
      UploadStatus.saving: 'Guardando registro…',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    statusLabels[store.status] ?? 'Procesando…',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(store.progress * 100).toInt()}%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: store.progress,
                  minHeight: 6,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorSection(ThemeData theme, MediaStore store) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.errorContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  store.errorMessage ?? 'Ocurrió un error inesperado.',
                  style: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        elevation: 0,
        color: Colors.green.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¡Imagen subida exitosamente!',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme, MediaStore store) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Imagen con caché y shimmer ──
            AspectRatio(
              aspectRatio: 16 / 10,
              child: CachedNetworkImage(
                imageUrl: store.lastUploadedUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildShimmerPlaceholder(theme),
                errorWidget: (context, url, error) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error al cargar imagen',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Metadata ──
            if (store.lastMediaItem != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.image_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        store.lastMediaItem!.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Subida ✓',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Placeholder tipo shimmer animado para la carga de imágenes.
  Widget _buildShimmerPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: _ShimmerEffect(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surfaceContainerHigh,
                  theme.colorScheme.surfaceContainerHighest,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Botones de acción ───────────────────────────────────────────

  Widget _buildUploadButton(
    BuildContext context,
    ThemeData theme,
    MediaStore store,
  ) {
    final authStore = context.read<AuthStore>();

    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: store.isWorking
            ? null
            : () {
                final userId = authStore.userId;
                if (userId != null) {
                  store.pickAndUploadImage(userId);
                }
              },
        icon: store.isWorking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.photo_library_rounded, size: 22),
        label: Text(
          store.isWorking ? 'Procesando…' : 'Seleccionar de Galería',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildResetButton(ThemeData theme, MediaStore store) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: store.reset,
        icon: const Icon(Icons.refresh_rounded, size: 20),
        label: const Text(
          'Subir otra imagen',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ─── Widget Shimmer Animado ─────────────────────────────────────────

/// Efecto shimmer animado para placeholders de carga.
///
/// Simula un brillo desplazándose horizontalmente sobre el widget hijo,
/// creando una experiencia visual pulida mientras la imagen se descarga.
class _ShimmerEffect extends StatefulWidget {
  final Widget child;

  const _ShimmerEffect({required this.child});

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0x00FFFFFF),
                Color(0x44FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

