import 'package:flutter/material.dart';
import 'package:salespro_admin/services/supabase/supabase.dart';

/// Pantalla de prueba para verificar conexión con Supabase
class TestSupabaseLogin extends StatefulWidget {
  const TestSupabaseLogin({super.key});

  @override
  State<TestSupabaseLogin> createState() => _TestSupabaseLoginState();
}

class _TestSupabaseLoginState extends State<TestSupabaseLogin> {
  final _emailController = TextEditingController(text: 'vladycomputer@hotmail.com');
  final _passwordController = TextEditingController();

  String _status = 'No conectado';
  String _userInfo = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    if (supabaseAuth.isAuthenticated) {
      setState(() {
        _status = '✅ Ya autenticado';
        _userInfo = '''
Usuario: ${supabaseAuth.currentUserEmail}
ID: ${supabaseAuth.currentUserId}
Branch: ${supabaseAuth.currentBranchId ?? 'No asignado'}
Rol: ${supabaseAuth.currentUserRole ?? 'No definido'}
        ''';
      });
    }
  }

  Future<void> _login() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _status = '⚠️ Ingresa la contraseña');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '🔄 Conectando...';
    });

    try {
      final response = await supabaseAuth.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.user != null) {
        // Recargar perfil para obtener branch_id
        await supabaseAuth.refreshProfile();

        setState(() {
          _status = '✅ Login exitoso!';
          _userInfo = '''
Usuario: ${response.user!.email}
ID: ${response.user!.id}
Branch: ${supabaseAuth.currentBranchId ?? 'Cargando...'}
Rol: ${supabaseAuth.currentUserRole ?? 'Cargando...'}
          ''';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _userInfo = '';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await supabaseAuth.signOut();
    setState(() {
      _status = '🚪 Sesión cerrada';
      _userInfo = '';
    });
  }

  Future<void> _testDatabase() async {
    setState(() {
      _isLoading = true;
      _status = '🔄 Probando base de datos...';
    });

    try {
      // Probar lectura de branches
      final branches = await supabaseService.getBranches();

      // Probar lectura de customers (filtrado por RLS)
      final customers = await customerRepository.getAll();

      setState(() {
        _status = '✅ Conexión a DB exitosa!';
        _userInfo = '''
Sucursales encontradas: ${branches.length}
${branches.map((b) => '  - ${b['city']} (${b['id']})').join('\n')}

Clientes en tu sucursal: ${customers.length}
        ''';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error DB: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Supabase'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _status.contains('✅')
                  ? Colors.green.shade50
                  : _status.contains('❌')
                      ? Colors.red.shade50
                      : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_userInfo.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _userInfo,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Login Form
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _login,
                    icon: const Icon(Icons.login),
                    label: const Text('Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testDatabase,
              icon: const Icon(Icons.storage),
              label: const Text('Probar Base de Datos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
