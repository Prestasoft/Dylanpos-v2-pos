// Test para visualizar el formato de comas de millar en el cuadre de caja
// Este script muestra ejemplos de cómo se verán los montos con el nuevo formato

import 'lib/commas.dart';

void main() {
  print('🧪 PRUEBA DEL FORMATO DE COMAS DE MILLAR EN CUADRE DE CAJA');
  print('========================================================');
  print('');
  
  // Simular datos de prueba
  final testAmounts = [
    125.50,
    1500.75,
    12500.00,
    125000.99,
    1250000.50,
    12500000.00,
  ];
  
  print('📊 COMPARACIÓN DE FORMATOS:');
  print('---------------------------');
  print('| Monto Original | Sin Comas | Con Comas |');
  print('|----------------|-----------|-----------|');
  
  for (var amount in testAmounts) {
    final sinComas = 'RD\$${amount.toStringAsFixed(2)}';
    final conComas = 'RD\$${myFormat.format(amount)}';
    
    print('| ${amount.toString().padRight(14)} | ${sinComas.padRight(9)} | ${conComas.padRight(9)} |');
  }
  
  print('');
  print('🎯 EJEMPLO EN EL MODAL DE CUADRE:');
  print('---------------------------------');
  
  // Datos de ejemplo realistas para un día de trabajo
  final efectivo = 15750.50;
  final tarjeta = 28300.75;
  final transferencia = 12450.25;
  final gastos = 3200.00;
  
  final totalVentas = efectivo + tarjeta + transferencia;
  final balanceNeto = totalVentas - gastos;
  
  print('💵 Pagos en Efectivo: RD\$${myFormat.format(efectivo)}');
  print('💳 Pagos con Tarjeta: RD\$${myFormat.format(tarjeta)}');
  print('📱 Pagos por Transferencia: RD\$${myFormat.format(transferencia)}');
  print('');
  print('🏦 Total Ventas del Día: RD\$${myFormat.format(totalVentas)}');
  print('💸 Total Gastos del Día: RD\$${myFormat.format(gastos)}');
  print('🏆 Balance Neto del Día: RD\$${myFormat.format(balanceNeto)}');
  
  print('');
  print('📱 EJEMPLO EN LOGS DE DEBUG:');
  print('----------------------------');
  print('🔍 Buscando ventas y gastos del día: 2025-07-04...');
  print('💰 Venta #1 encontrada:');
  print('   📄 Factura: 1001');
  print('   💵 Monto: ${myFormat.format(1250.75)}');
  print('   ✅ Categorizado como EFECTIVO. Total efectivo: ${myFormat.format(efectivo)}');
  print('');
  print('📈 RESUMEN FINAL DE TOTALES:');
  print('🏪 VENTAS DEL DÍA:');
  print('   💵 Efectivo: RD\$${myFormat.format(efectivo)}');
  print('   💳 Tarjeta: RD\$${myFormat.format(tarjeta)}');
  print('   📱 Transferencia: RD\$${myFormat.format(transferencia)}');
  print('   🏦 Total Ventas: RD\$${myFormat.format(totalVentas)}');
  print('');
  print('💸 GASTOS DEL DÍA:');
  print('   💰 Total Gastos: RD\$${myFormat.format(gastos)}');
  print('');
  print('🏆 BALANCE FINAL:');
  print('   💎 Balance Neto: RD\$${myFormat.format(balanceNeto)} ✅');
  
  print('');
  print('✅ FORMATO APLICADO EN:');
  print('======================');
  print('• 📱 Interfaz del modal (todos los montos)');
  print('• 🖥️ Logs de debug en consola');
  print('• 📊 SnackBar del botón "Cuadrar"');
  print('• 🧮 Cálculo de diferencias en efectivo');
  print('• 📈 Resumen final de totales');
  
  print('');
  print('🎉 BENEFICIOS DEL FORMATO CON COMAS:');
  print('====================================');
  print('• ✅ Mayor legibilidad de montos grandes');
  print('• ✅ Formato estándar internacional');
  print('• ✅ Reducción de errores de lectura');
  print('• ✅ Consistencia con otros sistemas contables');
  print('• ✅ Experiencia de usuario mejorada');
}
