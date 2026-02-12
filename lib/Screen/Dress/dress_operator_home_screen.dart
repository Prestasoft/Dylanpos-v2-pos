// dress_operator_home_screen.dart
// Pantalla de inicio para usuarios con rol "dress_operator"
// Solo permite acceso a Estado de Vestimentas y Disponibilidad de Vestimentas

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import '../../const.dart';
import '../../Repository/login_repo.dart';
import '../../services/version_check_service.dart';
import 'package:salespro_admin/Provider/branch_provider.dart';

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
          // Selector de vista
          Container(
            padding: const EdgeInsets.all(16),
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

          // Contenido principal
          Expanded(
            child: _selectedView == 'status'
                ? _buildStatusView()
                : _buildAvailabilityView(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(String value, String label, IconData icon, Color color) {
    final isSelected = _selectedView == value;
    return InkWell(
      onTap: () => setState(() => _selectedView = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusView() {
    // Navegamos a la pantalla de Estado de Vestimentas embebida
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kMainColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.checkroom, color: kMainColor, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Estado de Vestimentas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kMainColor,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => context.go('/service-package/dresses'),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Abrir en pantalla completa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMainColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checkroom, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Gestión de Estado de Vestimentas',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cambia el estado de los vestidos (Disponible, En uso, En lavandería, etc.)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/service-package/dresses'),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Ir a Estado de Vestimentas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF15CD75).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF15CD75), size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Disponibilidad de Vestimentas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15CD75),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => context.go('/calendario-reservas'),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Abrir en pantalla completa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15CD75),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Calendario de Disponibilidad',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Consulta la disponibilidad de vestidos por fecha',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/calendario-reservas'),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Ir a Disponibilidad'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15CD75),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
