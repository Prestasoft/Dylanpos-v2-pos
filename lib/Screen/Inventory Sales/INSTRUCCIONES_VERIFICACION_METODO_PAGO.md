# Instrucciones para Verificación de Métodos de Pago (Versión Simplificada)

Fecha: 5 de Julio de 2025

## Descripción

Este documento actualiza las instrucciones para utilizar las herramientas de verificación de métodos de pago en DylanPOS. Hemos creado versiones simplificadas que no dependen de Flutter para ejecutarse, lo que las hace más compatibles con diferentes entornos.

## Requisitos Previos

### Para la herramienta más simple (Recomendada):
- Solo necesitas un navegador web

### Para las otras herramientas:
1. Node.js instalado (versión 14 o superior)
2. Firebase CLI instalado y configurado
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

## Herramientas Disponibles

### 1. Verificador Web Directo (RECOMENDADO)

Esta es la herramienta más fácil de usar y no requiere ninguna instalación previa. Funciona directamente en el navegador.

**Archivo:** `verificador_web_directo.sh`

**Cómo ejecutar:**
```bash
chmod +x lib/Screen/Inventory\ Sales/verificador_web_directo.sh

# Para verificar una factura específica:
./lib/Screen/Inventory\ Sales/verificador_web_directo.sh 365

# Para generar un informe completo:
./lib/Screen/Inventory\ Sales/verificador_web_directo.sh informe
```

**Características:**
- No requiere instalación de Firebase CLI ni Node.js
- Se autentica directamente en el navegador con tu cuenta de Google
- Interfaz visual moderna y fácil de usar
- Permite verificar facturas específicas o generar un informe completo
- Incluye filtros avanzados y detección de problemas

### 2. Generador de Informe HTML

**Archivo:** `generar_informe_metodos_pago.sh`

**Cómo ejecutar:**
```bash
chmod +x lib/Screen/Inventory\ Sales/generar_informe_metodos_pago.sh
./lib/Screen/Inventory\ Sales/generar_informe_metodos_pago.sh
```

**Características:**
- Interfaz visual en HTML que se abre automáticamente en tu navegador
- Filtros por fecha, método de pago y número de factura
- Resumen estadístico de ventas y problemas detectados
- Resaltado visual de transacciones con problemas
- Requiere Node.js y Firebase CLI

### 3. Verificador de Factura Específica

Para consultar rápidamente una factura específica desde la línea de comandos.

**Archivo:** `verificar_factura_metodo_pago_simple.sh`

**Cómo ejecutar:**
```bash
chmod +x lib/Screen/Inventory\ Sales/verificar_factura_metodo_pago_simple.sh
./lib/Screen/Inventory\ Sales/verificar_factura_metodo_pago_simple.sh 365
```
(Donde 365 es el número de factura que deseas verificar)

**Características:**
- Consulta rápida desde la terminal
- Muestra todos los detalles de la factura específica
- Indica si hay problemas con el método de pago
- Incluye un resumen general de todas las ventas
- Requiere Node.js y Firebase CLI

## Ejemplo de Uso Común

Recomendamos este flujo de trabajo:

1. Usa el Verificador Web Directo (es el más sencillo):
   ```bash
   ./lib/Screen/Inventory\ Sales/verificador_web_directo.sh informe
   ```

2. Utiliza los filtros en la interfaz web para identificar facturas problemáticas

3. Si necesitas detalles específicos de una factura, puedes consultarla directamente:
   ```bash
   ./lib/Screen/Inventory\ Sales/verificador_web_directo.sh 365
   ```

## Solución de Problemas

Si encuentras errores al ejecutar los scripts:

1. **Error de permisos**: Asegúrate de que los scripts tienen permisos de ejecución
   ```bash
   chmod +x lib/Screen/Inventory\ Sales/*.sh
   ```

2. **Error de Firebase**: La herramienta `verificador_web_directo.sh` no requiere Firebase CLI, pero para las otras herramientas, verifica que estás autenticado:
   ```bash
   firebase login
   ```

3. **Error de Node.js**: Para las herramientas que lo requieren, asegúrate de tener Node.js instalado
   ```bash
   node --version
   ```

## Importante

Para corregir problemas con los métodos de pago, recuerda que estos se asignan en `inventory_sales.dart` alrededor de la línea 2423:

```dart
transitionModel.paymentType = selectedPaymentOption;
```

Este código se ejecuta solo cuando se completa el proceso de pago, por lo que cualquier método de pago no definido probablemente se debe a una falta de asignación o a un proceso de pago interrumpido.

---
Creado por: Miguel Castillo
Contacto: [correo electrónico]
