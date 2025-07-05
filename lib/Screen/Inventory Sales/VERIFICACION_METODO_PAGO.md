# Verificación de Métodos de Pago en DylanPOS

Fecha: 5 de Julio de 2025

## Descripción

Este documento describe las herramientas creadas para verificar si las ventas realizadas en el sistema DylanPOS tienen correctamente registrado el método de pago. El método de pago es un campo crucial que debe guardarse correctamente en cada transacción para mantener la integridad de los registros financieros.

## Problema Detectado

Se ha observado que en algunas transacciones de venta, el campo `paymentType` (método de pago) puede no estar correctamente registrado en Firebase. Esta información es esencial para:

1. Llevar un control preciso de los ingresos por método de pago
2. Realizar cuadres de caja correctos
3. Generar informes financieros precisos

## Herramientas de Verificación

Se han desarrollado las siguientes herramientas para verificar y diagnosticar problemas con los métodos de pago:

### 1. Verificador Visual de Métodos de Pago

**Archivo:** `verificador_metodo_pago.dart`
**Script de ejecución:** `ejecutar_verificador_metodo_pago.sh`

Esta herramienta proporciona una interfaz gráfica que permite:

- Visualizar todas las ventas realizadas en un período de tiempo
- Filtrar por método de pago
- Identificar visualmente las ventas con problemas (sin método de pago o con método de pago incorrecto)
- Ver detalles completos de cada venta

**Cómo ejecutar:**
```bash
chmod +x lib/Screen/Inventory\ Sales/ejecutar_verificador_metodo_pago.sh
./lib/Screen/Inventory\ Sales/ejecutar_verificador_metodo_pago.sh
```

### 2. Verificador de Factura Específica

**Archivo:** `verificar_factura_metodo_pago.sh`

Esta herramienta de línea de comandos permite verificar el método de pago para una factura específica, proporcionando detalles completos de la transacción.

**Cómo ejecutar:**
```bash
chmod +x lib/Screen/Inventory\ Sales/verificar_factura_metodo_pago.sh
./lib/Screen/Inventory\ Sales/verificar_factura_metodo_pago.sh 12345
```
(Donde 12345 es el número de factura que desea verificar)

## Implementación Técnica

### Modelo de Transacción de Venta

En el archivo `lib/model/sale_transaction_model.dart`, el método de pago se guarda en el campo `paymentType` de la clase `SaleTransactionModel`. Este campo se establece justo antes de guardar la transacción en Firebase, específicamente en el bloque:

```dart
transitionModel.paymentType = selectedPaymentOption;
```

### Flujo Correcto de Guardado

El flujo correcto para guardar una venta con su método de pago es:

1. El usuario selecciona un método de pago del dropdown (`selectedPaymentOption`)
2. Al hacer clic en el botón de pago, se crea una instancia de `SaleTransactionModel`
3. Justo antes de guardar en Firebase, se asigna `selectedPaymentOption` a `transitionModel.paymentType`
4. La transacción se guarda en Firebase con el método de pago correcto

## Recomendaciones para Solucionar Problemas

Si se encuentran ventas con métodos de pago incorrectos o faltantes:

1. Verificar que el método de pago se asigna correctamente antes de guardar la transacción
2. Comprobar que no hay código que anule o sobrescriba el valor del método de pago
3. Asegurarse de que el valor predeterminado para `selectedPaymentOption` sea un valor válido
4. Realizar pruebas exhaustivas con diferentes métodos de pago

## Notas Adicionales

- El método de pago se establece **únicamente cuando se confirma la venta**, no al seleccionar la opción en el dropdown
- Las cotizaciones tienen un método de pago fijo "Just Quotation" y no deberían considerarse problemáticas

---
Creado por: Miguel Castillo
Contacto: [correo electrónico]
