// dress_operator_home_screen.dart
// Pantalla de inicio para usuarios con rol "dress_operator"
// Solo permite acceso a Estado de Vestimentas y Disponibilidad de Vestimentas
// Las pantallas se muestran EMBEBIDAS, sin sidebar ni navegación externa

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import '../../const.dart';
import '../../Repository/login_repo.dart';
import '../../services/version_check_service.dart';
import 'package:salespro_admin/Provider/branch_provider.dart';
// Importar las pantallas que vamos a embeber
import 'package:salespro_admin/Screen/Dress/DressScreen.dart';
import 'package:salespro_admin/Screen/Calendar/CalendarDressScreen.dart';

class DressOperatorHomeScreen extends ConsumerStatefulWidget {
  const DressOperatorHomeScreen({super.key});

  @override
  ConsumerState<DressOperatorHomeScreen> createState() => _DressOperatorHomeScreenState();
}

class _DressOperatorHomeScreenState extends ConsumerState<DressOperatorHomeScreen> {
  final VersionCheckService _versionCheckService = VersionCheckService();
  String _selectedView = 'status'; // 'status' o 'availability'

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    await _versionCheckService.checkForUpdates();
  }

  Future<void> _logout() async {
    await LogInRepo().signOut(context);
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(branchIdProvider);
    final branchName = getBranchName(branchId);

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            // Logo
            Image.asset(
              'images/mobipos.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.checkroom, size: 40, color: kMainColor);
              },
            ),
            const SizedBox(width: 12),
            // Título
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Operador de Vestimentas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTitleColor,
                  ),
                ),
                Text(
                  branchName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Nombre del usuario
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                constSubUserTitle.isNotEmpty ? constSubUserTitle : 'Usuario',
                style: const TextStyle(
                  fontSize: 14,
                  color: kTitleColor,
                ),
              ),
            ),
          ),
          // Botón de cerrar sesión
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Cerrar sesión',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Selector de vista (tabs)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildViewButton(
                  'status',
                  'Estado de Vestimentas',
                  Icons.checkroom,
                  kMainColor,
                ),
                const SizedBox(width: 16),
                _buildViewButton(
                  'availability',
                  'Disponibilidad de Vestimentas',
                  Icons.calendar_today,
                  const Color(0xFF15CD75),
                ),
              ],
            ),
          ),

          // Contenido principal - EMBEBER las pantallas directamente
          Expanded(
            child: _selectedView == 'status'
                ? const DressScreen() // Pantalla de Estado de Vestimentas embebida
                : const CalendarDressScreen(), // Calendario embebido
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(String value, String label, IconData icon, Color color) {
    final isSelected = _selectedView == value;
    return InkWell(
      onTap: () => setState(() => _selectedView = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
