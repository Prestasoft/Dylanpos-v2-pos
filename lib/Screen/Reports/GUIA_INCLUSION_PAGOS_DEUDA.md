// Guía para incluir pagos de Cuentas por Cobrar en el Informe de Ventas

/*
Para resolver el problema de que no aparecen los pagos de cuentas por cobrar en el informe
de ventas, se deben seguir estos pasos:

1. Modificar el archivo report_screen.dart para incluir también los datos de Due Transaction
2. Utilizar ambos providers: transitionProvider y dueTransactionProvider
3. Modificar la función getDailyTransactions para que busque en ambas fuentes
4. Actualizar la tabla para mostrar los dos tipos de transacciones

A continuación se presentan los cambios específicos necesarios:
*/

// PASO 1: Asegurarse de importar los providers y modelos necesarios
/*
import '../../Provider/due_transaction_provider.dart';
import '../../model/due_transaction_model.dart';
*/

// PASO 2: Crear una función para combinar las transacciones
/*
// Método para combinar transacciones de ventas y pagos de cuentas por cobrar
List<dynamic> combinarTransacciones(List<SaleTransactionModel> transaccionesVenta, List<DueTransactionModel> transaccionesDue) {
  List<dynamic> transaccionesCombinadas = [];
  
  // Añadir transacciones de venta
  for (var venta in transaccionesVenta) {
    transaccionesCombinadas.add({
      'tipo': 'venta',
      'fecha': venta.purchaseDate,
      'cliente': venta.customerName,
      'monto': venta.totalAmount,
      'factura': venta.invoiceNumber,
      'metodoPago': venta.paymentType,
      'original': venta
    });
  }
  
  // Añadir transacciones de cuentas por cobrar
  for (var pago in transaccionesDue) {
    transaccionesCombinadas.add({
      'tipo': 'pago_deuda',
      'fecha': pago.purchaseDate,
      'cliente': pago.customerName,
      'monto': pago.payDueAmount,
      'factura': pago.invoiceNumber,
      'metodoPago': pago.paymentType,
      'original': pago
    });
  }
  
  // Ordenar por fecha, más reciente primero
  transaccionesCombinadas.sort((a, b) {
    DateTime fechaA = DateTime.tryParse(a['fecha'] ?? '') ?? DateTime(1900);
    DateTime fechaB = DateTime.tryParse(b['fecha'] ?? '') ?? DateTime(1900);
    return fechaB.compareTo(fechaA); // Orden descendente
  });
  
  return transaccionesCombinadas;
}
*/

// PASO 3: Modificar la sección donde se obtienen las transacciones
/*
child: Consumer(builder: (_, ref, watch) {
  AsyncValue<List<SaleTransactionModel>> transactionReport =
      ref.watch(transitionProvider);
  AsyncValue<List<DueTransactionModel>> dueTransactionReport =
      ref.watch(dueTransactionProvider);
      
  return transactionReport.when(data: (transaction) {
    return dueTransactionReport.when(data: (dueTransactions) {
      List<SaleTransactionModel> reTransaction = [];
      
      // Filtrar transacciones de venta según criterios de búsqueda y fecha
      for (var element in transaction.reversed.toList()) {
        if ((element.invoiceNumber
                    .toLowerCase()
                    .contains(searchItem.toLowerCase()) ||
                element.customerName
                    .toLowerCase()
                    .contains(searchItem.toLowerCase())) &&
            (DateTime.parse(element.purchaseDate.toString()).isAfter(selectedDate.start) &&
                DateTime.parse(element.purchaseDate.toString()).isBefore(selectedDate.end))) {
          reTransaction.add(element);
        }
      }
      
      // Filtrar transacciones de pago de deudas según criterios de búsqueda y fecha
      List<DueTransactionModel> reDueTransaction = [];
      for (var element in dueTransactions.reversed.toList()) {
        if ((element.invoiceNumber
                    .toLowerCase()
                    .contains(searchItem.toLowerCase()) ||
                element.customerName
                    .toLowerCase()
                    .contains(searchItem.toLowerCase())) &&
            (DateTime.parse(element.purchaseDate.toString()).isAfter(selectedDate.start) &&
                DateTime.parse(element.purchaseDate.toString()).isBefore(selectedDate.end))) {
          reDueTransaction.add(element);
        }
      }
      
      // Combinar ambas listas de transacciones
      List<dynamic> transaccionesCombinadas = combinarTransacciones(reTransaction, reDueTransaction);

      // Usar transaccionesCombinadas en lugar de solo reTransaction para la tabla
      return Column(
        children: [
          // ... resto del código ...
          
          // PASO 4: Modificar el DataTable para incluir ambos tipos de transacciones
          DataTable(
            // ... configuración de la tabla ...
            columns: [
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Factura')),
              DataColumn(label: Text('Cliente')),
              DataColumn(label: Text('Tipo')),  // Nueva columna para indicar el tipo
              DataColumn(label: Text('Monto')),
              DataColumn(label: Text('Método de Pago')),
              // ... otras columnas ...
            ],
            rows: transaccionesCombinadas.map((transaccion) {
              return DataRow(
                cells: [
                  DataCell(Text(formatDate(transaccion['fecha']))),
                  DataCell(Text(transaccion['factura'])),
                  DataCell(Text(transaccion['cliente'])),
                  DataCell(Text(transaccion['tipo'] == 'venta' ? 'Venta' : 'Pago Deuda')),
                  DataCell(Text('RD\$ ${formatNumber(transaccion['monto'])}')),
                  DataCell(Text(transaccion['metodoPago'] ?? 'N/A')),
                  // ... otras celdas ...
                ],
              );
            }).toList(),
          ),
          
          // ... resto del código ...
        ],
      );
    }, error: (error, stackTrace) {
      return Text('Error: $error');
    }, loading: () {
      return const Center(child: CircularProgressIndicator());
    });
  }, error: (error, stackTrace) {
    return Text('Error: $error');
  }, loading: () {
    return const Center(child: CircularProgressIndicator());
  });
}),
*/

// PASO 5: Modificar los cálculos de totales para incluir ambos tipos de transacciones
/*
double calculateTotalSale(List<SaleTransactionModel> transitionModel, List<DueTransactionModel> dueTransactionModel) {
  double total = 0.0;
  
  // Sumar transacciones de venta
  for (var element in transitionModel) {
    total += element.totalAmount!;
  }
  
  // Sumar pagos de deuda (pagos a cuentas por cobrar)
  for (var element in dueTransactionModel) {
    // Solo sumamos los pagos, no el monto original de la deuda
    total += element.payDueAmount!;
  }
  
  return total;
}
*/

// NOTAS ADICIONALES:
/*
1. Es posible que se necesiten ajustes adicionales para evitar el doble conteo, ya que los pagos
   de cuentas por cobrar también pueden estar registrados en Daily Transaction.

2. Se recomienda agregar una columna "Tipo" en la tabla para distinguir entre ventas normales
   y pagos de cuentas por cobrar.

3. Considerar mostrar los totales separados: "Total Ventas" y "Total Pagos de Deuda" para
   tener una mejor visibilidad financiera.
*/
