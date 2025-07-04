# Cambio de Logo del Sidebar por Nombre de Sucursal

## Descripción
Se realizó la modificación del header del sidebar para mostrar el nombre de la sucursal en texto en lugar del logo de imagen.

## Cambios Realizados

### 1. Modificación en global_side_bar.dart
**Archivo:** `/lib/Route/global_side_bar.dart`

**Función modificada:** `_buildHeader`

**Cambios principales:**
- Se eliminó la carga de imágenes (`Image.network`) del header del sidebar
- Se reemplazó por texto que muestra el nombre de la sucursal obtenido desde `GeneralSettingModel.companyName`
- Se implementaron dos modos de visualización:
  - **Modo icono (sidebar colapsado):** Muestra las iniciales de la sucursal en un contenedor con fondo de color
  - **Modo expandido:** Muestra el nombre completo de la sucursal centrado

### 2. Implementación de la lógica
```dart
// Obtener el nombre de la sucursal desde la configuración general
final branchName = setting.companyName.isNotEmpty == true 
    ? setting.companyName 
    : 'DylanPOS';
```

### 3. Visualización por modo

#### Modo Icono (sidebar colapsado):
- Contenedor de 38x38 píxeles con fondo azul (`kMainColor`)
- Muestra hasta 2 iniciales del nombre de la sucursal en mayúsculas
- Texto blanco y bold para buena visibilidad

#### Modo Expandido:
- Texto completo del nombre de la sucursal
- Estilo: `titleLarge`, color blanco, bold, tamaño 18
- Centrado horizontalmente
- Máximo 2 líneas con overflow ellipsis

## Fuente de Datos
El nombre de la sucursal se obtiene del campo `companyName` en `GeneralSettingModel`, que se accede a través del `generalSettingProvider`.

## Valor por defecto
Si no hay nombre configurado, se muestra "DylanPOS" como valor por defecto.

## Beneficios
1. **Identificación visual mejorada:** El usuario puede identificar fácilmente en qué sucursal está trabajando
2. **Personalización:** Cada sucursal puede tener su nombre distintivo
3. **Responsive:** Se adapta tanto al modo colapsado como expandido del sidebar
4. **Mantenimiento:** No depende de imágenes externas que pueden fallar al cargar

## Pruebas
- ✅ Compilación exitosa sin errores
- ✅ Visualización correcta en modo icono y expandido
- ✅ Obtención de datos desde el provider funcionando
- ✅ Fallback al valor por defecto funcionando

## Estado
✅ **COMPLETADO** - El cambio ha sido implementado y probado exitosamente.
