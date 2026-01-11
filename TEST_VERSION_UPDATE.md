# 🧪 Guía de Prueba del Sistema de Actualización Automática

## 📋 Resumen
Este sistema detecta cambios en el archivo `version.json` y muestra un popup al usuario para actualizar la aplicación. Al actualizar, se limpia toda la caché del navegador y se cierra la sesión del usuario.

## 🚀 Inicio Rápido

### Opción 1: Usar el script de prueba (Recomendado)
```bash
./test_update.sh
```

### Opción 2: Prueba manual
1. Ejecutar la aplicación:
   ```bash
   flutter run -d chrome --web-renderer html
   ```

2. En otra terminal, ver la versión actual:
   ```bash
   cat web/version.json
   ```

3. Simular una actualización:
   ```bash
   dart test_version_update.dart --update
   ```

## 📝 Escenarios de Prueba

### 1. Actualización Normal (Usuario puede postponer)
1. Inicia la aplicación con versión 1.0.0
2. Actualiza `version.json` a versión 1.0.1 con `forceUpdate: false`
3. Espera hasta 5 minutos (o reinicia la app)
4. **Resultado esperado:**
   - Aparece popup con la nueva versión
   - Botón "Más tarde" permite cerrar el popup
   - Botón "Actualizar ahora" cierra sesión y recarga

### 2. Actualización Forzada (Usuario debe actualizar)
1. Inicia la aplicación
2. Actualiza `version.json` a versión 2.0.0 con `forceUpdate: true`
3. Espera o reinicia
4. **Resultado esperado:**
   - Popup no se puede cerrar
   - Solo aparece botón "Actualizar ahora"
   - Mensaje indicando que es obligatorio

### 3. Sin Cambios (No debe aparecer popup)
1. Inicia la aplicación
2. No modifiques `version.json`
3. **Resultado esperado:**
   - No aparece ningún popup
   - La app funciona normalmente

## 🔧 Archivos de Prueba

### version.json - Actualización normal
```json
{
  "version": "1.0.1",
  "releaseDate": "2025-07-31",
  "description": "Mejoras de rendimiento y corrección de errores",
  "forceUpdate": false
}
```

### version.json - Actualización forzada
```json
{
  "version": "2.0.0",
  "releaseDate": "2025-07-31",
  "description": "Nueva versión con cambios importantes de seguridad",
  "forceUpdate": true
}
```

## 🔍 Verificación del Sistema

### 1. Verificar que el servicio está activo
- Abre las DevTools del navegador (F12)
- Ve a la consola
- Deberías ver mensajes como:
  ```
  Nueva versión disponible: 1.0.1
  ```
  o
  ```
  La aplicación está actualizada: 1.0.0
  ```

### 2. Verificar limpieza de caché
- Antes de actualizar, ve a Application > Storage en DevTools
- Toma nota de los datos en localStorage y sessionStorage
- Después de actualizar, verifica que están vacíos

### 3. Verificar cierre de sesión
- Inicia sesión en la aplicación
- Cuando aparezca el popup, da clic en "Actualizar ahora"
- Deberías ser redirigido a la pantalla de login

## 📊 Comportamiento del Sistema

| Componente | Comportamiento |
|------------|----------------|
| **Frecuencia de verificación** | Cada 5 minutos |
| **Verificación inicial** | Al cargar la aplicación |
| **Caché del navegador** | Se limpia completamente |
| **Service Workers** | Se desregistran |
| **Sesión Firebase** | Se cierra |
| **localStorage** | Se borra todo |
| **sessionStorage** | Se borra todo |

## 🐛 Solución de Problemas

### El popup no aparece
1. Verifica que `version.json` esté en la carpeta `web/`
2. Asegúrate de que el número de versión sea mayor
3. Espera al menos 5 minutos o reinicia la app
4. Revisa la consola del navegador por errores

### Error al actualizar
1. Verifica permisos del archivo `version.json`
2. Asegúrate de que Firebase esté configurado correctamente
3. Revisa que el usuario esté autenticado

### La caché no se limpia
1. Verifica en DevTools > Application > Clear Storage
2. Limpia manualmente y vuelve a intentar
3. Prueba en modo incógnito

## 🎯 Casos de Uso en Producción

1. **Actualizaciones menores**: Usa `forceUpdate: false`
   - Corrección de bugs
   - Mejoras de rendimiento
   - Nuevas características opcionales

2. **Actualizaciones críticas**: Usa `forceUpdate: true`
   - Parches de seguridad
   - Cambios breaking en la API
   - Correcciones críticas

## 📱 Notas Importantes

- El sistema solo funciona en la versión web
- La verificación consume mínimo ancho de banda
- El popup respeta el idioma configurado en la app
- Los usuarios no pueden saltarse actualizaciones forzadas