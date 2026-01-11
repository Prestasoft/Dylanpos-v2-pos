import 'daily_transaction_model.dart';

class DailySummaryModel {
  final double totalFacturado;
  final double totalPagado;
  final double totalPendiente;
  final double pagoEfectivo;
  final double pagoTransferencia;
  final double pagoTarjetas;
  final double ingresoEfectivo;
  final double gastoEfectivo;
  final double ingresoTransferencia;
  final double gastoTransferencia;
  final double ingresoTarjeta;
  final double gastoTarjeta;

  DailySummaryModel({
    this.totalFacturado = 0.0,
    this.totalPagado = 0.0,
    this.totalPendiente = 0.0,
    this.pagoEfectivo = 0.0,
    this.pagoTransferencia = 0.0,
    this.pagoTarjetas = 0.0,
    this.ingresoEfectivo = 0.0,
    this.gastoEfectivo = 0.0,
    this.ingresoTransferencia = 0.0,
    this.gastoTransferencia = 0.0,
    this.ingresoTarjeta = 0.0,
    this.gastoTarjeta = 0.0,
  });

  factory DailySummaryModel.fromDailyTransactions(List<DailyTransactionModel> transactions) {
    double totalFacturado = 0.0;
    double totalPagado = 0.0;
    double totalPendiente = 0.0;
    double pagoEfectivo = 0.0;
    double pagoTransferencia = 0.0;
    double pagoTarjetas = 0.0;
    double ingresoEfectivo = 0.0;
    double gastoEfectivo = 0.0;
    double ingresoTransferencia = 0.0;
    double gastoTransferencia = 0.0;
    double ingresoTarjeta = 0.0;
    double gastoTarjeta = 0.0;

    for (final transaction in transactions) {
      // Total Facturado - para todas las ventas (Sale, Adicionales, Producto)
      if (transaction.type == "Sale" || transaction.type == "Adicionales" || transaction.type == "Impresiones") {
        totalFacturado += transaction.total;
        totalPendiente += (transaction.total - transaction.paymentIn);
      }

      // Obtener el tipo de pago y monto según el tipo de transacción
      String? paymentType;
      double paymentAmount = 0.0;

      if (transaction.saleTransactionModel != null) {
        paymentType = transaction.saleTransactionModel!.paymentType;
        paymentAmount = transaction.paymentIn;
        totalPagado += transaction.paymentIn; // Sumar al total pagado
      } else if (transaction.purchaseTransactionModel != null) {
        paymentType = transaction.purchaseTransactionModel!.paymentType;
        paymentAmount = transaction.paymentOut;
        totalPagado += transaction.paymentOut; // Sumar al total pagado
      } else if (transaction.dueTransactionModel != null) {
        paymentType = transaction.dueTransactionModel!.paymentType;
        paymentAmount = transaction.paymentIn;
        totalPagado += transaction.paymentIn; // Sumar al total pagado
      } else if (transaction.incomeModel != null) {
        paymentType = transaction.incomeModel!.paymentType;
        paymentAmount = transaction.paymentIn;
        totalPagado += transaction.paymentIn; // Sumar al total pagado
      } else if (transaction.expenseModel != null) {
        paymentType = transaction.expenseModel!.paymentType;
        paymentAmount = transaction.paymentOut;
        totalPagado += transaction.paymentOut; // Sumar al total pagado
      } else if (transaction.paySalary != null) {
        paymentType = transaction.paySalary!.paymentType;
        paymentAmount = transaction.paymentOut;
        totalPagado += transaction.paymentOut; // Sumar al total pagado
      } else {
        // Fallback: usar campos directos de la transacción cuando los modelos anidados no están disponibles
        paymentType = transaction.paymentType;
        if (transaction.type == "Expense" || transaction.type == "Purchase" ||
            transaction.type == "Purchase Return" || transaction.type == "Salary Payment") {
          paymentAmount = transaction.paymentOut;
          totalPagado += transaction.paymentOut;
        } else {
          paymentAmount = transaction.paymentIn;
          totalPagado += transaction.paymentIn;
        }
      }

      // Categorizar por método de pago (considerando español e inglés)
      if (paymentType != null && paymentAmount > 0) {
        final paymentTypeLower = paymentType.toLowerCase().trim();
        
        // Determinar si es ingreso o gasto
        bool isExpense = transaction.type == "Expense" || transaction.type == "Purchase" || 
                        transaction.type == "Purchase Return" || transaction.type == "Salary Payment";
        
        switch (paymentTypeLower) {
          case "cash":
          case "efectivo":
            pagoEfectivo += paymentAmount;
            if (isExpense) {
              gastoEfectivo += paymentAmount;
            } else {
              ingresoEfectivo += paymentAmount;
            }
            break;
          case "bank":
          case "banco":
          case "transferencia":
            pagoTransferencia += paymentAmount;
            if (isExpense) {
              gastoTransferencia += paymentAmount;
            } else {
              ingresoTransferencia += paymentAmount;
            }
            break;
          case "card":
          case "tarjeta":
            pagoTarjetas += paymentAmount;
            if (isExpense) {
              gastoTarjeta += paymentAmount;
            } else {
              ingresoTarjeta += paymentAmount;
            }
            break;
        }
      }
    }

    return DailySummaryModel(
      totalFacturado: totalFacturado,
      totalPagado: totalPagado,
      totalPendiente: totalPendiente,
      pagoEfectivo: pagoEfectivo,
      pagoTransferencia: pagoTransferencia,
      pagoTarjetas: pagoTarjetas,
      ingresoEfectivo: ingresoEfectivo,
      gastoEfectivo: gastoEfectivo,
      ingresoTransferencia: ingresoTransferencia,
      gastoTransferencia: gastoTransferencia,
      ingresoTarjeta: ingresoTarjeta,
      gastoTarjeta: gastoTarjeta,
    );
  }

  // Método alternativo usando datos de Firebase directamente
  factory DailySummaryModel.fromFirebaseData(Map<dynamic, dynamic> firebaseData) {
    double totalFacturado = 0.0;
    double totalPagado = 0.0;
    double totalPendiente = 0.0;
    double pagoEfectivo = 0.0;
    double pagoTransferencia = 0.0;
    double pagoTarjetas = 0.0;

    firebaseData.forEach((key, value) {
      try {
        final data = Map<String, dynamic>.from(value);
        final type = data['type']?.toString() ?? '';
        final amount = (data['amount'] ?? 0).toDouble();
        final paidAmount = (data['paid_amount'] ?? 0).toDouble();
        final paymentType = data['payment_type']?.toString();

        // Total Facturado - solo ventas
        if (type == "Sale") {
          totalFacturado += amount;
        }

        // Total Pagado
        totalPagado += paidAmount;

        // Total Pendiente
        totalPendiente += (amount - paidAmount);

        // Pagos por método
        if (paidAmount > 0) {
          switch (paymentType) {
            case "Cash":
              pagoEfectivo += paidAmount;
              break;
            case "Bank":
              pagoTransferencia += paidAmount;
              break;
            case "Card":
              pagoTarjetas += paidAmount;
              break;
          }
        }
      } catch (e) {
        // Si hay error en algún registro, continuar con el siguiente
        print('Error procesando transacción $key: $e');
      }
    });

    return DailySummaryModel(
      totalFacturado: totalFacturado,
      totalPagado: totalPagado,
      totalPendiente: totalPendiente,
      pagoEfectivo: pagoEfectivo,
      pagoTransferencia: pagoTransferencia,
      pagoTarjetas: pagoTarjetas,
    );
  }
}