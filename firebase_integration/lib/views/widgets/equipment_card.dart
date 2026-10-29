import 'package:flutter/material.dart';
import '../../models/equipment_model.dart';

/// Widget puro y reutilizable que representa un equipo en la lista.
///
/// Es un [StatelessWidget] porque toda su información viene del [EquipmentModel].
/// Usa constructor [const] para que Flutter pueda optimizar el árbol de widgets
/// y evitar rebuilds innecesarios cuando el modelo no cambia (gracias a ==).
class EquipmentCard extends StatelessWidget {
  final EquipmentModel equipment;

  const EquipmentCard({super.key, required this.equipment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = equipment.status;

    // Color semántico: verde = activo, rojo/gris = inactivo
    final statusColor = isOnline
        ? const Color(0xFF22C55E) // green-500
        : const Color(0xFF9CA3AF); // gray-400

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ── Indicador de estado circular ──────────────────────────────
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // ── Nombre y categoría ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    equipment.category,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Precio ────────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${equipment.price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                // Etiqueta textual del status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOnline ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
