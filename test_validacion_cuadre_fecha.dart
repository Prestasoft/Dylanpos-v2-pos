import 'package:flutter_test/flutter_test.dart';

/// Script de validación para el filtro de ventas del día en cuadre de caja
/// 
/// Este script valida que:
/// 1. Solo se incluyan ventas del día actual
/// 2. Los métodos de pago se categoricen correctamente  
/// 3. Los cálculos sean precisos
/// 4. El filtro de fecha funcione con diferentes formatos

void main() {
  group('Validación Filtro de Ventas del Día - Cuadre de Caja', () {
    
    test('Validar lógica de filtro de fecha actual', () {
      // Simular la lógica de filtro de fecha de _getTodaysSalesTotals()
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      print('🔍 Rango de fechas para filtro:');
      print('📅 Inicio: ${todayStart.toString()}');
      print('📅 Fin: ${todayEnd.toString()}');
      
      // Test casos de fechas
      final testCases = [
        {
          'fecha': today.toString(), // Ahora mismo
          'esperado': true,
          'descripcion': 'Fecha actual (ahora)'
        },
        {
          'fecha': DateTime(today.year, today.month, today.day, 0, 0, 0).toString(), // Inicio del día
          'esperado': true,
          'descripcion': 'Inicio del día (00:00:00)'
        },
        {
          'fecha': DateTime(today.year, today.month, today.day, 23, 59, 59).toString(), // Final del día
          'esperado': true,
          'descripcion': 'Final del día (23:59:59)'
        },
        {
          'fecha': DateTime(today.year, today.month, today.day - 1).toString(), // Ayer
          'esperado': false,
          'descripcion': 'Ayer'
        },
        {
          'fecha': DateTime(today.year, today.month, today.day + 1).toString(), // Mañana
          'esperado': false,
          'descripcion': 'Mañana'
        },
      ];
      
      print('\n📊 VALIDANDO CASOS DE FECHA:');
      for (var testCase in testCases) {
        final fechaVenta = DateTime.parse(testCase['fecha'] as String);
        final isToday = fechaVenta.isAfter(todayStart.subtract(Duration(seconds: 1))) && fechaVenta.isBefore(todayEnd);
        final esperado = testCase['esperado'] as bool;
        
        print('📅 ${testCase['descripcion']}: $isToday ${isToday == esperado ? '✅' : '❌'}');
        expect(isToday, equals(esperado), reason: 'Fallo en caso: ${testCase['descripcion']}');
      }
    });
    
    test('Validar categorización de métodos de pago', () {
      print('\n💳 VALIDANDO CATEGORIZACIÓN DE MÉTODOS DE PAGO:');
      
      final metodosEfectivo = ['cash', 'Cash', 'efectivo', 'Efectivo', 'EFECTIVO'];
      final metodosTarjeta = ['card', 'Card', 'tarjeta', 'Tarjeta', 'bank', 'Bank'];
      final metodosTransferencia = ['transfer', 'Transfer', 'transferencia', 'Transferencia', 'mobile', 'Mobile Pay'];
      
      // Test efectivo
      for (var metodo in metodosEfectivo) {
        final esEfectivo = metodo.toLowerCase().contains('cash') || 
                          metodo.toLowerCase().contains('efectivo');
        print('💵 $metodo → Efectivo: $esEfectivo ${esEfectivo ? '✅' : '❌'}');
        expect(esEfectivo, isTrue, reason: 'Método $metodo debería ser categorizado como efectivo');
      }
      
      // Test tarjeta
      for (var metodo in metodosTarjeta) {
        final esTarjeta = metodo.toLowerCase().contains('card') || 
                         metodo.toLowerCase().contains('tarjeta') ||
                         metodo.toLowerCase().contains('bank');
        print('💳 $metodo → Tarjeta: $esTarjeta ${esTarjeta ? '✅' : '❌'}');
        expect(esTarjeta, isTrue, reason: 'Método $metodo debería ser categorizado como tarjeta');
      }
      
      // Test transferencia
      for (var metodo in metodosTransferencia) {
        final esTransferencia = metodo.toLowerCase().contains('transfer') || 
                               metodo.toLowerCase().contains('transferencia') ||
                               metodo.toLowerCase().contains('mobile');
        print('📱 $metodo → Transferencia: $esTransferencia ${esTransferencia ? '✅' : '❌'}');
        expect(esTransferencia, isTrue, reason: 'Método $metodo debería ser categorizado como transferencia');
      }
    });
    
    test('Validar parsing de diferentes formatos de fecha', () {
      print('\n📅 VALIDANDO PARSING DE FORMATOS DE FECHA:');
      
      final today = DateTime.now();
      final formatosFecha = [
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}', // dd/MM/yyyy
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}', // yyyy-MM-dd
        today.toString(), // DateTime.toString()
      ];
      
      for (var formato in formatosFecha) {
        try {
          DateTime fechaParseada;
          
          if (formato.contains('/')) {
            final parts = formato.split('/');
            fechaParseada = DateTime(
              int.parse(parts[2]), // año
              int.parse(parts[1]), // mes
              int.parse(parts[0]), // día
            );
          } else if (formato.contains('-')) {
            String datePart = formato.split(' ')[0];
            final parts = datePart.split('-');
            fechaParseada = DateTime(
              int.parse(parts[0]), // año
              int.parse(parts[1]), // mes
              int.parse(parts[2]), // día
            );
          } else {
            fechaParseada = DateTime.parse(formato);
          }
          
          final esHoy = fechaParseada.year == today.year && 
                       fechaParseada.month == today.month && 
                       fechaParseada.day == today.day;
          
          print('📅 $formato → Parseado correctamente: $esHoy ${esHoy ? '✅' : '❌'}');
          expect(esHoy, isTrue, reason: 'Formato $formato debería ser parseado como hoy');
          
        } catch (e) {
          print('❌ Error parseando $formato: $e');
          fail('No se pudo parsear el formato: $formato');
        }
      }
    });
    
    test('Validar cálculos del cuadre de caja', () {
      print('\n🧮 VALIDANDO CÁLCULOS DEL CUADRE:');
      
      // Datos de prueba
      final ventasEfectivo = [100.0, 250.0, 75.5];
      final ventasTarjeta = [300.0, 150.0];
      final ventasTransferencia = [200.0, 125.0];
      final gastos = [50.0, 25.0, 15.0];
      
      final totalEfectivo = ventasEfectivo.reduce((a, b) => a + b);
      final totalTarjeta = ventasTarjeta.reduce((a, b) => a + b);
      final totalTransferencia = ventasTransferencia.reduce((a, b) => a + b);
      final totalGastos = gastos.reduce((a, b) => a + b);
      
      final totalVentas = totalEfectivo + totalTarjeta + totalTransferencia;
      final balanceNeto = totalVentas - totalGastos;
      
      print('💵 Total Efectivo: RD\$${totalEfectivo.toStringAsFixed(2)}');
      print('💳 Total Tarjeta: RD\$${totalTarjeta.toStringAsFixed(2)}');
      print('📱 Total Transferencia: RD\$${totalTransferencia.toStringAsFixed(2)}');
      print('🏦 Total Ventas: RD\$${totalVentas.toStringAsFixed(2)}');
      print('💸 Total Gastos: RD\$${totalGastos.toStringAsFixed(2)}');
      print('🏆 Balance Neto: RD\$${balanceNeto.toStringAsFixed(2)}');
      
      // Validaciones
      expect(totalEfectivo, equals(425.5));
      expect(totalTarjeta, equals(450.0));
      expect(totalTransferencia, equals(325.0));
      expect(totalVentas, equals(1200.5));
      expect(totalGastos, equals(90.0));
      expect(balanceNeto, equals(1110.5));
      
      print('✅ Todos los cálculos son correctos');
    });
  });
}

/// Función auxiliar para debug en producción
void debugCuadreFilter() {
  print('🔧 HERRAMIENTAS DE DEBUG PARA CUADRE DE CAJA:');
  print('');
  print('1. 📊 Verificar logs en consola cuando se abre el modal');
  print('2. 🔍 Buscar patrones de logs que empiecen con:');
  print('   - "🔑 User ID obtenido"');
  print('   - "🔍 Buscando ventas y gastos del día"');
  print('   - "💰 Venta #X encontrada"');
  print('   - "💸 Gasto #X encontrado"');
  print('   - "📈 RESUMEN FINAL DE TOTALES"');
  print('');
  print('3. ✅ Verificar que en el modal aparezcan valores diferentes a 0.0');
  print('4. 🧮 Comprobar que los cálculos coincidan con las ventas reales');
  print('5. 📅 Confirmar que solo se incluyan transacciones de hoy');
  print('');
  print('📱 Para ejecutar validación en navegador:');
  print('   1. Abrir DevTools (F12)');
  print('   2. Ir a Console');
  print('   3. Ejecutar: validarCuadreDeCaja()');
  print('   4. Abrir modal de cuadre y verificar logs');
}
