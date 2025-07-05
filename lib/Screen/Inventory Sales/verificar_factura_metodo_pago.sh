#!/bin/bash

# Script para verificar el método de pago de una factura específica
# Creado el: 5 de julio de 2025

echo "==================================="
echo "VERIFICADOR DE MÉTODO DE PAGO POR FACTURA"
echo "==================================="
echo ""

# Verificar si se proporcionó un número de factura
if [ -z "$1" ]; then
  echo "Uso: $0 <número_de_factura>"
  echo ""
  echo "Ejemplo: $0 12345"
  exit 1
fi

# Establecer el número de factura
FACTURA="$1"
echo "Buscando factura número: $FACTURA"
echo ""

# Directorio actual del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
cd ../..

# Crear un script Dart temporal para la consulta
TMP_SCRIPT="/tmp/verificar_factura_${FACTURA}.dart"

cat > "$TMP_SCRIPT" << 'EOL'
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'lib/const.dart';
import 'lib/model/sale_transaction_model.dart';

void main() async {
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  // Obtener el número de factura del argumento
  final args = Platform.environment['FACTURA_NUM'];
  if (args == null || args.isEmpty) {
    print('ERROR: No se proporcionó número de factura');
    exit(1);
  }
  
  final facturaNum = args;
  print('Buscando factura número: $facturaNum');
  
  try {
    // Obtener el ID de usuario
    final userId = await getUserID();
    
    // Consultar la base de datos
    final ref = FirebaseDatabase.instance.ref("$userId/Sales Transition");
    final snapshot = await ref.get();
    
    if (!snapshot.exists) {
      print('No se encontraron transacciones de venta');
      exit(1);
    }
    
    // Buscar la factura
    bool encontrada = false;
    Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    
    data.forEach((key, value) {
      try {
        final venta = SaleTransactionModel.fromJson(value);
        
        if (venta.invoiceNumber == facturaNum) {
          encontrada = true;
          final fechaVenta = DateTime.parse(venta.purchaseDate);
          final formatoFecha = DateFormat('dd/MM/yyyy HH:mm:ss');
          final formatoMonto = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');
          
          print('=================================');
          print('INFORMACIÓN DE LA FACTURA #$facturaNum');
          print('=================================');
          print('ID: $key');
          print('Cliente: ${venta.customerName}');
          print('Teléfono: ${venta.customerPhone}');
          print('Fecha: ${formatoFecha.format(fechaVenta)}');
          print('Monto total: ${formatoMonto.format(venta.totalAmount ?? 0)}');
          print('Método de pago: ${venta.paymentType ?? "NO DEFINIDO"}');
          print('Estado de pago: ${venta.isPaid == true ? "PAGADO" : "PENDIENTE"}');
          if (venta.dueAmount != null && venta.dueAmount! > 0) {
            print('Monto pendiente: ${formatoMonto.format(venta.dueAmount)}');
          }
          print('=================================');
          
          // Evaluar si hay problemas con el método de pago
          if (venta.paymentType == null || venta.paymentType == 'Unknown' || venta.paymentType!.isEmpty) {
            print('⚠️ ADVERTENCIA: Esta factura no tiene un método de pago definido correctamente');
          } else {
            print('✅ Método de pago correctamente registrado');
          }
        }
      } catch (e) {
        print('Error al procesar venta $key: $e');
      }
    });
    
    if (!encontrada) {
      print('⚠️ No se encontró ninguna factura con el número $facturaNum');
    }
    
  } catch (e) {
    print('Error: $e');
  }
  
  exit(0);
}
EOL

# Ejecutar el script Dart
echo "Consultando Firebase..."
FACTURA_NUM="$FACTURA" flutter run -d macos "$TMP_SCRIPT"

# Limpiar
rm "$TMP_SCRIPT"
