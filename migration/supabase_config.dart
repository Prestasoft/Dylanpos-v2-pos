// Configuración de Supabase para Victor Guzman Fotografía
// Este archivo contiene las credenciales para conectar Flutter con Supabase

class SupabaseConfig {
  /// URL del proyecto Supabase
  static const String supabaseUrl = 'https://mfduhbrwfjmkfgsqeygq.supabase.co';

  /// Anon Key (segura para usar en el cliente con RLS habilitado)
  static const String supabaseAnonKey = 'sb_publishable_Q0q1NFHO_68T4_x1l1fbAA_cubF320f';

  /// Nota: La Service Role Key (secreta) debe guardarse en variables de entorno
  /// NUNCA incluir la Service Role Key en el código del cliente
}
