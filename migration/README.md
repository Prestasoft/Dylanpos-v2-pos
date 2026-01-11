# Migración Firebase → Supabase

## Estado Actual

✅ **Completado:**
- Esquema de base de datos (`schema.sql`)
- Configuración de Supabase (`supabase_config.dart`)
- Servicio de Supabase (`supabase_service.dart`)
- Servicio de autenticación (`supabase_auth_service.dart`)
- Repositorios CRUD para todas las entidades:
  - `customer_repository.dart`
  - `product_repository.dart`
  - `service_repository.dart`
  - `sale_repository.dart`
  - `reservation_repository.dart`
  - `expense_repository.dart`
- Script de migración de datos (`firebase_to_supabase_migration.dart`)

⏳ **Pendiente:**
1. Ejecutar `schema.sql` en Supabase Dashboard
2. Migrar datos de cada sucursal
3. Actualizar pantallas para usar los nuevos repositorios

## Paso 1: Crear las tablas en Supabase

1. Ir a: https://supabase.com/dashboard/project/mfduhbrwfjmkfgsqeygq
2. Click en **SQL Editor** en el menú lateral
3. Copiar el contenido de `schema.sql`
4. Click en **Run**

Esto creará:
- 11 tablas (branches, users, customers, categories, products, services, reservations, sales, sale_items, expenses, daily_summaries)
- Row Level Security (RLS) para multi-tenant
- Índices para rendimiento
- Triggers para updated_at automático

## Paso 2: Migrar datos desde Firebase

Para cada sucursal, ejecutar el script de migración:

```dart
import 'package:salespro_admin/services/supabase/migration/firebase_to_supabase_migration.dart';

// Migrar sucursal Santo Domingo Este
final result = await runMigration('sde');
print(result);

// Migrar sucursal Santiago
final result2 = await runMigration('stg');
print(result2);

// Migrar sucursal Santo Domingo
final result3 = await runMigration('sdo');
print(result3);

// Migrar sucursal La Romana
final result4 = await runMigration('rom');
print(result4);
```

## Paso 3: Actualizar la aplicación

### 3.1 Usar los nuevos repositorios

```dart
import 'package:salespro_admin/services/supabase/supabase.dart';

// Obtener clientes
final customers = await customerRepository.getAll();

// Crear venta
final sale = await saleRepository.createSale(
  sale: SaleModel(...),
  items: [SaleItemModel(...), ...],
);

// Obtener reservaciones del día
final reservations = await reservationRepository.getByDate(DateTime.now());
```

### 3.2 Autenticación con Supabase

```dart
// Login
final response = await supabaseAuth.signInWithEmail(
  email: 'usuario@email.com',
  password: 'contraseña',
);

// Obtener usuario actual
final user = supabaseAuth.currentUser;
final branchId = supabaseAuth.currentBranchId;

// Logout
await supabaseAuth.signOut();
```

## Estructura de archivos

```
lib/services/supabase/
├── supabase.dart                 # Barrel file (exporta todo)
├── supabase_service.dart         # Servicio principal
├── supabase_auth_service.dart    # Autenticación
├── repositories/
│   ├── base_repository.dart      # Clase base CRUD
│   ├── customer_repository.dart
│   ├── product_repository.dart
│   ├── service_repository.dart
│   ├── sale_repository.dart
│   ├── reservation_repository.dart
│   └── expense_repository.dart
└── migration/
    └── firebase_to_supabase_migration.dart
```

## Mapeo de IDs de sucursales

| Sucursal | ID Firebase | ID Supabase |
|----------|-------------|-------------|
| Santo Domingo Este | sistema-victor-sde | sde |
| Santiago | dylanpos-v2 | stg |
| Santo Domingo | dylanpos-victorfoto-stodgo | sdo |
| La Romana | sistema-victor-romana | rom |

## Credenciales Supabase

- **URL:** https://mfduhbrwfjmkfgsqeygq.supabase.co
- **Anon Key:** sb_publishable_Q0q1NFHO_68T4_x1l1fbAA_cubF320f

## Próximos pasos después de la migración

1. Probar cada funcionalidad con Supabase
2. Remover código de Firebase gradualmente
3. Eliminar dependencias de Firebase del pubspec.yaml:
   - firebase_core
   - firebase_auth
   - firebase_database
   - cloud_firestore
   - firebase_storage
   - firebase_messaging
   - firebase_app_check
