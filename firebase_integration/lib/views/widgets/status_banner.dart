import 'package:flutter/material.dart';

/// Tipo semántico para el banner de conectividad.
enum ConnectivityStatus { connected, disconnected }

/// Banner reutilizable que indica el estado de la conexión a internet.
///
/// * [ConnectivityStatus.connected]    → fondo verde, mensaje "Conexión restaurada".
/// * [ConnectivityStatus.disconnected] → fondo rojo,  mensaje "Sin conexión - Modo Avión".
///
/// Es un [StatelessWidget] con constructor [const] para máximo rendimiento.
class StatusBanner extends StatelessWidget {
  final ConnectivityStatus connectivityStatus;

  const StatusBanner({super.key, required this.connectivityStatus});

  @override
  Widget build(BuildContext context) {
    final isConnected = connectivityStatus == ConnectivityStatus.connected;

    final backgroundColor =
        isConnected ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    final icon = isConnected ? Icons.wifi : Icons.wifi_off;

    final message =
        isConnected ? 'Conexión restaurada' : 'Sin conexión - Modo Avión';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
