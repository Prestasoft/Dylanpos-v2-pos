# Sistema de Permisos para Header/TopBar

## Resumen de Implementación

Se ha implementado un sistema de control de acceso basado en roles para todos los botones del header de la aplicación.

## Botones Controlados por Permisos

### 1. Botón "Rentar" 
- **Ruta**: `/reservations/rent-clothes`
- **Permisos requeridos**: `rent_clothing`
- **Función de verificación**: `_canAccessRentClothing()`

### 2. Botón "Facturar"
- **Ruta**: `/sales/inventory-sales`
- **Permisos requeridos**: `sales` o `inventory_sales`
- **Función de verificación**: `_canAccessSales()`

### 3. Botón "Estado de Vestimentas"
- **Ruta**: `/service-package/dresses`
- **Permisos requeridos**: `services` o `register_clothing`
- **Función de verificación**: `_canAccessClothingStatus()`

### 4. Botón "Disponibilidad de Vestimentas"
- **Ruta**: `/calendario-reservas`
- **Permisos requeridos**: `reservation_calendar` o `reservations`
- **Función de verificación**: `_canAccessAvailabilityCalendar()`

### 5. Botón de Notificaciones
- **Funcionalidad**: Mostrar diálogo de notificaciones
- **Permisos requeridos**: `sales` o `reservations`
- **Función de verificación**: `_canAccessNotifications()`

### 6. Botón "Cuadrar Caja"
- **Funcionalidad**: Mostrar modal de cuadre de caja
- **Permisos requeridos**: `reports` o `transaction`
- **Función de verificación**: `_canAccessCashRegisterSquare()`

### 7. Menú de Perfil
- **Funcionalidad**: Acceder a actualización de perfil y configuraciones de usuario
- **Permisos requeridos**: `dashboard` (acceso básico al sistema)
- **Función de verificación**: `_canAccessProfile()`
- **Nota**: Este es un permiso base que también habilita:
  - Botón "Inicio" (navegación)
  - Botón "Tablero" (vista de métricas)
  - Acceso al Panel de Control (administración)

## Comportamiento del Sistema

### Para Usuarios Administradores (`isSubUser = false`)
- Tienen acceso completo a todos los botones
- No se aplican restricciones de permisos

### Para Sub-usuarios (`isSubUser = true`)
- Se verifican los permisos específicos para cada botón
- Si no tienen permiso, el botón se oculta (`SizedBox.shrink()`)
- Si intentan acceder sin permisos, se muestra mensaje de error

## Funciones de Verificación

Todas las funciones siguen el mismo patrón:

```dart
bool _canAccessFeature() {
  if (!isSubUser) return true; // Admin siempre tiene acceso
  return checkUserRoleViewPermissionV2(type: 'permission_type');
}
```

## Tipos de Permisos Utilizados

Los permisos se mapean a los siguientes tipos en el sistema de roles:

### Permisos de Navegación y Panel Principal
- `dashboard` - **Panel de Control**: Acceso al sistema administrativo principal
- `inicio` - **Inicio**: Navegación a página principal y botón de inicio
- `tablero` - **Tablero**: Vista de métricas, estadísticas y análisis

### Permisos de Funcionalidades Específicas
- `rent_clothing` - Rentar vestimentas
- `sales` - Ventas generales
- `inventory_sales` - Ventas de inventario
- `services` - Servicios
- `register_clothing` - Registrar vestimentas
- `reservation_calendar` - Calendario de reservas
- `reservations` - Reservas
- `reports` - Reportes
- `transaction` - Transacciones

## Beneficios de la Implementación

1. **Seguridad**: Solo usuarios autorizados pueden ver y acceder a funcionalidades específicas
2. **UI Limpia**: Los botones no autorizados se ocultan completamente
3. **Experiencia de Usuario**: Evita confusión al mostrar solo opciones disponibles
4. **Control Granular**: Cada botón puede tener diferentes combinaciones de permisos
5. **Mantenibilidad**: Fácil agregar nuevos botones con sus respectivos permisos

## Consideraciones de Diseño

- Los botones se ocultan completamente si no hay permisos (no se muestran disabled)
- Se mantiene la responsividad original del diseño
- Los usuarios administradores mantienen acceso completo
- Los mensajes de error son claros y específicos

## Mejoras en la UI de Permisos (Últimas actualizaciones)

### Destacado de Permisos Principales

#### 1. Permiso "Panel de Control" (Dashboard)
Se han implementado mejoras visuales significativas para hacer más visible este permiso fundamental en la pantalla de creación/edición de roles:

**Características del Destacado:**
- **Posición prioritaria**: Aparece primero en la lista de permisos
- **Estilo visual distintivo**: 
  - Fondo con gradiente en color principal de la aplicación
  - Borde resaltado en color principal
  - Icono específico (dashboard_rounded) en el lateral izquierdo
  - Badge "PRINCIPAL" para mayor énfasis visual
  - Texto en negrita y color principal
- **Separador visual**: Línea decorativa con el texto "Otros Permisos" que separa visualmente el Dashboard del resto de permisos

**Funcionalidad Controlada:**
- Acceso al panel principal de administración
- Navegación por el menú lateral principal
- Vista general de estadísticas y métricas del sistema

#### 2. Botón "Inicio" (Navegación)
**Funcionalidad**: Redirección a la página principal/dashboard
**Permisos requeridos**: `dashboard` (acceso básico)
**Ubicación**: Header/TopBar de navegación
**Comportamiento**: Permite volver rápidamente a la vista principal

#### 3. Botón "Tablero" (Dashboard View)
**Funcionalidad**: Acceso directo a vista de tablero con widgets
**Permisos requeridos**: `dashboard` (view/edit según funcionalidad)
**Ubicación**: Menú de navegación lateral o accesos rápidos
**Comportamiento**: Muestra métricas, gráficos y resúmenes ejecutivos

#### Justificación de la Separación:
- **Panel de Control**: Permiso base para acceso al sistema administrativo
- **Botón Inicio**: Funcionalidad de navegación básica
- **Botón Tablero**: Vista específica de métricas y análisis
- Cada uno puede tener diferentes niveles de acceso (view/edit)
- Permite control granular sobre qué usuarios ven qué información

Esta separación asegura que los administradores puedan configurar con precisión el nivel de acceso de cada usuario a las diferentes áreas del sistema.

## Próximos Pasos

Si necesitas agregar más botones al header:

1. Crear nueva función de verificación de permisos
2. Envolver el botón con la verificación condicional
3. Agregar el tipo de permiso correspondiente al sistema de roles
4. Documentar el nuevo botón en esta lista
