import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/equipment_model.dart';
import '../services/equipment_service.dart';
import 'widgets/equipment_card.dart';
import 'widgets/status_banner.dart';

/// Vista principal del monitor de equipos.
///
/// Responsabilidades:
/// - Consumir el [Stream] de [EquipmentService] mediante [StreamBuilder].
/// - Observar el estado de la red con [Connectivity.onConnectivityChanged].
/// - Mantener los datos en caché cuando no hay conexión.
/// - Mostrar el [StatusBanner] de forma temporal al reconectar.
class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  // ── Servicio (capa de datos) ─────────────────────────────────────────────
  final _service = EquipmentService();

  // ── Estado de conectividad ───────────────────────────────────────────────
  ConnectivityStatus _connectivityStatus = ConnectivityStatus.connected;

  /// Controla si el banner debe mostrarse en pantalla.
  bool _showBanner = false;

  /// Suscripción al stream de cambios de red.
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  /// Timer para ocultar el banner verde tras 3 segundos.
  Timer? _bannerTimer;

  // ── Caché local para mantener datos visibles sin conexión ────────────────
  List<EquipmentModel>? _cachedEquipments;

  // ── Ciclo de vida ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _subscribeToConnectivity();
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }

  // ── Lógica de conectividad ───────────────────────────────────────────────

  void _subscribeToConnectivity() {
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    // Considera "sin conexión" si todos los resultados son none.
    final isOffline = results.every((r) => r == ConnectivityResult.none);
    final newStatus = isOffline
        ? ConnectivityStatus.disconnected
        : ConnectivityStatus.connected;

    if (newStatus == _connectivityStatus) return; // sin cambio real

    setState(() {
      _connectivityStatus = newStatus;
      _showBanner = true;
    });

    // Si se reconectó, ocultamos el banner verde después de 3 segundos.
    if (newStatus == ConnectivityStatus.connected) {
      _bannerTimer?.cancel();
      _bannerTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showBanner = false);
      });
    }
    // Si se desconectó, el banner rojo permanece visible.
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor de Equipos'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Banner de conectividad (animado, solo visible cuando hay cambio)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showBanner
                ? StatusBanner(connectivityStatus: _connectivityStatus)
                : const SizedBox.shrink(),
          ),

          // Lista reactiva de equipos
          Expanded(
            child: StreamBuilder<List<EquipmentModel>>(
              stream: _service.getCatalogStream(),
              builder: (context, snapshot) {
                // ── 1. Cacheamos los datos más recientes ──────────────────
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  _cachedEquipments = snapshot.data;
                }

                // ── 2. Error con caché disponible → mostramos caché ───────
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error);
                }

                // ── 3. Loading inicial (sin caché todavía) ─────────────────
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _cachedEquipments == null) {
                  return const _LoadingIndicator();
                }

                // ── 4. Datos disponibles (en vivo o desde caché) ──────────
                final equipments = snapshot.data ?? _cachedEquipments ?? [];

                if (equipments.isEmpty) {
                  return const _EmptyState();
                }

                return ListView.builder(
                  // Padding inferior para evitar que el último item quede
                  // debajo de la barra de navegación del sistema.
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: equipments.length,
                  itemBuilder: (context, index) {
                    return EquipmentCard(
                      key: ValueKey(equipments[index].id),
                      equipment: equipments[index],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el estado de error manteniendo la caché visible si existe.
  Widget _buildErrorState(Object? error) {
    if (_cachedEquipments != null && _cachedEquipments!.isNotEmpty) {
      // Si tenemos caché, la mostramos con un banner de advertencia superior.
      return Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.orange.shade100,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mostrando datos en caché. Error: $error',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: _cachedEquipments!.length,
              itemBuilder: (context, index) => EquipmentCard(
                key: ValueKey(_cachedEquipments![index].id),
                equipment: _cachedEquipments![index],
              ),
            ),
          ),
        ],
      );
    }

    // Sin caché: estado de error puro.
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            'Ocurrió un error al cargar los equipos.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '$error',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Widgets privados auxiliares (DRY) ─────────────────────────────────────────

/// Spinner de carga inicial.
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Estado vacío cuando la colección no tiene documentos.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay equipos registrados.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
