# Instrucciones para Verificación de Métodos de Pago (Versión Unificada)

Fecha: 8 de Agosto de 2025

## Descripción

Este documento actualiza las instrucciones para utilizar las herramientas de verificación de métodos de pago en DylanPOS. Hemos creado un nuevo verificador universal que unifica todas las herramientas anteriores, haciéndolo más fácil de usar y compatible con todos los entornos.

## Requisitos Previos

### Para el Verificador Universal (Recomendado):
- Solo necesitas un navegador web

### Para las otras herramientas (opcionales):
1. Node.js instalado (versión 14 o superior)
2. Firebase CLI instalado y configurado
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

## Verificador Universal (NUEVA VERSIÓN RECOMENDADA)

Hemos creado un nuevo verificador universal que integra todas las herramientas anteriores en una sola interfaz amigable y con mejor manejo de errores.

**Archivo:** `verificador_universal.sh`

**Cómo ejecutar:**
```bash
chmod +x lib/Screen/Inventory\ Sales/verificador_universal.sh
./lib/Screen/Inventory\ Sales/verificador_universal.sh
```

**Características:**
- Interfaz de menú interactiva en la terminal
- Integra todas las herramientas en un solo lugar
- No requiere instalación de Firebase CLI ni Node.js para la versión offline
- Interfaz visual moderna y fácil de usar
- Incluye colores en la terminal para mejor visualización
- Detecta automáticamente si faltan scripts y ofrece alternativas
- Mejor manejo de errores y guía paso a paso
- Compatible con macOS, Linux y Windows

**Opciones disponibles:**
1. **Verificador Offline** - No requiere autenticación, funciona con datos exportados de Firebase
2. **Verificador Web Directo** - Autenticación con Google directamente en el navegador
3. **Verificar factura específica** - Consulta rápida de una factura por número
4. **Generar informe completo** - Análisis detallado de todas las transacciones

## Herramientas Anteriores (para referencia)

Las siguientes herramientas siguen estando disponibles, pero recomendamos usar el Verificador Universal en su lugar:

### 1. Verificador Web Directo

**Archivo:** `verificador_web_directo.sh`

**Cómo ejecutar:**
```bash
chmod +x lib/Screen/Inventory\ Sales/verificador_web_directo.sh

# Para verificar una factura específica:
./lib/Screen/Inventory\ Sales/verificador_web_directo.sh 365

# Para generar un informe completo:
./lib/Screen/Inventory\ Sales/verificador_web_directo.sh informe
```

### 2. Verificador Offline Simple

**Archivo:** `verificador_offline_simple.sh`

**Cómo ejecutar:**
```bash
chmod +x lib/Screen/Inventory\ Sales/verificador_offline_simple.sh
./lib/Screen/Inventory\ Sales/verificador_offline_simple.sh
```

### 3. Generador de Informe HTML

**Archivo:** `generar_informe_metodos_pago.sh`

**Cómo ejecutar:**
```bash
chmod +x lib/Screen/Inventory\ Sales/generar_informe_metodos_pago.sh
./lib/Screen/Inventory\ Sales/generar_informe_metodos_pago.sh
```

### 4. Verificador de Factura Específica

**Archivo:** `verificar_factura_metodo_pago_simple.sh`

**Cómo ejecutar:**
```bash
chmod +x lib/Screen/Inventory\ Sales/verificar_factura_metodo_pago_simple.sh
./lib/Screen/Inventory\ Sales/verificar_factura_metodo_pago_simple.sh 365
```
(Donde 365 es el número de factura que deseas verificar)

## Ejemplo de Uso Común

Recomendamos usar el nuevo Verificador Universal:

1. Ejecuta el verificador universal:
   ```bash
   ./lib/Screen/Inventory\ Sales/verificador_universal.sh
   ```

2. Selecciona la opción que necesites del menú interactivo

3. Sigue las instrucciones en pantalla para completar la verificación

## Solución de Problemas

Si encuentras errores al ejecutar los scripts:

1. **Error de permisos**: Asegúrate de que los scripts tienen permisos de ejecución
   ```bash
   chmod +x lib/Screen/Inventory\ Sales/*.sh
   ```

2. **Error de Firebase**: La herramienta `verificador_offline_simple.sh` y la opción "Verificador Offline" del verificador universal no requieren Firebase CLI.

3. **Error al abrir el navegador**: Si el navegador no se abre automáticamente, puedes abrir manualmente el archivo HTML generado que se muestra en la consola.

4. **Error al cargar datos JSON**: Asegúrate de que estás exportando correctamente los datos de Firebase. El verificador incluye instrucciones detalladas sobre cómo hacerlo.

## Importante

Para corregir problemas con los métodos de pago, recuerda que estos se asignan en `inventory_sales.dart` alrededor de la línea 2423:

```dart
transitionModel.paymentType = selectedPaymentOption;
```

Este código se ejecuta solo cuando se completa el proceso de pago, por lo que cualquier método de pago no definido probablemente se debe a una falta de asignación o a un proceso de pago interrumpido.

---
Actualizado por: Miguel Castillo
Fecha: 8 de Agosto de 2025
