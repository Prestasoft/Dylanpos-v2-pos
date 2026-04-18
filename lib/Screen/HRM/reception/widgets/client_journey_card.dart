import 'package:flutter/material.dart';
import '../client_tracking_model.dart';

/// Card visual que muestra el pipeline de un cliente a través de departamentos.
///
/// Indicadores de color:
///   ⚪ Gris  — No ha llegado a este departamento
///   🔴 Rojo  — Asignado o en progreso
///   🟡 Amarillo — Vencida (SLA superado)
///   🟢 Verde — Completado
class ClientJourneyCard extends StatelessWidget {
  final ClientTrackingModel client;
  final VoidCallback? onAssign; // Para asignar recepcionista desde "Sin asignar"

  const ClientJourneyCard({
    super.key,
    required this.client,
    this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: Nombre + Servicio + Fecha
            Row(
              children: [
                // Avatar con inicial
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A84B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    client.customerName.isNotEmpty ? client.customerName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFD4A84B)),
                  ),
                ),
                const SizedBox(width: 12),
                // Info del cliente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (client.serviceName.isNotEmpty)
                        Text(
                          client.serviceName,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Fecha + hora
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(client.reservationDate),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    if (client.reservationTime.isNotEmpty)
                      Text(
                        client.reservationTime,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Fila 2: Pipeline de etapas
            if (client.stages.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text('Sin departamentos asignados', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              )
            else
              isMobile ? _buildPipelineVertical() : _buildPipelineHorizontal(),

            // Fila 3: Botón de asignar (solo si está en "Sin asignar")
            if (onAssign != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAssign,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Asignar recepcionista', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD4A84B),
                    side: const BorderSide(color: Color(0xFFD4A84B)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],

            // Progreso completado
            if (client.stages.isNotEmpty && !client.isUnassigned) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: client.stages.isEmpty ? 0 : client.completedCount / client.stages.length,
                        minHeight: 4,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          client.isFullyCompleted ? Colors.green : const Color(0xFFD4A84B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${client.completedCount}/${client.stages.length}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Pipeline horizontal para desktop
  Widget _buildPipelineHorizontal() {
    return Row(
      children: [
        for (int i = 0; i < client.stages.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey.shade300),
            ),
          Expanded(child: _buildStageChip(client.stages[i])),
        ],
      ],
    );
  }

  /// Pipeline vertical para móvil
  Widget _buildPipelineVertical() {
    return Column(
      children: client.stages.map((stage) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _buildStageRow(stage),
        );
      }).toList(),
    );
  }

  Widget _buildStageChip(StageStatus stage) {
    final color = _stageColor(stage);
    final icon = _stageIcon(stage);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            _shortName(stage.designationName),
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (stage.employeeName != null && stage.employeeName!.isNotEmpty)
            Text(
              stage.employeeName!.split(' ').first,
              style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildStageRow(StageStatus stage) {
    final color = _stageColor(stage);
    final icon = _stageIcon(stage);

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            stage.designationName,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
          ),
        ),
        if (stage.employeeName != null && stage.employeeName!.isNotEmpty)
          Text(
            stage.employeeName!,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _statusLabel(stage),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }

  Color _stageColor(StageStatus stage) {
    if (stage.isCompleted) return Colors.green;
    if (stage.isOverdue) return Colors.orange;
    if (stage.isActive) return Colors.red;
    return Colors.grey; // sin task
  }

  IconData _stageIcon(StageStatus stage) {
    if (stage.isCompleted) return Icons.check_circle;
    if (stage.isOverdue) return Icons.warning_amber;
    if (stage.isActive) return Icons.circle;
    return Icons.circle_outlined;
  }

  String _statusLabel(StageStatus stage) {
    if (stage.isCompleted) return 'Listo';
    if (stage.isOverdue) return 'Vencida';
    if (stage.isActive) return 'En proceso';
    return 'Pendiente';
  }

  String _shortName(String name) {
    if (name.length <= 8) return name;
    // Abreviaciones comunes
    final lower = name.toLowerCase();
    if (lower.contains('maquill')) return 'Maquill.';
    if (lower.contains('fotograf')) return 'Foto';
    if (lower.contains('film')) return 'Film';
    if (lower.contains('edic') || lower.contains('editor')) return 'Edición';
    if (lower.contains('impres')) return 'Impres.';
    if (lower.contains('recepcion')) return 'Recep.';
    if (lower.contains('seleccion')) return 'Selec.';
    return name.substring(0, 7);
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      final months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return date;
    }
  }
}
