# Pasos para Probar la Generación de Facturas

## Opción 1: Prueba Directa en el Módulo

1. **Inicia sesión** en la aplicación normalmente

2. **Ve al módulo "Impresión y Enmarcado"**
   - En el menú lateral, busca el botón con ícono de cámara
   - El texto debe decir "Impresión y Enmarcado"

3. **Abre la Consola del Navegador** (F12)
   - Ve a la pestaña "Console"
   - Limpia la consola para ver solo los nuevos mensajes

4. **En el módulo, realiza estos pasos**:
   - Selecciona un cliente (cualquiera)
   - Agrega al menos un producto o servicio
   - Observa los mensajes en la consola
   - Haz clic en "Imprimir Factura"

5. **Observa los mensajes de debug**:
   ```
   Creando modelo de factura...
   Customer: [nombre del cliente]
   Products: [número]
   Services: [número]
   Total: [monto]
   Modelo de factura creado exitosamente
   Factura guardada con ID: [id]
   Iniciando generación de PDF...
   PersonalInfo: [nombre empresa], Phone: [teléfono]
   GeneralSetting: [nombre]
   ```

## Si ves algún error, comparte:
1. El mensaje exacto del error
2. En qué paso falló
3. Si aparece algún mensaje sobre "PersonalInformation es null" o "GeneralSetting es null"

## Errores Comunes y Soluciones:

### Error: "PersonalInformation es null"
- El perfil de la empresa no está configurado
- Ve a Configuración > Perfil de Empresa

### Error: "No se pudo cargar el logo"
- El archivo de logo no existe o no está accesible
- Puedes ignorar este error, el PDF se generará sin logo

### Error: Firebase 400
- Hay un problema con los permisos de Firebase
- La factura podría generarse pero no guardarse

## Opción 2: Prueba Rápida sin Firebase

Si quieres probar solo la generación del PDF sin guardar en Firebase, puedes:

1. Comentar temporalmente las líneas 1197-1204 en `photo_invoice_screen_v2.dart`
2. Esto saltará el guardado en Firebase
3. El PDF debería generarse normalmente

Comparte qué mensajes aparecen en la consola para poder ayudarte mejor.