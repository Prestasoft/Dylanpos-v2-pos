# Validación del Método de Pago en Ventas de Inventario

## Resumen
Este documento proporciona instrucciones para verificar que el método de pago seleccionado durante una venta en la pantalla de Inventory Sales se guarda correctamente en la base de datos Firebase.

## Flujo de funcionamiento del método de pago

### 1. Selección del método de pago
En la pantalla de Inventory Sales, el usuario puede seleccionar un método de pago desde un menú desplegable. El método seleccionado se almacena en la variable `selectedPaymentOption`.

```dart
// Definición de la variable
late String selectedPaymentOption = paymentItem.first;

// Widget de selección
DropdownButton<String>(
  value: selectedPaymentOption,
  onChanged: (value) {
    setState(() {
      selectedPaymentOption = value!;
    });
  },
  items: paymentItem.map<DropdownMenuItem<String>>((String value) {
    return DropdownMenuItem<String>(
      value: value,
      child: Text(value),
    );
  }).toList(),
)
```

### 2. Asignación del método de pago al modelo de transacción
Cuando el usuario presiona el botón de pago y se procesa la transacción, el valor de `selectedPaymentOption` se asigna a la propiedad `paymentType` del modelo de transacción:

```dart
transitionModel.paymentType = selectedPaymentOption;
```

### 3. Guardado en Firebase
El modelo de transacción completo, incluyendo el método de pago, se guarda en Firebase:

```dart
post = checkLossProfit(transitionModel: transitionModel);
await ref.push().set(post.toJson());
```

## Verificación

Para verificar que el método de pago se guarda correctamente, hemos desarrollado una herramienta de validación que:

1. Lee las últimas transacciones de ventas de Firebase
2. Muestra el método de pago almacenado para cada transacción
3. Permite verificar si coincide con lo seleccionado durante la venta

## Instrucciones de uso

### Paso 1: Realizar una venta con un método de pago específico
1. Acceda a la pantalla de Inventory Sales
2. Agregue productos al carrito
3. Seleccione un método de pago específico (por ejemplo, "Card", "Cash", etc.)
4. Complete la venta haciendo clic en el botón de pago
5. Anote el número de factura generado

### Paso 2: Ejecutar la herramienta de validación
1. Abra una terminal en la raíz del proyecto
2. Ejecute el siguiente comando:

```bash
./lib/Screen/Inventory\ Sales/ejecutar_validacion_metodo_pago.sh
```

3. Se abrirá una aplicación que mostrará las últimas transacciones

### Paso 3: Verificar los resultados
1. Busque la transacción con el número de factura anotado
2. Verifique que el método de pago mostrado coincide con el seleccionado durante la venta
3. Si coinciden, la implementación está funcionando correctamente

## Solución de problemas

Si el método de pago no coincide con el seleccionado, verifique:

1. Que no haya errores en la consola durante el proceso de guardado
2. Que la asignación `transitionModel.paymentType = selectedPaymentOption` se esté ejecutando
3. Que el método `toJson()` del modelo `SaleTransactionModel` incluya la propiedad `paymentType`

## Código relevante

El método de pago se asigna y guarda en el siguiente fragmento de código:

```dart
try {
  ref = FirebaseDatabase.instance.ref("${await getUserID()}/Sales Transition");
  (double.tryParse(dueAmountController.text) ?? 0) <= 0 ? transitionModel.isPaid = true : transitionModel.isPaid = false;
  (double.tryParse(dueAmountController.text) ?? 0) <= 0 ? transitionModel.dueAmount = 0 : transitionModel.dueAmount = (double.tryParse(dueAmountController.text) ?? 0);
  (double.tryParse(changeAmountController.text) ?? 0) > 0 ? transitionModel.returnAmount = (double.tryParse(changeAmountController.text) ?? 0).abs() : transitionModel.returnAmount = 0;
  transitionModel.paymentType = selectedPaymentOption;
  transitionModel.sellerName = isSubUser ? constSubUserTitle : 'Admin';
  post = checkLossProfit(transitionModel: transitionModel);
  await ref.push().set(post.toJson());
} catch (e) {
  print('ERROR al guardar transacción: $e');
  EasyLoading.showError('Error al guardar la venta: ${e.toString()}');
  setState(() => saleButtonClicked = false);
  return;
}
```

La definición del modelo `SaleTransactionModel` incluye la propiedad `paymentType`:

```dart
class SaleTransactionModel {
  // Otras propiedades...
  String? paymentType;
  
  SaleTransactionModel({
    // Otros parámetros...
    this.paymentType,
  });
  
  Map<String, dynamic> toJson() {
    return {
      // Otras propiedades...
      'paymentType': paymentType,
    };
  }
}
```
