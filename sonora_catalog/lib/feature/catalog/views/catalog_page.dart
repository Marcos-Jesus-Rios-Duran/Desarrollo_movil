import 'package:flutter/material.dart';
import 'package:sonora_catalog/feature/catalog/controllers/catalog_controller.dart';
import 'package:sonora_catalog/feature/catalog/data/models/instrument_view_model.dart';
import 'package:sonora_catalog/feature/catalog/views/instrument_form_page.dart';

/// Pantalla principal del catálogo de instrumentos.
///
/// Observa [CatalogController] mediante [ValueListenableBuilder] para
/// reconstruir sólo las secciones afectadas por cambios de estado.
/// No contiene lógica de negocio ni de sincronización.
class CatalogPage extends StatefulWidget {
  /// Controlador inyectado (permite testear con un fake).
  final CatalogController controller;

  const CatalogPage({super.key, required this.controller});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  // ---------------------------------------------------------------------------
  // Ciclo de vida
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    widget.controller.init();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Build
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: <Widget>[
          _ConnectivityBanner(isOnline: widget.controller.isOnline),
          _ErrorBanner(errorMessage: widget.controller.errorMessage),
          Expanded(child: _CatalogBody(controller: widget.controller)),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  // ---------------------------------------------------------------------------
  // Widgets auxiliares privados
  // ---------------------------------------------------------------------------

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('🎸 Sonora Catalog'),
      actions: <Widget>[
        // Botón de sincronización manual
        ValueListenableBuilder<bool>(
          valueListenable: widget.controller.isLoading,
          builder: (_, bool loading, _) {
            return IconButton(
              icon: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              tooltip: 'Sincronizar ahora',
              onPressed: loading ? null : widget.controller.syncNow,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _openForm(context, null),
      icon: const Icon(Icons.add),
      label: const Text('Agregar'),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    InstrumentViewModel? existing,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => InstrumentFormPage(
          controller: widget.controller,
          existing: existing,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets privados del archivo
// ---------------------------------------------------------------------------

/// Banner de estado de conectividad.
class _ConnectivityBanner extends StatelessWidget {
  final ValueNotifier<bool> isOnline;
  const _ConnectivityBanner({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isOnline,
      builder: (_, bool online, _) {
        if (online) return const SizedBox.shrink();
        return Container(
          color: Colors.orange.shade700,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: const Row(
            children: <Widget>[
              Icon(Icons.wifi_off, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Sin conexión — modo offline activo',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Banner de error rojo bajo el AppBar.
class _ErrorBanner extends StatelessWidget {
  final ValueNotifier<String> errorMessage;
  const _ErrorBanner({required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: errorMessage,
      builder: (_, String msg, _) {
        if (msg.isEmpty) return const SizedBox.shrink();
        return Container(
          color: Colors.red.shade700,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
            children: <Widget>[
              const Icon(Icons.error_outline, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Cuerpo principal: lista de instrumentos con manejo de estado.
class _CatalogBody extends StatelessWidget {
  final CatalogController controller;
  const _CatalogBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isLoading,
      builder: (_, bool loading, _) {
        if (loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ValueListenableBuilder<List<InstrumentViewModel>>(
          valueListenable: controller.instruments,
          builder: (_, List<InstrumentViewModel> list, _) {
            if (list.isEmpty) {
              return const Center(
                child: Text(
                  'No hay instrumentos.\nPresiona + para agregar uno.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: controller.syncNow,
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (BuildContext ctx, int index) {
                  return _InstrumentTile(
                    vm: list[index],
                    controller: controller,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// Tarjeta de un instrumento en la lista.
class _InstrumentTile extends StatelessWidget {
  final InstrumentViewModel vm;
  final CatalogController controller;

  const _InstrumentTile({required this.vm, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.music_note),
      ),
      title: Text(vm.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${vm.brand}  •  ${vm.stockLabel}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            vm.formattedPrice,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            vm.syncStatus,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
      onTap: () => _openForm(context),
      onLongPress: () => _confirmDelete(context),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            InstrumentFormPage(controller: controller, existing: vm),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar instrumento'),
        content: Text('¿Deseas eliminar "${vm.name}"?'),
        actions: <TextButton>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await controller.deleteInstrument(vm.id);
    }
  }
}
