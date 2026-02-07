import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';

import 'models/commission_config_model.dart';
import 'providers/rentability_provider.dart';
import 'repo/rentability_repo.dart';

/// Pantalla de Configuración de Comisiones
class CommissionSettingsScreen extends ConsumerStatefulWidget {
  const CommissionSettingsScreen({super.key});

  @override
  ConsumerState<CommissionSettingsScreen> createState() => _CommissionSettingsScreenState();
}

class _CommissionSettingsScreenState extends ConsumerState<CommissionSettingsScreen> {
  late CommissionConfig _config;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      final config = await ref.read(commissionConfigProvider.future);
      setState(() {
        _config = config;
      });
    } catch (e) {
      // Si hay error, usar configuración por defecto
      setState(() {
        _config = CommissionConfig.defaultConfig('current_branch_id');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppSurfaceBg,
      appBar: AppBar(
        backgroundColor: kMainColor,
        foregroundColor: Colors.white,
        title: const Text('Configuración de Comisiones'),
        elevation: 0,
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _saveConfiguration,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Guardar Cambios', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Niveles de Comisión
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(51),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, color: kMainColor),
                      const SizedBox(width: 12),
                      const Text(
                        'NIVELES DE COMISIÓN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kMainColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTierEditor(
                    '🥇 Nivel Oro (Top 20%)',
                    _config.goldTier,
                    Color(_config.goldTier.color),
                    (tier) => setState(() {
                      _config = CommissionConfig(
                        id: _config.id,
                        branchId: _config.branchId,
                        goldTier: tier,
                        silverTier: _config.silverTier,
                        bronzeTier: _config.bronzeTier,
                      );
                      _hasChanges = true;
                    }),
                  ),
                  const SizedBox(height: 20),
                  _buildTierEditor(
                    '🥈 Nivel Plata (Top 50%)',
                    _config.silverTier,
                    Color(_config.silverTier.color),
                    (tier) => setState(() {
                      _config = CommissionConfig(
                        id: _config.id,
                        branchId: _config.branchId,
                        goldTier: _config.goldTier,
                        silverTier: tier,
                        bronzeTier: _config.bronzeTier,
                      );
                      _hasChanges = true;
                    }),
                  ),
                  const SizedBox(height: 20),
                  _buildTierEditor(
                    '🥉 Nivel Bronce (Resto)',
                    _config.bronzeTier,
                    Color(_config.bronzeTier.color),
                    (tier) => setState(() {
                      _config = CommissionConfig(
                        id: _config.id,
                        branchId: _config.branchId,
                        goldTier: _config.goldTier,
                        silverTier: _config.silverTier,
                        bronzeTier: tier,
                      );
                      _hasChanges = true;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Reglas de Facturación
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(51),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.rule, color: kMainColor),
                      const SizedBox(width: 12),
                      const Text(
                        'REGLAS DE FACTURACIÓN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kMainColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildRuleCheckbox(
                    'Solo contar reservas 100% pagadas',
                    _config.onlyPaidInvoices,
                    (value) => setState(() {
                      _config = CommissionConfig(
                        id: _config.id,
                        branchId: _config.branchId,
                        goldTier: _config.goldTier,
                        silverTier: _config.silverTier,
                        bronzeTier: _config.bronzeTier,
                        onlyPaidInvoices: value,
                        excludeCancellations: _config.excludeCancellations,
                        gracePeriodDays: _config.gracePeriodDays,
                      );
                      _hasChanges = true;
                    }),
                  ),
                  const SizedBox(height: 12),
                  _buildRuleCheckbox(
                    'Excluir cancelaciones',
                    _config.excludeCancellations,
                    (value) => setState(() {
                      _config = CommissionConfig(
                        id: _config.id,
                        branchId: _config.branchId,
                        goldTier: _config.goldTier,
                        silverTier: _config.silverTier,
                        bronzeTier: _config.bronzeTier,
                        onlyPaidInvoices: _config.onlyPaidInvoices,
                        excludeCancellations: value,
                        gracePeriodDays: _config.gracePeriodDays,
                      );
                      _hasChanges = true;
                    }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        'Aplicar comisión solo después de:',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: TextEditingController(text: _config.gracePeriodDays.toString()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            suffix: Text('días'),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onChanged: (value) {
                            final days = int.tryParse(value) ?? 7;
                            setState(() {
                              _config = CommissionConfig(
                                id: _config.id,
                                branchId: _config.branchId,
                                goldTier: _config.goldTier,
                                silverTier: _config.silverTier,
                                bronzeTier: _config.bronzeTier,
                                onlyPaidInvoices: _config.onlyPaidInvoices,
                                excludeCancellations: _config.excludeCancellations,
                                gracePeriodDays: days,
                              );
                              _hasChanges = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('sin devolución', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierEditor(
    String title,
    CommissionTier tier,
    Color color,
    Function(CommissionTier) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Comisión %:', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: tier.percentage.toString()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        suffix: Text('%'),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      onChanged: (value) {
                        final percentage = double.tryParse(value) ?? tier.percentage;
                        onChanged(CommissionTier(
                          name: tier.name,
                          percentage: percentage,
                          minMonthlyRevenue: tier.minMonthlyRevenue,
                          minMonthlyReservations: tier.minMonthlyReservations,
                          color: tier.color,
                        ));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mín. facturado/mes:', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: tier.minMonthlyRevenue.toStringAsFixed(0)),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        prefix: Text('\$'),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      onChanged: (value) {
                        final revenue = double.tryParse(value) ?? tier.minMonthlyRevenue;
                        onChanged(CommissionTier(
                          name: tier.name,
                          percentage: tier.percentage,
                          minMonthlyRevenue: revenue,
                          minMonthlyReservations: tier.minMonthlyReservations,
                          color: tier.color,
                        ));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mín. reservas/mes:', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: tier.minMonthlyReservations.toString()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      onChanged: (value) {
                        final reservations = int.tryParse(value) ?? tier.minMonthlyReservations;
                        onChanged(CommissionTier(
                          name: tier.name,
                          percentage: tier.percentage,
                          minMonthlyRevenue: tier.minMonthlyRevenue,
                          minMonthlyReservations: reservations,
                          color: tier.color,
                        ));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCheckbox(String label, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: (newValue) => onChanged(newValue ?? false),
      activeColor: kMainColor,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _saveConfiguration() async {
    final repo = ref.read(rentabilityRepositoryProvider);
    final success = await repo.saveCommissionConfig(_config);

    if (success) {
      // Invalidar el provider para refrescar datos
      ref.invalidate(commissionConfigProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _hasChanges = false;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error guardando configuración'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
