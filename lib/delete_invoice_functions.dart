import 'dart:convert';
import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/model/purchase_transation_model.dart';

import 'const.dart';
import 'model/product_model.dart';
import 'model/sale_transaction_model.dart';

class DeleteInvoice {
  Future<void> editStockAndSerial({
    required SaleTransactionModel saleTransactionModel,
  }) async {
    for (var product in saleTransactionModel.productList!) {
      final ref = FirebaseDatabase.instance.ref('${await getUserID()}/Products/');

      // Buscar el producto por productCode
      final data = await ref.orderByChild('productCode').equalTo(product.productId).once();

      if (data.snapshot.value == null) {
        continue; // No se encontró el producto
      }

      // Obtener la clave del producto directamente
      final dataMap = Map.from(data.snapshot.value as Map);
      final productPath = dataMap.keys.first;

      // Obtener el stock actual
      var stockSnap = await ref.child('$productPath/productStock').get();
      int currentStock = int.tryParse(stockSnap.value.toString()) ?? 0;
      int updatedStock = currentStock + int.tryParse(product.quantity.toString())!;

      // Actualizar el stock
      await ref.child(productPath).update({'productStock': '$updatedStock'});

      /// Agregar los números de serie nuevamente
      ProductModel? productData;
      final serialRef = FirebaseDatabase.instance.ref('${await getUserID()}/Products/$productPath');

      await serialRef.orderByKey().get().then((value) {
        productData = ProductModel.fromJson(jsonDecode(jsonEncode(value.value)));
      });

      for (var serial in product.serialNumber ?? []) {
        if (!productData!.serialNumber.contains(serial)) {
          productData!.serialNumber.add(serial);
        }
      }

      await serialRef.child('serialNumber').set(productData!.serialNumber);
    }
  }

  Future<void> editStockAndSerialForPurchase({required PurchaseTransactionModel saleTransactionModel}) async {
    for (var element in saleTransactionModel.productList!) {
      final ref = FirebaseDatabase.instance.ref('${await getUserID()}/Products/');

      final data = await ref.orderByChild('productCode').equalTo(element.productCode).once();

      if (data.snapshot.value == null) {
        continue; // No se encontró el producto
      }

      final dataMap = Map.from(data.snapshot.value as Map);
      final productPath = dataMap.keys.first;

      var data1 = await ref.child('$productPath/productStock').get();
      int stock = int.parse(data1.value.toString());
      int remainStock = stock - int.parse(element.productStock.toString());

      await ref.child(productPath).update({'productStock': '$remainStock'});

      ///_____serial_remove________________________________
      ProductModel? productData;

      final serialRef = FirebaseDatabase.instance.ref('${await getUserID()}/Products/$productPath');
      await serialRef.orderByKey().get().then((value) {
        productData = ProductModel.fromJson(jsonDecode(jsonEncode(value.value)));
      });

      for (var serial in element.serialNumber) {
        productData!.serialNumber.remove(serial);
      }

      await serialRef.child('serialNumber').set(productData!.serialNumber.map((e) => e).toList());
    }
  }

  Future<void> customerDueUpdate({required String phone, required num due}) async {
    if (due > 0) {
      final ref = FirebaseDatabase.instance.ref('${await getUserID()}/Customers/');
      String? key;

      await FirebaseDatabase.instance.ref(await getUserID()).child('Customers').orderByKey().get().then((value) {
        for (var element in value.children) {
          var data = jsonDecode(jsonEncode(element.value));
          if (data['phoneNumber'] == phone) {
            key = element.key;
          }
        }
      });
      var data1 = await ref.child('$key/due').get();
      int previousDue = data1.value.toString().toInt();

      int totalDue;

      totalDue = previousDue - due.toInt();
      await ref.child(key!).update({'due': '$totalDue'});
    }
  }

  Future<void> updateFromShopRemainBalance({required num paidAmount, required bool isFromPurchase}) async {
    if (paidAmount > 0) {
      final ref = FirebaseDatabase.instance.ref('${await getUserID()}/Personal Information');
      var data1 = await ref.child("remainingShopBalance").get();
      num previousBalance = data1.value.toString().toInt();
      await ref.update({'remainingShopBalance': isFromPurchase ? previousBalance + paidAmount : previousBalance - paidAmount});
    }
  }

  Future<void> deleteDailyTransaction({required String invoice, required String status, required String field}) async {
    final ref = FirebaseDatabase.instance.ref('${await getUserID()}/Daily Transaction');
    String? key;

    await FirebaseDatabase.instance.ref(await getUserID()).child('Daily Transaction').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['type'] == status && data[field]['invoiceNumber'] == invoice) {
          key = element.key;
        }
      }
    });
    if (key == null) {
      log('No transaction found for invoice: $invoice with status: $status');
      return;
    }
    await ref.child(key!).remove();
  }
}
