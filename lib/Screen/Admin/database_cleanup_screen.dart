import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../const.dart';

class DatabaseCleanupScreen extends StatefulWidget {
  const DatabaseCleanupScreen({super.key});

  @override
  State<DatabaseCleanupScreen> createState() => _DatabaseCleanupScreenState();
}

class _DatabaseCleanupScreenState extends State<DatabaseCleanupScreen> {
  bool _isLoading = false;
  List<String> _logs = [];

  // Nodos a eliminar
  final List<String> _nodosAEliminar = [
    'Sales List',
    'Customers',
    'Due List',
    'Reservations',
    'Daily Transaction',
    'Sale Confirmations',
  ];

  // Nodos a preservar
  final List<String> _nodosAPreservar = [
    'Products',
    'Packages',
    'Services',
    'Vestimentas',
    'Dresses',
    'Warehouse',
    'General Settings',
    'Personal Information',
    'Subscription',
  ];

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
  }

  Future<void> _cleanDatabase() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    _addLog('=== INICIANDO LIMPIEZA DE BASE DE DATOS ===\n');

    try {
      final database = FirebaseDatabase.instance;
      final rootRef = database.ref();
      final rootSnapshot = await rootRef.get();

      if (!rootSnapshot.exists) {
        _addLog('❌ No hay datos en la base de datos');
        setState(() => _isLoading = false);
        return;
      }

      final data = rootSnapshot.value as Map<dynamic, dynamic>;
      _addLog('✓ Conexión exitosa a Firebase\n');

      for (var userId in data.keys) {
        _addLog('📁 Procesando usuario: ${userId.toString().substring(0, 10)}...\n');

        final userData = data[userId];
        if (userData is! Map) continue;

        // Eliminar nodos
        for (var nodo in _nodosAEliminar) {
          if (userData.containsKey(nodo)) {
            try {
              await database.ref().child(userId.toString()).child(nodo).remove();
              _addLog('  ✓ Eliminado: $nodo');
            } catch (e) {
              _addLog('  ❌ Error eliminando $nodo: $e');
            }
          } else {
            _addLog('  ⚪ No existe: $nodo');
          }
        }

        _addLog('\n  📦 Nodos preservados:');
        for (var nodo in _nodosAPreservar) {
          if (userData.containsKey(nodo)) {
            _addLog('  ✓ $nodo');
          }
        }
      }

      _addLog('\n=== ✅ LIMPIEZA COMPLETADA ===');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Base de datos limpiada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('\n❌ ERROR: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Limpieza de Base de Datos'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade800, size: 30),
                      const SizedBox(width: 10),
                      Text(
                        '⚠️ ADVERTENCIA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Esta acción eliminará permanentemente los siguientes datos:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  ..._nodosAEliminar.map((nodo) => Padding(
                    padding: const EdgeInsets.only(left: 20, top: 2),
                    child: Text('• $nodo', style: const TextStyle(color: Colors.red)),
                  )),
                  const SizedBox(height: 15),
                  const Text(
                    'Se preservarán:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _nodosAPreservar.map((nodo) => Chip(
                      label: Text(nodo, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.green.shade100,
                    )).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Cleanup Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _showConfirmDialog(),
                icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever),
                label: Text(_isLoading ? 'Limpiando...' : 'LIMPIAR BASE DE DATOS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Logs
            if (_logs.isNotEmpty) ...[
              const Text(
                'Registro de operaciones:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _logs.join('\n'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('Confirmar Limpieza'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar todas las ventas, clientes y transacciones?\n\n'
          'Esta acción NO se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cleanDatabase();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SÍ, ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
