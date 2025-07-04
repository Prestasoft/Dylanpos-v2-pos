# Guía de Restricción de Acceso a Botones del Header

## Botones Críticos del Header y Sus Permisos

### 🔒 **Botones Principales a Restringir**

| Botón | Permisos Requeridos | Descripción |
|-------|-------------------|-------------|
| **"Rentar"** | `rent_clothing` | Acceso al módulo de renta de vestimentas |
| **"Facturar"** | `sales` O `inventory_sales` | Acceso al módulo de facturación/ventas |
| **"Estado de Vestimentas"** | `services` O `register_clothing` | Ver estado de vestimentas registradas |
| **"Disponibilidad de Vestimentas"** | `reservation_calendar` O `reservations` | Calendario de disponibilidad |
| **"Cuadre de Caja"** | `reports` O `transaction` | Modal de cuadre de caja |

## 📋 **Roles Predefinidos Disponibles**

### 1. **"Solo Ventas Básicas"** 
- ✅ Dashboard, Clientes, Productos, Lista de Ventas, Reportes
- ❌ Rentar, Facturar, Estado/Disponibilidad de Vestimentas, Cuadre de Caja

### 2. **"Sin Rentar/Facturar"**
- ✅ Dashboard, Servicios, Clientes, Productos, Reportes
- ❌ **Rentar, Facturar, Disponibilidad de Vestimentas**

### 3. **"Sin Botones Header"** ⭐ **MÁXIMA RESTRICCIÓN**
- ✅ Solo Dashboard, Clientes, Productos, Listas
- ❌ **TODOS los botones del header (Rentar, Facturar, Estados, Disponibilidad, Cuadre)**

### 4. **"Recursos Humanos"**
- ✅ Dashboard/Inicio (acceso completo), Lista de Ventas, Calendario de Reservas
- ✅ Botón de Cuadre de Caja, Clientes (ver y editar)
- ✅ Compras, Inventario, Gastos e Ingresos (ver y editar)
- ✅ Transacciones, Gestión de Nómina completa (empleados, salarios, puestos)
- ❌ **Botones del header principales** (Rentar, Facturar, Estado/Disponibilidad Vestimentas)

### 5. **"Ver Todo"**
- ✅ Ver toda la información
- ❌ No puede editar ni eliminar, pero sí usar botones del header

## 🎯 **Configuración Manual de Permisos**

### Para Restringir Botón "Rentar":
- Desmarcar: `rent_clothing` (Rentar Vestimentas)

### Para Restringir Botón "Facturar":
- Desmarcar: `sales` (Ventas) Y `inventory_sales` (Ventas desde Inventario)

### Para Restringir Botón "Estado de Vestimentas":
- Desmarcar: `services` (Servicios) Y `register_clothing` (Registrar Vestimenta)

### Para Restringir Botón "Disponibilidad de Vestimentas":
- Desmarcar: `reservation_calendar` (Calendario de Reservas) Y `reservations` (Reservas)

### Para Restringir Botón "Cuadre de Caja":
- Desmarcar: `reports` (Reportes) Y `transaction` (Transacciones)

## ⚡ **Uso Rápido de Roles Predefinidos**

### Escenario 1: Empleado de Recursos Humanos
```
👆 Usar: "Recursos Humanos"
Resultado: Acceso completo a dashboard, nómina, ventas, clientes, gastos, ingresos y cuadre de caja
Sin acceso: Rentar, Facturar, Estado/Disponibilidad de Vestimentas
```

### Escenario 2: Empleado Sin Acceso a Funciones Críticas
```
👆 Usar: "Sin Botones Header"
Resultado: Acceso básico sin ningún botón del header
```

### Escenario 3: Vendedor Sin Rentar ni Disponibilidad
```
👆 Usar: "Sin Rentar/Facturar"
Resultado: Puede ver servicios pero no rentar, facturar o ver disponibilidad
```

## 🔐 **Comportamiento del Sistema**

### Para Administradores (`isSubUser = false`):
- ✅ Siempre tienen acceso completo a todos los botones
- ✅ No se aplican restricciones

### Para Sub-usuarios (`isSubUser = true`):
- ✅ Solo ven botones para los que tienen permisos
- ❌ Botones sin permisos se ocultan completamente
- ⚠️ Si intentan acceder directamente, reciben mensaje de error

## 📝 **Pasos para Configurar un Usuario Restringido**

1. **Crear nuevo usuario** o **editar existente**
2. **Seleccionar rol predefinido** apropiado:
   - Para máxima seguridad: **"Sin Botones Header"**
   - Para consulta únicamente: **"Solo Consultas"**
   - Para restricción específica: **"Sin Rentar/Facturar"**
3. **Ajustar manualmente** si necesitas permisos específicos
4. **Guardar** y el usuario solo verá botones autorizados

### Roles Específicos por Área

#### **Para Recursos Humanos:**
- **Usar**: "Recursos Humanos"
- **Acceso completo a**: 
  - Dashboard/Inicio (ver y editar)
  - Lista de Ventas y Calendario de Reservas
  - Botón de Cuadre de Caja
  - Clientes (ver y editar)
  - Compras e Inventario
  - Gastos e Ingresos (gestión completa)
  - Gestión de Nómina (empleados, salarios, puestos)
- **Sin acceso a**: Rentar, Facturar, Estado/Disponibilidad de Vestimentas

#### **Permisos Específicos del Rol "Recursos Humanos":**
| Módulo | Permiso | Ver | Editar |
|--------|---------|-----|--------|
| **Dashboard/Inicio** | `dashboard` | ✅ | ✅ |
| **Lista de Ventas** | `sales_list` | ✅ | ❌ |
| **Calendario de Reservas** | `reservation_calendar` | ✅ | ❌ |
| **Cuadre de Caja** | `reports` + `transaction` | ✅ | ❌ |
| **Clientes** | `customers` | ✅ | ✅ |
| **Compras** | `purchases` + `purchase_list` | ✅ | ❌ |
| **Inventario** | `inventory_list` + `products` | ✅ | ❌ |
| **Gastos** | `expense` | ✅ | ✅ |
| **Ingresos** | `income` | ✅ | ✅ |
| **Transacciones** | `transaction` | ✅ | ❌ |
| **Gestión de Nómina** | `hrm` | ✅ | ✅ |
| **Empleados** | `employees` | ✅ | ✅ |
| **Lista de Salarios** | `salary_list` | ✅ | ✅ |
| **Puestos** | `designations` | ✅ | ✅ |

## ⚠️ **Consideraciones Importantes**

- Los botones se **ocultan completamente** (no aparecen deshabilitados)
- El **diseño se mantiene responsive** sin botones no autorizados
- Los **administradores** siempre mantienen acceso completo
- Los cambios de permisos son **inmediatos** (requiere recarga de la aplicación)

## 🎨 **Interfaz Visual**

- **Botones disponibles**: Se muestran normalmente
- **Botones restringidos**: No aparecen en el header
- **Indicadores visuales**: Los tooltips en los roles predefinidos indican qué se restringe
