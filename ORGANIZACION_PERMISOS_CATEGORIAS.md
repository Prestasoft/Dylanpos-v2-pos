# Organización de Permisos por Categorías del Menú

## Resumen de la Nueva Estructura

Los permisos del sistema DylanPOS han sido reorganizados por categorías lógicas que corresponden a las secciones principales del menú de la aplicación. Esta organización mejora la experiencia del usuario al crear y gestionar roles.

**Total de categorías**: 12  
**Total de permisos**: 42

## 🎯 Categorías de Permisos

### 📊 NAVEGACIÓN PRINCIPAL
**Color**: Azul principal (`kMainColor`)
**Ícono**: `dashboard_rounded`

| Permiso | Descripción |
|---------|-------------|
| `dashboard` | Panel de Control administrativo |
| `inicio` | Botón de navegación a inicio |
| `tablero` | Vista de métricas y análisis |

---

### 🛎️ SERVICIOS Y PAQUETES
**Color**: Púrpura (`Colors.purple`)
**Ícono**: `room_service_rounded`

| Permiso | Descripción |
|---------|-------------|
| `services` | Gestión de servicios |
| `register_package` | Registrar paquetes |
| `register_clothing` | Registrar vestimentas |

---

### 📅 RESERVAS
**Color**: Azul (`Colors.blue`)
**Ícono**: `event_available_rounded`

| Permiso | Descripción |
|---------|-------------|
| `reservations` | Gestión general de reservas |
| `reservation_calendar` | Calendario de reservas |
| `rent_clothing` | Rentar vestimentas |
| `reserve_package` | Reservar paquetes |

---

### 💰 VENTAS
**Color**: Verde (`Colors.green`)
**Ícono**: `point_of_sale_rounded`

| Permiso | Descripción |
|---------|-------------|
| `sales` | Ventas generales |
| `pos_sales` | Ventas en punto de venta |
| `inventory_sales` | Ventas desde inventario |
| `sales_list` | Lista de ventas |
| `sales_return` | Devoluciones de venta |
| `quotation_list` | Lista de cotizaciones |

---

### 🛒 COMPRAS
**Color**: Naranja (`Colors.orange`)
**Ícono**: `shopping_cart_rounded`

| Permiso | Descripción |
|---------|-------------|
| `purchases` | Compras generales |
| `pos_purchase` | Compras en punto de venta |
| `purchase_list` | Lista de compras |
| `purchase_return` | Devoluciones de compra |

---

### 📦 INVENTARIO
**Color**: Verde azulado (`Colors.teal`)
**Ícono**: `inventory_rounded`

| Permiso | Descripción |
|---------|-------------|
| `products` | Gestión de productos |
| `categories` | Categorías de productos |
| `warehouses` | Gestión de almacenes |
| `inventory_list` | Lista de inventario |
| `inventory_equipment` | Inventario de equipos |

---

### 👥 CONTACTOS
**Color**: Índigo (`Colors.indigo`)
**Ícono**: `contacts_rounded`

| Permiso | Descripción |
|---------|-------------|
| `customers` | Gestión de clientes |
| `suppliers` | Gestión de proveedores |

---

### ✅ CONFIRMACIONES
**Color**: Celeste (`Colors.lightBlue`)
**Ícono**: `verified_rounded`

| Permiso | Descripción |
|---------|-------------|
| `confirmations` | Gestión de confirmaciones |

---

### 💳 FINANZAS
**Color**: Rojo (`Colors.red`)
**Ícono**: `account_balance_rounded`

| Permiso | Descripción |
|---------|-------------|
| `expense` | Gestión de gastos |
| `income` | Gestión de ingresos |
| `transaction` | Transacciones |
| `dues` | Cuentas por cobrar |
| `ledger` | Libro mayor |
| `loss_profit` | Pérdidas y ganancias |

---

### 📈 REPORTES
**Color**: Marrón (`Colors.brown`)
**Ícono**: `assessment_rounded`

| Permiso | Descripción |
|---------|-------------|
| `reports` | Generación de reportes |

---

### 👨‍💼 RECURSOS HUMANOS
**Color**: Rosa (`Colors.pink`)
**Ícono**: `people_alt_rounded`

| Permiso | Descripción |
|---------|-------------|
| `hrm` | Gestión de recursos humanos |
| `employees` | Gestión de empleados |
| `designations` | Puestos de trabajo |
| `salary_list` | Lista de salarios |

---

### ⚙️ CONFIGURACIÓN
**Color**: Gris (`Colors.grey`)
**Ícono**: `settings_rounded`

| Permiso | Descripción |
|---------|-------------|
| `user_roles` | Gestión de roles de usuario |
| `tax_rates` | Configuración de tasas de impuesto |

---

## 🎨 Características Visuales

### Separadores de Categoría
Cada categoría tiene un separador visual que incluye:
- **Barra lateral de color** específico de la categoría
- **Ícono representativo** de la funcionalidad
- **Nombre de la categoría** en mayúsculas
- **Línea degradada** que se extiende horizontalmente

### Permisos Destacados
Los permisos de "Navegación Principal" mantienen su destacado especial:
- **Fondo con gradiente** más pronunciado
- **Bordes resaltados**
- **Badges distintivos**: "PRINCIPAL" y "NAVEGACIÓN"

## 🔧 Implementación Técnica

### Funciones Clave

#### `getPermissionCategory(String type)`
Devuelve la categoría correspondiente a cada tipo de permiso.

#### `getCategoryColor(String category)`
Retorna el color específico asignado a cada categoría.

#### `_getCategoryIcon(String category)`
Proporciona el ícono representativo de cada categoría.

#### `shouldShowCategorySeparator(int index)`
Determina si debe mostrarse un separador de categoría basándose en el cambio de categoría entre elementos consecutivos.

### Estructura de Renderizado

```dart
ListView.builder(
  itemBuilder: (context, index) {
    // Detectar categoría y mostrar separador si es necesario
    if (shouldShowCategorySeparator(index)) {
      // Mostrar separador con ícono, color y nombre de categoría
    }
    
    // Renderizar permiso individual con estilos según categoría
    // ...
  }
)
```

## 💡 Beneficios de Esta Organización

### Para Administradores
- **Navegación intuitiva**: Encuentra permisos fácilmente por área funcional
- **Configuración eficiente**: Asigna permisos por módulos completos
- **Comprensión clara**: Relaciona permisos con funcionalidades del menú
- **Gestión de equipos**: Control específico sobre inventario de equipos
- **Confirmaciones centralizadas**: Manejo de todas las confirmaciones del sistema

### Para Usuarios Finales
- **Roles más coherentes**: Los permisos se agrupan lógicamente
- **Mejor experiencia**: Interfaz más organizada y profesional
- **Acceso controlado**: Solo ven las funcionalidades autorizadas

### Para Desarrolladores
- **Mantenibilidad**: Fácil agregar nuevos permisos a categorías existentes
- **Escalabilidad**: Estructura preparada para nuevas funcionalidades
- **Claridad**: Código más legible y organizado
- **Modularidad**: Cada categoría puede gestionarse independientemente

## 🔄 Actualizaciones de Roles Predefinidos

Todos los roles predefinidos han sido actualizados para incluir los permisos reorganizados, manteniendo la funcionalidad original pero con mejor organización visual.

Esta nueva estructura hace que la gestión de permisos sea más intuitiva y eficiente, alineándose con la estructura natural del menú de la aplicación.
