# Corrección de Funcionalidad de Impresión de Facturas

## Problema
Los botones de imprimir y ver PDF de facturas no estaban funcionando correctamente debido a la falta de implementación del método `generateThermalDocument` que es utilizado para la impresión en formato térmico (para impresoras de 58-80mm).

## Solución implementada

### 1. Implementación de generación de PDF térmico

Se ha añadido la función `generateThermalDocument` en el archivo `sales_invoice_pdf.dart`. Esta función crea un documento PDF optimizado para impresoras térmicas con las siguientes características:

- Ancho reducido (58mm) para adaptarse a impresoras térmicas pequeñas
- Fuentes más pequeñas para mejor legibilidad en papel térmico
- Diseño compacto que incluye toda la información esencial:
  - Encabezado con logo (si está disponible)
  - Información de la empresa
  - Número de factura y fecha
  - Datos del cliente
  - Lista detallada de productos
  - Subtotal, impuestos y descuentos
  - Total final
  - Método de pago y monto pendiente
  - Pie de página con información adicional

### 2. Mejora en el manejo de errores

Se ha mejorado el manejo de errores en la función `_imprimirFactura` del archivo `due_list_screen.dart`:

- Se ha añadido un bloque `try-catch` adicional alrededor de la llamada a `printSaleInvoice`
- Se muestran mensajes de error más descriptivos y detallados
- Se registran todos los errores en la consola para facilitar la depuración
- Se limita la longitud de los mensajes de error para evitar sobrecarga de información

### 3. Mantenimiento de la interfaz de usuario

El diálogo de selección de tipo de impresión se ha mantenido igual, ofreciendo las opciones:
- **Factura térmica**: Para impresoras de 58-80mm
- **Factura normal**: Formato completo A4/Letter

## Instrucciones de uso

1. En la pantalla de Cuentas por Cobrar, busque el cliente deseado
2. Haga clic en "Ver facturas" en la última columna
3. Se mostrará un diálogo con todas las facturas pendientes
4. Utilice el botón de impresión (icono de impresora) para imprimir una factura
5. Seleccione el formato deseado (térmico o normal)
6. El sistema generará e imprimirá el documento

## Notas técnicas

- La impresión térmica es especialmente útil para negocios que utilizan impresoras de tickets pequeñas
- El formato normal es más adecuado para documentación formal y archivado
- Ambos formatos incluyen toda la información necesaria para cumplir con requisitos fiscales
- El sistema guarda automáticamente una copia del PDF en Firebase Storage para referencia futura

## Próximas mejoras

- Agregar opción para enviar facturas por correo electrónico
- Implementar la posibilidad de generar múltiples facturas a la vez
- Mejorar el diseño visual de las facturas térmicas
- Agregar código QR para verificación de autenticidad
