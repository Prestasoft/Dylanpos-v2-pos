# Instrucciones para Debuggear la Generación de Facturas

## Problema Identificado
La generación de facturas PDF no está funcionando correctamente. He agregado logs de debugging extensivos para identificar el problema exacto.

## Pasos para Identificar el Error

### 1. Ejecutar la Aplicación
```bash
flutter run -d chrome --web-renderer html
```

### 2. Probar con la Página de Test
He creado una página de prueba específica para aislar el problema. Navega a:
```
http://localhost:[puerto]/#/sales/test-invoice
```

Esta página:
- Crea datos de prueba automáticamente
- No requiere conexión a Firebase
- Muestra mensajes de estado en tiempo real
- Identifica exactamente dónde falla el proceso

### 3. Si la Página de Test Funciona
Si la factura de prueba se genera correctamente, el problema está en:
- Los datos del cliente seleccionado
- Los providers de PersonalInformation o GeneralSetting
- La conexión con Firebase

### 4. Si la Página de Test NO Funciona
Revisar la consola del navegador (F12) para ver:
- El error específico
- En qué línea del PDF está fallando

### 5. Prueba Manual en el Módulo Real
1. Ir a "Impresión y Enmarcado"
2. Seleccionar un cliente
3. Agregar al menos un producto o servicio
4. Hacer clic en "Imprimir Factura"
5. Revisar la consola del navegador para ver los logs:
   - `Creando modelo de factura...`
   - `PersonalInfo: [nombre], Phone: [teléfono]`
   - `GeneralSetting: [nombre]`
   - `Iniciando generación de PDF...`

## Posibles Causas del Error

### 1. Problema con el Logo
Si el error menciona `images/vg_logo.png`:
- Verificar que el archivo existe en la carpeta `images/`
- Verificar que está declarado en `pubspec.yaml`

### 2. Problema con PersonalInformation
Si el error menciona campos de `personalInformation`:
- El usuario no ha configurado su perfil completamente
- Falta información de la empresa en Firebase

### 3. Problema con Campos Null
Si el error menciona "null" o "late field":
- Algún campo requerido no está siendo inicializado
- Los datos del cliente están incompletos

## Solución Temporal
Si necesitas generar facturas urgentemente mientras resolvemos el problema:

1. Comenta temporalmente la línea del logo en `photo_invoice_pdf_pro.dart`:
   ```dart
   // Alrededor de la línea 72-78
   // if (image != null) ...[
   //   pw.Container(...),
   //   pw.SizedBox(width: 15),
   // ],
   ```

2. Verifica que el cliente tenga todos los campos completos:
   - Nombre
   - Teléfono
   - Dirección (puede estar vacía pero no null)

## Información para Reportar
Si el problema persiste, comparte:
1. El mensaje de error exacto de la consola
2. Los logs que aparecen antes del error
3. Si la página de test funciona o no
4. La versión de Flutter (`flutter --version`)

## Nota Importante
Los `print` statements son solo para debugging. Una vez identificado y resuelto el problema, se deben remover para la versión de producción.