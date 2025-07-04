# Reordenamiento del Menú del Sidebar

## Descripción
Se realizó la reorganización del menú del sidebar para mover "Cuentas x Cobrar" debajo de "Confirmaciones" según el requerimiento del usuario.

## Cambios Realizados

### 1. Modificación en sidebar_item_model.dart
**Archivo:** `/lib/Route/sidebar_item_model.dart`

**Cambio realizado:**
- Se movió el elemento del menú "Cuentas x Cobrar" (`lang.S.current.dueList`) para que aparezca inmediatamente después de "Confirmaciones" en la lista del sidebar.

### 2. Nuevo orden del menú
**Orden anterior:**
1. Dashboard
2. Servicios
3. Reservas
4. Ventas
5. Confirmaciones
6. Compras
7. Categorías
8. Productos
9. Almacén
10. Proveedores
11. Clientes
12. **Cuentas x Cobrar** (estaba más abajo)
13. ...otros elementos

**Nuevo orden:**
1. Dashboard
2. Servicios
3. Reservas
4. Ventas
5. Confirmaciones
6. **Cuentas x Cobrar** ← **MOVIDO AQUÍ**
7. Compras
8. Categorías
9. Productos
10. Almacén
11. Proveedores
12. Clientes
13. ...otros elementos

### 3. Elemento movido
```dart
SidebarItemModel(
  name: lang.S.current.dueList, // "Cuentas x Cobrar"
  iconPath: 'images/dashboard_icon/due_list.svg',
  type: "dues",
  navigationPath: '/due-list',
),
```

## Impacto
- **Mejora en la experiencia del usuario:** Los elementos relacionados con confirmaciones y cuentas por cobrar ahora están agrupados lógicamente
- **Flujo de trabajo optimizado:** Los usuarios pueden acceder más fácilmente a las cuentas por cobrar después de revisar las confirmaciones
- **Organización lógica:** El menú sigue un flujo más natural del proceso de negocio

## Verificación
- ✅ Compilación exitosa sin errores
- ✅ El elemento "Cuentas x Cobrar" aparece después de "Confirmaciones"
- ✅ Funcionalidad del menú mantenida
- ✅ Navegación funcionando correctamente

## Estado
✅ **COMPLETADO** - El reordenamiento del menú ha sido implementado exitosamente.
