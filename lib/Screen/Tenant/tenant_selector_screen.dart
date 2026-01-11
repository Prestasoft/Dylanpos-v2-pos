import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:salespro_admin/services/tenant/tenant_manager.dart';
import 'package:salespro_admin/services/tenant/tenant_model.dart';

import '../Widgets/Constant Data/constant.dart';

/// Pantalla para seleccionar la sucursal antes de iniciar sesión
class TenantSelectorScreen extends StatefulWidget {
  const TenantSelectorScreen({super.key});

  static const String route = '/select-branch';

  @override
  State<TenantSelectorScreen> createState() => _TenantSelectorScreenState();
}

class _TenantSelectorScreenState extends State<TenantSelectorScreen> {
  final TenantManager _tenantManager = TenantManager();
  TenantModel? _selectedTenant;
  bool _isLoading = false;
  bool _rememberSelection = true;

  @override
  void initState() {
    super.initState();
    _loadSavedTenant();
  }

  Future<void> _loadSavedTenant() async {
    final saved = await _tenantManager.getSavedTenant();
    if (saved != null && mounted) {
      setState(() {
        _selectedTenant = saved;
      });
    }
  }

  Future<void> _continueWithTenant() async {
    if (_selectedTenant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione una sucursal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Guardar selección si está marcado
      if (_rememberSelection) {
        await _tenantManager.saveTenant(_selectedTenant!);
      }

      // Navegar al login
      if (mounted) {
        GoRouter.of(context).go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenants = _tenantManager.getAllTenants();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: size.width > 600 ? 500 : size.width * 0.9,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kMainColor, kMainColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.store_mall_directory,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Seleccionar Sucursal',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Elija la sucursal a la que desea acceder',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de sucursales
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ...tenants.map((tenant) => _buildTenantCard(tenant)),

                      const SizedBox(height: 20),

                      // Checkbox recordar
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberSelection,
                            activeColor: kMainColor,
                            onChanged: (v) {
                              setState(() => _rememberSelection = v ?? true);
                            },
                          ),
                          const Text(
                            'Recordar mi selección',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Botón continuar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _continueWithTenant,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kMainColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Continuar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, color: Colors.white),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTenantCard(TenantModel tenant) {
    final isSelected = _selectedTenant?.id == tenant.id;

    return GestureDetector(
      onTap: () => setState(() => _selectedTenant = tenant),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kMainColor.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kMainColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar/Icono
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? kMainColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  tenant.initials,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant.city,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? kMainColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tenant.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? kMainColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? kMainColor : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
