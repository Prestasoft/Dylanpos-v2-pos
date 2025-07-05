# Implementación de Visualización e Impresión de Facturas Pendientes

## Resumen de Cambios

Se ha implementado la funcionalidad para visualizar e imprimir facturas pendientes de pago en la pantalla de Cuentas por Cobrar. Esta nueva funcionalidad permite a los usuarios:

1. Ver una lista de todas las facturas pendientes de un cliente específico
2. Visualizar los detalles completos de cada factura
3. Imprimir facturas individuales en formato térmico o normal

## Cambios Realizados

### 1. Interfaz de Usuario
- Se agregó una nueva columna "Facturas" en la tabla de Cuentas por Cobrar
- Se implementó un botón "Ver facturas" con estilo visual distintivo
- Se creó un diálogo modal para mostrar la lista de facturas pendientes
- Se añadió visualización detallada de cada factura con todos sus productos

### 2. Funcionalidad de Consulta
- Se desarrolló la función `_obtenerFacturasPendientes` que consulta las facturas con deuda pendiente en Firebase
- Las facturas se filtran por el teléfono del cliente y monto pendiente mayor a cero
- Se implementó ordenamiento por fecha (más recientes primero)

### 3. Impresión de Facturas
- Se añadió un selector de tipo de impresión (térmica o normal)
- Se integró con el sistema de impresión existente en la aplicación
- Se corrigió la obtención de configuraciones necesarias para la impresión

### 4. Manejo de Errores
- Se implementaron comprobaciones de nulos en todos los campos críticos
- Se agregaron mensajes de error claros para cada posible fallo
- Se garantiza que la aplicación no falle incluso si no hay facturas o datos incompletos

## Próximos Pasos

1. **Mejora de Rendimiento**: Optimizar la consulta de facturas para grandes volúmenes de datos
2. **Mejora Visual**: Perfeccionar el diseño y añadir opciones de filtrado por fecha o monto
3. **Integración con WhatsApp**: Permitir enviar facturas pendientes a los clientes vía WhatsApp
4. **Pagos Parciales**: Implementar funcionalidad para aplicar pagos parciales directamente desde esta interfaz

## Uso

Para utilizar esta nueva funcionalidad:

1. Acceda a la pantalla de "Cuentas por Cobrar"
2. Busque el cliente deseado
3. Haga clic en "Ver facturas" en la última columna de la tabla
4. Se mostrará un diálogo con todas las facturas pendientes
5. Utilice las opciones "Ver detalle" para examinar la factura completa
6. Utilice "Imprimir factura" para generar e imprimir el documento

## Notas Técnicas

- Las facturas se identifican utilizando el número telefónico del cliente como clave de búsqueda
- La impresión requiere la configuración general y personal de la empresa
- El formateo de moneda utiliza el formato con comas para mejor legibilidad
