# 📦 Guía de Despliegue - Sistema de Actualización Automática

## 🚀 Pasos para Desplegar en Producción

### 1. Compilar la aplicación para producción
```bash
flutter clean
flutter pub get
flutter build web --web-renderer html --release
```

### 2. Preparar el archivo de versión inicial

Crear el archivo `app-version.json` en la carpeta `build/web/`:

```json
{
  "version": "1.0.0",
  "releaseDate": "2025-07-31",
  "description": "Versión inicial del sistema",
  "forceUpdate": false
}
```

### 3. Subir al hosting

Sube TODO el contenido de la carpeta `build/web/` a tu hosting, incluyendo:
- Todos los archivos y carpetas generados por Flutter
- El archivo `app-version.json`

### 4. Verificar que funciona

Una vez desplegado, verifica que el archivo es accesible:
```
https://tu-dominio.com/app-version.json
```

## 📝 Cómo publicar una actualización

### 1. Actualización normal (el usuario puede postponer)

1. Compila la nueva versión:
   ```bash
   flutter build web --web-renderer html --release
   ```

2. Actualiza SOLO el archivo `app-version.json` en el hosting:
   ```json
   {
     "version": "1.0.1",
     "releaseDate": "2025-08-01",
     "description": "Corrección de errores y mejoras de rendimiento",
     "forceUpdate": false
   }
   ```

3. Los usuarios verán el popup en máximo 5 minutos.

### 2. Actualización forzada (obligatoria)

Para actualizaciones críticas de seguridad o cambios importantes:

```json
{
  "version": "2.0.0",
  "releaseDate": "2025-08-01",
  "description": "Actualización crítica de seguridad",
  "forceUpdate": true
}
```

### 3. Proceso completo de actualización

1. **Primero**: Sube SOLO el `app-version.json` actualizado
2. **Espera**: 10-15 minutos para que todos los usuarios vean la notificación
3. **Después**: Sube los archivos de la aplicación compilada

Este orden evita que los usuarios accedan a una versión incompleta.

## ⚙️ Configuración del servidor web

### Nginx
Agrega estas cabeceras para evitar caché del archivo de versión:

```nginx
location /app-version.json {
    add_header Cache-Control "no-cache, no-store, must-revalidate";
    add_header Pragma "no-cache";
    add_header Expires "0";
}
```

### Apache (.htaccess)
```apache
<Files "app-version.json">
    Header set Cache-Control "no-cache, no-store, must-revalidate"
    Header set Pragma "no-cache"
    Header set Expires "0"
</Files>
```

## 🔍 Monitoreo

### Logs útiles en producción
Los usuarios verán en la consola del navegador (F12):
- "Nueva versión disponible: X.X.X" cuando hay actualización
- "La aplicación está actualizada: X.X.X" cuando está al día

### Verificar versión actual de un usuario
En la consola del navegador, ejecuta:
```javascript
localStorage.getItem('app_version')
```

## 🛠️ Solución de problemas

### El popup no aparece
1. Verifica que `app-version.json` sea accesible públicamente
2. Revisa que no haya errores CORS
3. Asegúrate de que el número de versión sea mayor
4. Limpia caché del navegador

### Error CORS
Si ves errores CORS, agrega estas cabeceras en tu servidor:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET
Access-Control-Allow-Headers: Content-Type
```

### La actualización no se aplica
1. Verifica que Firebase Auth esté funcionando
2. Revisa que el service worker se desregistre correctamente
3. Prueba en modo incógnito

## 📊 Mejores prácticas

1. **Versionado semántico**: Usa X.Y.Z
   - X: Cambios mayores (breaking changes)
   - Y: Nuevas funcionalidades
   - Z: Corrección de bugs

2. **Descripción clara**: Explica qué cambia en cada versión

3. **Actualizaciones forzadas**: Úsalas solo cuando sea necesario:
   - Parches de seguridad críticos
   - Cambios en la API que rompen compatibilidad
   - Correcciones de bugs críticos

4. **Horario de actualización**: Despliega cuando haya menos usuarios activos

5. **Comunicación**: Considera notificar a los usuarios sobre actualizaciones importantes por otros medios

## 🔒 Seguridad

- El archivo `app-version.json` es público, no incluyas información sensible
- La limpieza de caché y cierre de sesión es automática
- Los usuarios deben volver a autenticarse después de actualizar