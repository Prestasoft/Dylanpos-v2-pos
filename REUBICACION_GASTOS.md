# Reubicación de "Gastos" en el Menú del Sidebar

## Descripción
Se realizó la reubicación del elemento "Gastos" (Expense) en el menú del sidebar para que aparezca inmediatamente después de "Informes" según el requerimiento del usuario.

## Cambios Realizados

### 1. Modificación en sidebar_item_model.dart
**Archivo:** `/lib/Route/sidebar_item_model.dart`

**Cambio realizado:**
- Se movió el elemento del menú "Gastos" (`lang.S.current.expense`) desde su posición original (entre "Pérdidas y Ganancias" e "Ingresos") para que aparezca inmediatamente después de "Informes" en la lista del sidebar.

### 2. Nuevo orden del menú
**Orden anterior:**
1. Dashboard
2. Servicios
3. Reservas
4. Ventas
5. Confirmaciones
6. Cuentas x Cobrar
7. Informes
8. Compras
9. Categorías
10. Productos
11. Almacén
12. Proveedores
13. Clientes
14. Libro Mayor
15. Pérdidas y Ganancias
16. **Gastos** (estaba aquí)
17. Ingresos
18. ...otros elementos

**Nuevo orden:**
1. Dashboard
2. Servicios
3. Reservas
4. Ventas
5. Confirmaciones
6. Cuentas x Cobrar
7. Informes
8. **Gastos** ← **MOVIDO AQUÍ**
9. Compras
10. Categorías
11. Productos
12. Almacén
13. Proveedores
14. Clientes
15. Libro Mayor
16. Pérdidas y Ganancias
17. Ingresos
18. ...otros elementos

### 3. Elemento movido
```dart
SidebarItemModel(
  name: lang.S.current.expense, // "Gastos"
  iconPath: 'images/dashboard_icon/expense.svg',
  type: "expense",
  navigationPath: '/expense',
),
```

## Impacto
- **Agrupación lógica mejorada:** Los elementos relacionados con análisis financiero (Informes → Gastos) están ahora agrupados secuencialmente
- **Flujo de trabajo optimizado:** Los usuarios pueden acceder fácilmente a los gastos después de revisar los informes
- **Navegación más intuitiva:** El menú sigue un flujo más natural del proceso de análisis financiero

## Secuencia lógica mejorada
**Nueva secuencia de análisis financiero:**
- Confirmaciones → Cuentas x Cobrar → Informes → Gastos

Esta secuencia permite a los usuarios:
1. Revisar las confirmaciones de ventas
2. Verificar las cuentas por cobrar
3. Consultar informes generales
4. Analizar los gastos específicos

## Verificación
- ✅ Compilación exitosa sin errores
- ✅ El elemento "Gastos" aparece después de "Informes"
- ✅ Funcionalidad del menú mantenida
- ✅ Navegación funcionando correctamente
- ✅ Elemento eliminado de su ubicación anterior

## Estado
✅ **COMPLETADO** - La reubicación de "Gastos" ha sido implementada exitosamente.
