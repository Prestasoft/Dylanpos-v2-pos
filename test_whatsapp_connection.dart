import 'package:http/http.dart' as http;

Future<void> main() async {
  print('🔍 Verificando conectividad con API de WhatsApp...\n');

  // Credenciales de Santo Domingo (las que deberían funcionar)
  const String token = '5i36w829nb1ljkj7';
  const String instance = 'instance127004';
  
  try {
    // Probar endpoint de documentos
    print('📄 Probando endpoint de documentos...');
    final documentUrl = Uri.parse('https://api.ultramsg.com/$instance/messages/document');
    final documentResponse = await http.head(documentUrl).timeout(const Duration(seconds: 10));
    print('✅ Endpoint de documentos: ${documentResponse.statusCode == 200 ? 'ACCESIBLE' : 'ERROR ' + documentResponse.statusCode.toString()}');

    // Probar endpoint de chat
    print('💬 Probando endpoint de chat...');
    final chatUrl = Uri.parse('https://api.ultramsg.com/$instance/messages/chat');
    final chatResponse = await http.head(chatUrl).timeout(const Duration(seconds: 10));
    print('✅ Endpoint de chat: ${chatResponse.statusCode == 200 ? 'ACCESIBLE' : 'ERROR ' + chatResponse.statusCode.toString()}');

    // Probar endpoint de estado de la instancia
    print('📊 Verificando estado de la instancia...');
    final statusUrl = Uri.parse('https://api.ultramsg.com/$instance/instance/status');
    final statusHeaders = {'Authorization': 'Bearer $token'};
    
    final statusResponse = await http.get(
      statusUrl,
      headers: statusHeaders,
    ).timeout(const Duration(seconds: 10));
    
    print('✅ Estado de instancia: ${statusResponse.statusCode}');
    print('📋 Respuesta: ${statusResponse.body}');

  } catch (e) {
    print('❌ Error de conectividad: $e');
  }

  print('\n📝 Resumen de configuración actual:');
  print('Token: $token');
  print('Instancia: $instance');
  print('URL Documentos: https://api.ultramsg.com/$instance/messages/document');
  print('URL Chat: https://api.ultramsg.com/$instance/messages/chat');
  
  print('\n✨ Prueba completada. Verifica los resultados arriba.');
}
