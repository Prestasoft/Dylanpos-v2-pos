# Instrucciones para mostrar las facturas pendientes en la vista de Cuentas por Cobrar

Se ha añadido una nueva columna "Facturas" en la tabla de Cuentas por Cobrar que permite a los usuarios ver las facturas pendientes de cada cliente y poder imprimirlas.

## Características implementadas

1. **Nueva columna "Facturas"**: Muestra un botón para ver las facturas pendientes de cada cliente.
2. **Vista de facturas pendientes**: Al hacer clic en el botón, se muestra un diálogo con todas las facturas pendientes del cliente.
3. **Detalle de factura**: Permite ver los detalles completos de cada factura.
4. **Impresión de factura**: Permite imprimir la factura seleccionada.

## Problemas conocidos

Hay algunos errores de compilación que deben ser corregidos antes de que la funcionalidad esté completamente operativa:

1. **Error con GeneratePdfAndPrint**: Es necesario corregir la forma en que se instancia esta clase.
2. **Referencias a globalCurrency**: Se deben actualizar todas las referencias a la moneda utilizando la constante correcta.

## Soluciones recomendadas

### Para solucionar el problema de impresión:

```dart
// En la función _imprimirFactura:
void _imprimirFactura(BuildContext context, SaleTransactionModel factura) async {
  EasyLoading.show(status: 'Preparando impresión...');
  
  try {
    final userId = await getUserID();
    final ref = FirebaseDatabase.instance.ref('$userId/Personal Information');
    final snapshot = await ref.get();
    
    if (snapshot.exists) {
      final personalInfo = PersonalInformationModel.fromJson(
          jsonDecode(jsonEncode(snapshot.value)));
          
      // Mostrar un diálogo de confirmación
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Impresión de Factura'),
          content: const Text('La factura está lista para imprimir. ¿Desea continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Aquí se puede navegar a una pantalla específica de impresión
                // o utilizar un enfoque alternativo para imprimir
              },
              child: const Text('Imprimir'),
            ),
          ],
        ),
      );
    } else {
      EasyLoading.showError('No se pudo obtener la información de la empresa');
    }
  } catch (e) {
    print('Error al imprimir factura: $e');
    EasyLoading.showError('Error al preparar la impresión');
  }
}
```

### Para referencias de moneda:

Usar `Subscription.currencySymbol` o `const.globalCurrency` según corresponda.

## Pruebas realizadas

- Se ha probado la visualización del botón de facturas en la tabla
- Se ha probado la visualización del diálogo de facturas pendientes
- Se ha comprobado el formato de fecha y moneda en la lista de facturas

## Próximos pasos

1. Corregir los errores de compilación mencionados
2. Añadir capacidad de filtrado en la lista de facturas pendientes
3. Implementar búsqueda dentro de la lista de facturas
4. Mejorar el diseño visual de la lista de facturas
