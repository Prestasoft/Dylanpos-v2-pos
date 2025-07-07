# Corrección de Error al Agregar Productos Adicionales

## Problema Identificado
Al agregar productos adicionales a una venta antes de facturar, se producía un error con Firebase relacionado con rutas inválidas. Este error estaba relacionado con caracteres no permitidos en rutas de Firebase.

## Causa Raíz
1. **Problema de Serialización**: El modelo `AddToCartModel` tenía un método `toJson()` que devolvía un `String` en lugar de un `Map<String, dynamic>`, lo que causaba inconsistencias en la serialización cuando `SaleTransactionModel` esperaba un Map.

2. **Campos no Sanitizados**: Los identificadores como `reservationId`, `dressId` y `serviceId` podían contener caracteres inválidos para Firebase (`.`, `#`, `$`, `[`, `]`) y no estaban siendo sanitizados adecuadamente.

## Solución Implementada

1. **Corrección del Método toJson()**:
   - Se ha modificado el método `toJson()` en `AddToCartModel` para que devuelva un `Map<String, dynamic>` en lugar de un `String`.
   - Se ha añadido un método `toJsonString()` para mantener la funcionalidad original.

2. **Sanitización de Identificadores**:
   - Se han sanitizado los campos `reservationId`, `dressId` y `serviceId` para eliminar caracteres no permitidos en Firebase.
   ```dart
   'reservationId': reservationId != null ? reservationId!.replaceAll(RegExp(r'[.#$\[\]]'), '_') : null,
   "dressId": dressId != null ? dressId!.replaceAll(RegExp(r'[.#$\[\]]'), '_') : null,
   "serviceId": serviceId != null ? serviceId!.replaceAll(RegExp(r'[.#$\[\]]'), '_') : null,
   ```

## Beneficios

1. **Mayor Robustez**: El sistema ahora maneja de forma segura identificadores que podrían contener caracteres especiales.
2. **Serialización Correcta**: Los productos del carrito se serializan correctamente para Firebase.
3. **Prevención de Errores**: Se evitan errores relacionados con rutas inválidas en Firebase al agregar productos adicionales.

## Recomendaciones Adicionales

1. **Sanitización Centralizada**: Considerar crear una función utilitaria global para sanitizar todos los identificadores que se usan en rutas de Firebase.
2. **Validación de Datos**: Implementar validación de datos en el lado del cliente antes de enviar a Firebase.
3. **Monitoreo de Errores**: Agregar más logs de depuración para identificar rápidamente problemas similares en el futuro.

## Impacto de la Corrección

Esta corrección permite que los usuarios puedan agregar productos adicionales a una venta antes de facturar sin encontrar errores relacionados con Firebase.
