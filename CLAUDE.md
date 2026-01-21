# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Dylanpos v2** (package name: `salespro_admin`) is a comprehensive Flutter web application for a dress rental and photography reservation system (Sistema de reservas y renta de vestidos para fotografías). It's built as a Point of Sale (POS) system with advanced inventory management, customer management, and business analytics.

## Technology Stack

- **Framework**: Flutter (Web-only application, no mobile support configured)
- **Backend**: Firebase (Firestore, Auth, Realtime Database, Storage, Messaging)
- **State Management**: Hybrid approach - Riverpod for new features, Provider for legacy code
- **Navigation**: GoRouter with shell routes and nested routing
- **UI Framework**: Material Design with responsive breakpoints using responsive_framework
- **Internationalization**: Flutter Intl (50+ languages with RTL support)
- **PDF Generation**: Syncfusion PDF libraries for invoices and reports
- **Payment Processing**: PayPal integration with secure token handling

## Development Commands

### Essential Commands
```bash
# Install dependencies
flutter pub get

# Run the app (web only - application is web-focused)
flutter run -d chrome --web-renderer html

# Build for web production
flutter build web --web-renderer html

# Analyze code quality and linting
flutter analyze

# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Generate localization files from .arb files
flutter gen-l10n

# Clean build artifacts
flutter clean

# Format all Dart code
dart format .
```

### Code Quality & Analysis
```bash
# Primary linting (uses flutter_lints package)
flutter analyze

# Code formatting
dart format .

# Check for unused dependencies
flutter pub deps
```

## Project Architecture

### Directory Structure

**Core Business Logic**:
- `lib/Provider/` - Business logic providers (hybrid Provider/Riverpod pattern)
- `lib/Repository/` - Data access layer implementing Repository pattern
- `lib/model/` - Data models, DTOs, and Firebase document models
- `lib/services/` - Service layer implementations (audit, payments, etc.)

**UI Layer**:
- `lib/Screen/` - Feature-based screens organized by business domains
- `lib/Route/` - GoRouter configuration with shell routes and nested navigation
- `lib/Screen/Widgets/` - Reusable UI components and shared widgets

**Key Feature Modules**:
- `Authentication/` - Login, signup, profile management with Firebase Auth
- `Reservation/` - Calendar-based dress reservation system with package management
- `Inventory Sales/` - Point of sale system with payment processing
- `Due List/` - Accounts receivable and invoice management with PDF generation
- `Reports/` - Business analytics, daily transactions, and financial reports
- `HRM/` - Human resources (employees, designations, salaries)
- `Product/` - Inventory management with barcode generation
- `Customer List/` - Customer relationship management

### Navigation Architecture

Uses GoRouter with a **shell route pattern**:
- `ShellRouteWrapper` provides consistent layout (sidebar, topbar)
- Nested routes for feature modules (e.g., `/sales/pos-sales`, `/purchase/pos-purchase`)
- Route parameters and state passing via `extra` parameter
- Authentication guard implemented at router level

### Firebase Integration

Multi-service Firebase setup:
- **Firestore**: Primary NoSQL database for business data
- **Realtime Database**: Real-time data sync and FCM token storage
- **Authentication**: User management with role-based permissions
- **Storage**: Image and document storage (dress photos, invoices)
- **Messaging**: Push notifications with web push support
- **App Check**: Security for production environment

**Configuration**: Web-only deployment with separate environments (Santiago/Santo Domingo)

### State Management Pattern

**Hybrid Architecture**:
- **Riverpod**: ProviderScope at app root, used for new features
- **Provider**: Legacy ChangeNotifier providers for existing features
- **Data Flow**: Repository → Provider → UI with reactive updates
- **Language/Currency**: Global providers for internationalization

### Responsive Design Framework

- **Breakpoints**: XS, SM (576px), MD (1240px), LG (infinity)
- **responsive_framework**: Adaptive layouts across screen sizes
- **responsive_grid**: Custom grid system with defined breakpoints
- **Tablet-specific**: Dedicated tablet screens for key workflows

## Key Features

1. **Dress Reservation System**: Calendar-based booking with package management
2. **Point of Sale**: Complete POS system with payment processing
3. **Inventory Management**: Stock tracking and product management
4. **Customer Management**: CRM with customer profiles and history
5. **Financial Management**: Income/expense tracking, profit/loss reports
6. **User Roles**: Multi-level permission system
7. **Multilingual Support**: 50+ languages with RTL support
8. **PDF Generation**: Invoices, reports, and receipts

## Development Notes

### Testing Structure
- **Widget Tests**: Basic Flutter widget tests in `test/`
- **Specialized Tests**: `test/widget_test_reservation_calendar.dart` for calendar functionality
- **Business Logic Validation**: Extensive validation scripts in `lib/Screen/Inventory Sales/` for payment method verification
- **Command**: Use `flutter test` for all tests, `flutter test test/specific_file.dart` for individual tests

### Business Logic Validation Scripts
The codebase includes comprehensive validation scripts (primarily in `lib/Screen/Inventory Sales/`):
- Payment method validation scripts (.dart and .sh files)
- Invoice verification and PDF generation testing
- Database cleanup utilities
- Method payment analysis and debugging tools

### Code Quality Standards
- **Linting**: Uses `flutter_lints` package for code quality enforcement
- **Formatting**: Standard Dart formatting with `dart format`
- **Architecture**: Repository pattern with Provider/Riverpod state management
- **Documentation**: Extensive markdown documentation files for complex features

### Firebase Environment Configuration
- **Multi-environment setup**: Santiago (active) and Santo Domingo configurations
- **Security**: Firebase App Check implemented for production
- **Realtime Database**: Used for FCM tokens and real-time synchronization
- **Database Rules**: Security rules defined in `database.rules.json`
- **Web Push**: FCM web push notifications with VAPID keys

### Critical Business Logic Areas
- **Payment Processing**: Complex validation in `lib/Screen/Inventory Sales/` with multiple verification layers
- **PDF Generation**: Invoice and report generation using Syncfusion in `lib/PDF/`
- **Reservation System**: Calendar-based booking logic in `lib/Screen/Reservation/`
- **Financial Reporting**: Daily transactions and profit/loss calculations in `lib/Screen/Reports/`
- **User Permissions**: Role-based access control throughout the application

## Common Development Patterns

### Adding New Features
1. **New Screens**: Create in appropriate `lib/Screen/[Feature]/` directory following existing patterns
2. **State Management**: Use Riverpod for new features, maintain Provider for existing code
3. **Routing**: Add routes to `lib/Route/app_routes.dart` within the ShellRoute structure
4. **Models**: Define data models in `lib/model/` with Firebase serialization
5. **Repository Layer**: Implement data access in `lib/Repository/` following Repository pattern

### Working with Firebase
- **Document References**: Use collection/document paths consistently
- **Real-time Updates**: Leverage Firestore streams for live data
- **Error Handling**: Implement proper Firebase exception handling
- **Security**: Follow role-based access patterns established in existing screens

### Internationalization Workflow
- **Add Strings**: Edit appropriate `lib/l10n/intl_[locale].arb` files
- **Generate**: Run `flutter gen-l10n` to regenerate localization files
- **Usage**: Import `generated/l10n.dart` and use `S.of(context).stringKey`

### PDF and Document Generation
- **Invoices**: Use patterns from `lib/PDF/` directory with Syncfusion libraries
- **Reports**: Follow existing report generation patterns for consistency
- **Styling**: Maintain consistent branding and formatting

### Payment Processing Integration
- **PayPal**: Use established PayPal integration patterns
- **Validation**: Implement thorough validation following patterns in `lib/Screen/Inventory Sales/`
- **Security**: Never log or expose payment credentials

## ⚠️ DESPLIEGUE A PRODUCCIÓN - OBLIGATORIO USAR deploy.sh

**CRÍTICO**: Para desplegar a producción, SIEMPRE usar el script `deploy.sh`. NUNCA hacer deployment manual con `flutter build web` + `scp/rsync`.

### Comando de despliegue:
```bash
# SIEMPRE usar este comando para desplegar:
./deploy.sh

# O con input automático (para Claude):
echo -e "s\nDescripción del cambio" | ./deploy.sh
```

### ¿Por qué usar deploy.sh?
El script `deploy.sh` hace automáticamente:
1. **Auto-incrementa la versión** (ej: 2.1.7 → 2.1.8)
2. **Actualiza la versión en todos los archivos**:
   - `pubspec.yaml`
   - `web/index.html` (REQUIRED_VERSION, título, version-text)
   - `lib/top_bar/top_bar.dart` (badge de versión)
   - `lib/Screen/Authentication/log_in.dart` (badge de versión)
   - `web/app-version.json` (archivo de versión para actualización automática)
3. **Compila** `flutter build web --release`
4. **Sube archivos** via rsync al servidor
5. **Verifica** la versión en el servidor

### ⛔ NO HACER NUNCA:
```bash
# ❌ INCORRECTO - No actualiza versión:
flutter build web --release
scp -r build/web/* root@servidor:/var/www/victorpos-app/

# ❌ INCORRECTO - No actualiza versión:
rsync -avz build/web/ root@servidor:/var/www/victorpos-app/
```

### Configuración del servidor:
- **IP**: 72.62.163.74
- **Usuario**: root
- **Ruta**: /var/www/victorpos-app
- **URL**: https://sistema.victorguzmanfotografia.com

---

## Security Considerations

- **Firebase Rules**: Database security rules are critical - test changes thoroughly
- **User Roles**: Implement role-based UI and data access controls
- **Payment Security**: PayPal credentials stored in Firebase, never in code
- **Data Validation**: Server-side validation required for all business-critical operations
- **Access Control**: UI elements hidden/shown based on user permissions throughout app

---

## 🔧 Soluciones a Problemas Conocidos

### Warehouse Dropdown No Se Actualizaba Al Cambiar de Sucursal (Enero 2026)

**PROBLEMA**: En las pantallas de Ventas (Inventory Sales), el dropdown de almacén (warehouse) no se actualizaba automáticamente cuando el usuario cambiaba de sucursal. Por ejemplo, al cambiar de Santiago a La Romana, el dropdown seguía mostrando "Victor Guzmán Santo Domingo Este" en lugar del almacén correcto de La Romana.

**CAUSA RAÍZ**:
El método `getWare()` en `inventory_sales.dart` e `inventory_sale2s.dart` tenía una lógica que solo seleccionaba el warehouse cuando `selectedWareHouse == null`. Sin embargo, cuando el usuario cambiaba de sucursal, esta variable nunca se reseteaba, por lo que el warehouse quedaba "congelado" con el valor de la primera sucursal.

**Flujo problemático**:
1. Usuario entra a Ventas en sucursal Santiago → `selectedWareHouse = "Santiago"` ✅
2. Usuario cambia a sucursal La Romana → `html.window.localStorage['selected_tenant_id']` cambia a `'rom'` ✅
3. Usuario regresa a Ventas → `getWare()` se ejecuta pero encuentra `selectedWareHouse != null`, entonces NO recalcula ❌
4. Resultado: Dropdown muestra "Santiago" aunque la sucursal actual es "La Romana" ❌

**SOLUCIÓN APLICADA (v2.1.102)**:

Implementar **tracking de cambios de sucursal** para detectar cuando el `selected_tenant_id` cambia y forzar recálculo del warehouse.

#### Cambios en `lib/Screen/Inventory Sales/inventory_sales.dart`

**1. Agregar variable de tracking** (líneas 131-133):
```dart
WareHouseModel? selectedWareHouse;
String? _lastKnownBranchId; // Para detectar cambios de sucursal
int i = 0;
```

**2. Detectar cambio de sucursal en `getWare()`** (líneas 1846-1852):
```dart
DropdownButton<WareHouseModel> getWare({required List<WareHouseModel> list}) {
  List<DropdownMenuItem<WareHouseModel>> dropDownItems = [];

  // Obtener sucursal actual de localStorage
  final currentBranchId = html.window.localStorage['selected_tenant_id'] ?? '';

  // CRÍTICO: Si la sucursal cambió, resetear el warehouse seleccionado
  // Esto permite que el dropdown se actualice automáticamente al cambiar de sucursal
  if (_lastKnownBranchId != null && _lastKnownBranchId != currentBranchId) {
    selectedWareHouse = null;
    debugPrint('🔄 Sucursal cambió de $_lastKnownBranchId a $currentBranchId - Reseteando warehouse');
  }
  _lastKnownBranchId = currentBranchId;

  // ... resto del código que selecciona warehouse basado en branch
}
```

**3. Agregar debug logs** (líneas 1886-1896):
```dart
if (matches) {
  selectedWareHouse = element;
  debugPrint('✅ Warehouse seleccionado: ${element.warehouseName} para sucursal $currentBranchId');
}

// Si no se encontró ninguno basado en la sucursal, seleccionar el primer warehouse disponible
if (selectedWareHouse == null && list.isNotEmpty) {
  selectedWareHouse = list.first;
  debugPrint('⚠️ No se encontró warehouse específico - usando primero de la lista: ${list.first.warehouseName}');
}
```

#### Cambios en `lib/Screen/Inventory Sales/inventory_sale2s.dart`

**Mismos cambios aplicados**:
- Líneas 1016-1018: Agregar `String? _lastKnownBranchId;`
- Líneas 1029-1035: Detectar cambio de sucursal y resetear warehouse
- Líneas 1070-1075: Debug logs para tracking

**ARCHIVOS MODIFICADOS**:
- ✅ `lib/Screen/Inventory Sales/inventory_sales.dart` - Líneas 132, 1846-1852, 1886-1896
- ✅ `lib/Screen/Inventory Sales/inventory_sale2s.dart` - Líneas 1017, 1029-1035, 1070-1075

**CÓMO VERIFICAR**:
1. Login en sucursal Santiago (stg)
2. Ir a Ventas → Verificar que dropdown muestra "Victor Guzmán Santiago"
3. Cambiar sucursal a La Romana (rom) desde el selector de sucursales
4. Regresar a Ventas → Dropdown ahora debe mostrar "ROMANA" o warehouse correspondiente a La Romana
5. En los logs de debug (Flutter DevTools), deberías ver:
   ```
   🔄 Sucursal cambió de stg a rom - Reseteando warehouse
   ✅ Warehouse seleccionado: ROMANA para sucursal rom
   ```

**FLUJO CORRECTO DESPUÉS DEL FIX**:
1. Usuario entra a Ventas en Santiago → `selectedWareHouse = "Santiago"`, `_lastKnownBranchId = "stg"` ✅
2. Usuario cambia a La Romana → `localStorage['selected_tenant_id'] = 'rom'` ✅
3. Usuario regresa a Ventas → `getWare()` detecta `_lastKnownBranchId ('stg') != currentBranchId ('rom')` ✅
4. Se ejecuta `selectedWareHouse = null` para forzar recálculo ✅
5. Warehouse se recalcula con la nueva sucursal → Dropdown muestra "ROMANA" ✅

**LECCIONES APRENDIDAS**:
- Las variables de estado en StatefulWidget pueden persistir entre cambios de contexto (como cambio de sucursal)
- Cuando un valor debe ser reactivo a cambios externos (como `localStorage`), hay que implementar tracking explícito
- El patrón `if (variable == null) { calcular... }` solo funciona si la variable se resetea cuando las condiciones cambian
- Los debug logs con emojis (`🔄`, `✅`, `⚠️`) son esenciales para diagnosticar problemas de estado reactivo
- El `html.window.localStorage` es la fuente de verdad para el `selected_tenant_id` en aplicaciones multi-sucursal

---

### Datos Faltantes en Santiago Impiden Generación de PDF y Pagos (Enero 2026)

**PROBLEMA**: Al aplicar un pago en "Cuentas por Cobrar" en la sucursal de Santiago (stg), el sistema no generaba el PDF del recibo ni aplicaba el pago correctamente, mientras que en otras sucursales (SDE, SDO, ROM) funcionaba perfectamente.

**SÍNTOMAS**:
- El usuario aplica un pago → No se genera PDF
- El pago no se registra correctamente
- Otras sucursales funcionan sin problemas

**CAUSA RAÍZ**:
La tabla `general_settings` en el esquema de Santiago (`stg`) estaba **completamente vacía** (0 registros), mientras que las otras sucursales sí tenían un registro. Esta tabla es crítica porque:
1. El método `generateDueDocument()` en `lib/PDF/due_invoice_pdf.dart` necesita datos de `BranchSettingsModel`
2. `BranchSettingsModel` depende de datos en `general_settings` para configurar el encabezado del PDF
3. Sin este registro, la generación del PDF falla silenciosamente

**DIAGNÓSTICO**:

```sql
-- Estado ANTES del fix:
SELECT 'stg' as schema, COUNT(*) as rows FROM stg.general_settings
UNION ALL
SELECT 'sde', COUNT(*) FROM sde.general_settings
UNION ALL
SELECT 'sdo', COUNT(*) FROM sdo.general_settings
UNION ALL
SELECT 'rom', COUNT(*) FROM rom.general_settings;

-- Resultado:
-- rom | 1
-- sde | 1
-- sdo | 1
-- stg | 0  ← PROBLEMA: Santiago sin datos
```

**SOLUCIÓN APLICADA**:

1. **Insertar registro faltante en `stg.general_settings`**:
```sql
INSERT INTO stg.general_settings (id, title, company_name, main_logo, common_header_logo, sidebar_logo, data, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'DylanPOS',
  '',
  '',
  '',
  '',
  '{}',  -- JSON vacío válido
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
);
```

2. **Verificar consistencia después del fix**:
```sql
-- Estado DESPUÉS del fix:
-- stg | 1  ✅ Ahora Santiago tiene el registro requerido
-- sde | 1  ✅
-- sdo | 1  ✅
-- rom | 1  ✅
```

**ARCHIVOS/TABLAS AFECTADOS**:
- ✅ `stg.general_settings` - Agregado registro faltante
- ✅ PostgreSQL: Todas las sucursales ahora consistentes

**SCRIPT DE VERIFICACIÓN**:

Para verificar la consistencia de datos críticos entre todas las sucursales, usar este script:

```sql
-- Verificar general_settings (crítico para PDF)
SELECT
  'stg' as schema, COUNT(*) as rows FROM stg.general_settings
UNION ALL
SELECT 'sde', COUNT(*) FROM sde.general_settings
UNION ALL
SELECT 'sdo', COUNT(*) FROM sdo.general_settings
UNION ALL
SELECT 'rom', COUNT(*) FROM rom.general_settings
ORDER BY schema;

-- TODAS las sucursales deben tener al menos 1 registro
```

**CÓMO VERIFICAR EL FIX**:
1. Login en sucursal Santiago (stg)
2. Ir a **Due List (Cuentas x Cobrar)**
3. Seleccionar una factura con balance pendiente (hay 24 disponibles según diagnóstico)
4. Click en botón de pago
5. Ingresar monto de pago
6. Click en **Submit**
7. Verificar que:
   - ✅ Se muestra diálogo de WhatsApp
   - ✅ El PDF se genera correctamente con formato profesional
   - ✅ El PDF se abre/descarga automáticamente
   - ✅ El pago se registra en la tabla `stg.due_transactions`
   - ✅ El balance del cliente se actualiza en `stg.customers`

**VERIFICACIÓN EN BASE DE DATOS**:
```sql
-- Ver pagos recientes en Santiago
SELECT
  customer_name,
  invoice_number,
  paid_amount,
  seller_name,
  created_at
FROM stg.due_transactions
ORDER BY created_at DESC
LIMIT 5;

-- Ver ventas con balance pendiente en Santiago
SELECT
  invoice_number,
  customer_name,
  total,
  due_amount,
  paid_amount
FROM stg.sales
WHERE due_amount > 0
ORDER BY created_at DESC
LIMIT 5;
```

**LECCIONES APRENDIDAS**:
- Los esquemas multi-sucursal deben mantener consistencia en tablas críticas
- La tabla `general_settings` es OBLIGATORIA para generación de PDFs
- Siempre verificar que TODAS las sucursales tengan los datos mínimos requeridos
- Los errores silenciosos (sin mensaje de error visible) suelen ser por datos faltantes en BD
- Crear scripts de verificación de consistencia para detectar problemas temprano
- Cuando una funcionalidad falla solo en una sucursal, primero verificar consistencia de datos entre esquemas

**PREVENCIÓN FUTURA**:
- Ejecutar script de verificación de consistencia antes de cada despliegue
- Agregar constraints o triggers para garantizar que `general_settings` nunca esté vacío
- Implementar validación al iniciar la app que verifique datos críticos existen
- Agregar logs más detallados cuando falla la generación de PDF

---

### Duplicados en Reporte de Daily Transactions (Enero 2026)

**PROBLEMA**: El reporte de transacciones diarias mostraba duplicados cuando una factura tenía múltiples items (ej: reserva + producto). Cada transacción aparecía 2 veces con datos diferentes.

**CAUSA RAÍZ**:
1. **Frontend** (`lib/Screen/Reports/daily_transaction.dart`): El código de deduplicación usaba `UUID` del campo `id` en lugar de `invoiceNumber` para detectar duplicados
2. **Backend** (`/var/www/victorpos-api/src/routes/daily-transactions.js`): No extraía el `invoiceNumber` de los modelos anidados en el campo JSONB `data`, siempre retornaba `null`

**SOLUCIÓN APLICADA**:

#### Frontend - `lib/Screen/Reports/daily_transaction.dart` (Líneas 538-545)
```dart
// ❌ CÓDIGO ANTERIOR (INCORRECTO):
Set<String> existingInvoiceNumbers = reTransaction
    .where((t) => t.type == 'Sale' || t.type == 'Adicionales' || ...)
    .map((t) => t.id)  // Usaba UUID en lugar de invoice number
    .toSet();

// ✅ CÓDIGO CORREGIDO:
Set<String> existingInvoiceNumbers = {};
for (var t in reTransaction.where((t) => t.type == 'Sale' || t.type == 'Adicionales' || t.type == 'Impresiones' || t.type == 'Reserva')) {
  // Extrae invoice number de campos directos o modelos anidados
  final invoice = t.invoiceNumber ?? t.saleTransactionModel?.invoiceNumber ?? t.id;
  debugPrint('🔍 Extrayendo factura - Type: ${t.type}, invoiceNumber: ${t.invoiceNumber}, saleModel.invoice: ${t.saleTransactionModel?.invoiceNumber}, usando: $invoice');
  if (invoice.isNotEmpty) {
    existingInvoiceNumbers.add(invoice);
  }
}
```

#### Backend - `/var/www/victorpos-api/src/routes/daily-transactions.js` (Líneas 75-84)
```javascript
// ❌ CÓDIGO ANTERIOR (INCORRECTO):
const invoiceNumber = jsonData.invoiceNumber || jsonData.invoice_number || null;
// Solo buscaba en el nivel superior del JSON

// ✅ CÓDIGO CORREGIDO:
let invoiceNumber = jsonData.invoiceNumber || jsonData.invoice_number || null;
if (!invoiceNumber && row.type === 'Sale' && jsonData.saleTransactionModel) {
  invoiceNumber = jsonData.saleTransactionModel.invoiceNumber || jsonData.saleTransactionModel.invoice_number || null;
} else if (!invoiceNumber && row.type === 'Purchase' && jsonData.purchaseTransactionModel) {
  invoiceNumber = jsonData.purchaseTransactionModel.invoiceNumber || jsonData.purchaseTransactionModel.invoice_number || null;
} else if (!invoiceNumber && (row.type === 'Reserva' || row.type === 'Adicionales' || row.type === 'Impresiones') && jsonData.saleTransactionModel) {
  invoiceNumber = jsonData.saleTransactionModel.invoiceNumber || jsonData.saleTransactionModel.invoice_number || null;
}
```

**ARCHIVOS MODIFICADOS**:
1. **Frontend**: `lib/Screen/Reports/daily_transaction.dart` - Líneas 538-545
2. **Backend**: `/var/www/victorpos-api/src/routes/daily-transactions.js` - GET endpoint, líneas 75-84

**CÓMO VERIFICAR**:
1. Ejecutar `flutter run -d chrome`
2. Login y navegar a Reports → Daily Transactions
3. Cambiar sucursal a Santiago (stg) para ver datos de prueba
4. Verificar que cada factura aparece solo UNA vez (no duplicada)
5. En los logs de debug, deberías ver:
   ```
   🔍 Extrayendo factura - Type: Sale, invoiceNumber: 3, saleModel.invoice: 3, usando: 3
   🔄 Facturas ya existentes en Daily: {3, 2, 5, ...}
   ```
   (Números de factura en lugar de UUIDs)

**REINICIAR BACKEND DESPUÉS DE CAMBIOS**:
```bash
# Si se modifica el backend en /var/www/victorpos-api:
ssh root@72.62.163.74 "pm2 restart victorpos-api"
```

**LECCIONES APRENDIDAS**:
- Siempre verificar la estructura real del JSON en la base de datos antes de asumir qué campos están disponibles
- Los datos en PostgreSQL JSONB pueden estar anidados en modelos complejos
- La deduplicación de transacciones DEBE usar `invoiceNumber`, NUNCA el `UUID/id`
- Cuando hay dos fuentes de datos (daily_transactions + sales), la deduplicación es crítica
- Los debug logs son esenciales para diagnosticar problemas de datos anidados

---

### Campo sellerName Faltante en PDF de Photo Invoice (Enero 2026)

**PROBLEMA**: Las facturas PDF de Photo Invoice (impresiones y enmarcado) no mostraban el nombre del usuario/vendedor que realizó la venta, a diferencia de las facturas normales que sí lo muestran.

**CAUSA RAÍZ**:
1. **Modelo de datos**: `PhotoInvoiceModel` NO tenía el campo `sellerName` definido
2. **PDF**: El template `photo_invoice_pdf.dart` no incluía el campo de vendedor
3. **Creación de facturas**: Al crear el `PhotoInvoiceModel` en `photo_invoice_screen_v2.dart`, no se pasaba el nombre del usuario

**SOLUCIÓN APLICADA**:

#### 1. Modelo - `lib/model/photo_invoice_model.dart`
```dart
// Agregar campo sellerName a la clase:
class PhotoInvoiceModel {
  // ... otros campos
  String? sellerName;  // Usuario que realizó la venta/factura

  PhotoInvoiceModel({
    // ... otros parámetros
    this.sellerName,
  });

  // En toJson():
  if (sellerName != null && sellerName!.isNotEmpty) {
    json['sellerName'] = sellerName;
  }

  // En fromJson():
  sellerName: json['sellerName'] ?? json['seller_name'],  // Soporte camelCase y snake_case
}
```

#### 2. PDF Template - `lib/PDF/photo_invoice_pdf.dart` (Después de línea 359)
```dart
///______Seller_Name____________________________________________
if (invoice.sellerName != null && invoice.sellerName!.isNotEmpty) ...[
  pw.Row(children: [
    pw.SizedBox(
      width: 50.0,
      child: pw.Text(
        'Vendedor',
        style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
      ),
    ),
    pw.SizedBox(
      width: 10.0,
      child: pw.Text(
        ':',
        style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
      ),
    ),
    pw.SizedBox(
      width: 125.0,
      child: pw.Text(
        invoice.sellerName!,
        style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
      ),
    ),
  ]),
],
```

#### 3. Creación de Factura - `lib/Screen/Photo Invoice/photo_invoice_screen_v2.dart`

**Agregar import** (línea 35):
```dart
import 'package:salespro_admin/const.dart';
```

**Al crear PhotoInvoiceModel** (línea 1384):
```dart
invoice = PhotoInvoiceModel(
  // ... otros campos
  sellerName: isSubUser ? constSubUserTitle : 'Admin',  // Usuario que realizó la venta
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
```

**ARCHIVOS MODIFICADOS**:
1. `lib/model/photo_invoice_model.dart` - Agregar campo sellerName (declaración, constructor, toJson, fromJson)
2. `lib/PDF/photo_invoice_pdf.dart` - Mostrar vendedor en el PDF (líneas 360-385 aprox)
3. `lib/Screen/Photo Invoice/photo_invoice_screen_v2.dart` - Pasar sellerName al crear factura (import const.dart, línea 1384)

**CÓMO VERIFICAR**:
1. Ejecutar `flutter run -d chrome`
2. Login con un usuario específico
3. Crear una factura de Photo Invoice (impresiones/enmarcado)
4. Generar y descargar el PDF
5. Verificar que el campo "Vendedor" aparece en la sección derecha del PDF con el nombre del usuario correcto

**PATRÓN GENERAL PARA OBTENER USUARIO ACTUAL**:
```dart
// Importar const.dart:
import 'package:salespro_admin/const.dart';

// Obtener nombre del usuario:
final userName = isSubUser ? constSubUserTitle : 'Admin';

// Variables globales definidas en lib/const.dart (líneas 125-127):
// - bool isSubUser
// - String constSubUserTitle
// - String constUserId
```

**LECCIONES APRENDIDAS**:
- Siempre comparar modelos similares (SaleTransactionModel vs PhotoInvoiceModel) para detectar campos faltantes
- El PDF de ventas normales (`sales_invoice_pdf.dart`) sirve como referencia para otros PDFs
- Las variables globales de usuario están en `lib/const.dart` (isSubUser, constSubUserTitle)
- Mantener consistencia entre todos los PDFs (facturas, impresiones, compras)
- Siempre incluir `sellerName` en cualquier transacción o factura para auditoría

---

### Formato Profesional del PDF de Recibos de Pago (Enero 2026)

**PROBLEMA**: El PDF de recibos de pago de "Cuentas x Cobrar" (`due_invoice_pdf.dart`) tenía un formato básico muy diferente al PDF de facturas de ventas (`sales_invoice_pdf.dart`), sin diseño profesional, sin elementos visuales consistentes, y sin el estilo gubernamental/DGII.

**CAUSA RAÍZ**:
El archivo `due_invoice_pdf.dart` (869 líneas) era menos de la mitad del tamaño de `sales_invoice_pdf.dart` (1776 líneas) y le faltaban:
1. Encabezado profesional con banda gubernamental
2. Línea de contacto con fondo gris
3. Sección de tipo de documento con diseño destacado
4. Sección "Recibido De" con formato de formulario oficial
5. Sección de Información del Pago + Responsables (dos columnas)
6. Tabla con encabezado de fondo gris y filas alternas
7. Pie de página elegante con slogan y línea separadora
8. Funciones auxiliares reutilizables (`_buildFormRow`, `_buildInfoRow`)

**SOLUCIÓN APLICADA**:

#### Cambios Completos en `lib/PDF/due_invoice_pdf.dart`

**1. Imports Actualizados**:
```dart
import 'package:salespro_admin/commas.dart';  // Para myFormat
```

**2. Encabezado Profesional (Estilo Gubernamental/DGII)**:
- Banda con borde negro de 1.5px
- Logo + nombre de empresa con RNC en diseño horizontal
- Título "RECIBO DE PAGO" con número de factura destacado
- Línea secundaria con fondo gris (grey200) para contacto
- **Ubicación**: Header section, líneas 31-128

**3. Sección Tipo de Documento**:
```dart
pw.Container(
  decoration: pw.BoxDecoration(
    border: pw.Border.all(color: PdfColors.grey400, width: 1),
  ),
  child: pw.Column(
    children: [
      // Encabezado con fondo gris
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 15),
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        child: pw.Text('RECIBO DE PAGO - DOCUMENTO INTERNO', ...),
      ),
      // Contenido
      pw.Padding(
        padding: const pw.EdgeInsets.all(12),
        child: pw.Row(
          children: [
            pw.Text('Tipo:', ...),
            pw.Text('Abono a cuenta - Pago de balance pendiente', ...),
          ],
        ),
      ),
    ],
  ),
)
```
- **Ubicación**: Líneas 138-179

**4. Sección "RECIBIDO DE" (Cliente) - Estilo Formulario Oficial**:
```dart
pw.Container(
  decoration: pw.BoxDecoration(
    border: pw.Border.all(color: PdfColors.grey400, width: 1),
  ),
  child: pw.Column(
    children: [
      // Encabezado con fondo gris
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey200,
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
        ),
        child: pw.Text('RECIBIDO DE:', ...),
      ),
      // Datos del cliente usando _buildFormRow
      pw.Padding(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          children: [
            _buildFormRow('Nombre/Razón Social ', transactions.customerName),
            if (transactions.customerGst.trim().isNotEmpty)
              _buildFormRow('RNC/Cédula ', transactions.customerGst),
            if (transactions.customerAddress.isNotEmpty)
              _buildFormRow('Dirección ', transactions.customerAddress),
            if (transactions.customerPhone.isNotEmpty)
              _buildFormRow('Teléfono ', transactions.customerPhone),
          ],
        ),
      ),
    ],
  ),
)
```
- **Ubicación**: Líneas 186-223

**5. Sección de Información del Pago + Responsables (Dos Columnas)**:
```dart
pw.Row(
  children: [
    // Columna Izquierda: Información del Pago
    pw.Expanded(
      child: pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(...)),
        child: pw.Column(
          children: [
            // Encabezado con fondo gris
            pw.Container(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200, ...),
              child: pw.Text('INFORMACIÓN DEL PAGO', ...),
            ),
            // Contenido usando _buildInfoRow
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                children: [
                  _buildInfoRow('Estado', transactions.isPaid! ? 'PAGADO' : 'PENDIENTE'),
                  _buildInfoRow('Método', transactions.paymentType ?? 'N/A'),
                  if (transactions.bankName != null && transactions.bankName!.isNotEmpty)
                    _buildInfoRow('Banco', transactions.bankName!),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    pw.SizedBox(width: 8),
    // Columna Derecha: Responsables
    pw.Expanded(
      child: pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(...)),
        child: pw.Column(
          children: [
            // Encabezado con fondo gris
            pw.Container(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200, ...),
              child: pw.Text('RESPONSABLES', ...),
            ),
            // Contenido usando _buildInfoRow
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                children: [
                  _buildInfoRow('Recibido por', transactions.sellerName ?? 'Admin'),
                  _buildInfoRow('Hora', DateFormat('HH:mm').format(...)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ],
)
```
- **Ubicación**: Líneas 230-299

**6. Tabla Profesional con Filas Alternas**:
```dart
pw.Table.fromTextArray(
  border: const pw.TableBorder(
    left: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
    right: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
    bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
    top: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
    verticalInside: pw.BorderSide(color: PdfColors.grey400, width: 0.3),
    horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.3),
  ),
  // Encabezado con fondo gris claro
  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
  headerStyle: pw.TextStyle(
    color: PdfColors.black,
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
  ),
  // Filas alternas para mejor legibilidad
  rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
  oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFf5f5f5)),
  ...
)
```
- **Ubicación**: Líneas 399-444

**7. Pie de Página Elegante**:
```dart
pw.Column(
  children: [
    // Sección de firmas (igual que sales_invoice_pdf.dart)
    pw.Padding(...),
    pw.SizedBox(height: 15),
    // Línea separadora elegante
    pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 1,
      decoration: const pw.BoxDecoration(color: PdfColors.black),
    ),
    pw.SizedBox(height: 8),
    // Slogan + Texto de documento electrónico
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20),
      child: pw.Column(
        children: [
          pw.Text(
            '"Capturando momentos que duran para siempre"',
            style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Documento generado electrónicamente - ${setting.companyName.isNotEmpty == true ? setting.companyName : pdfFooter}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    ),
  ],
)
```
- **Ubicación**: Footer section, líneas 315-391

**8. Funciones Auxiliares Agregadas**:

```dart
/// Widget auxiliar para construir filas de información en formato etiqueta: valor
pw.Widget _buildInfoRow(String label, String value, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 70,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Widget auxiliar para construir filas con líneas punteadas (estilo formulario oficial)
pw.Widget _buildFormRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
        ),
        pw.Expanded(
          child: pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
            ),
            padding: const pw.EdgeInsets.only(left: 5, bottom: 2),
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}
```
- **Ubicación**: Líneas 695-751

**ARCHIVOS MODIFICADOS**:
- `lib/PDF/due_invoice_pdf.dart` - Reescritura completa con formato profesional (752 líneas finales)

**ELEMENTOS VISUALES AGREGADOS**:
1. ✅ Encabezado profesional con banda gubernamental (borde negro 1.5px)
2. ✅ Línea de contacto con fondo gris claro (grey200)
3. ✅ Sección "RECIBO DE PAGO - DOCUMENTO INTERNO" con diseño destacado
4. ✅ Sección "RECIBIDO DE" con formato de formulario oficial (líneas bajo datos)
5. ✅ Dos columnas: "INFORMACIÓN DEL PAGO" + "RESPONSABLES"
6. ✅ Línea divisoria de 2px (grey800) antes de tabla
7. ✅ Tabla con encabezado gris y filas alternas (grey200 / f5f5f5)
8. ✅ Bordes suaves multinivel (grey500, grey400, grey300)
9. ✅ Pie de página con línea separadora elegante
10. ✅ Slogan en itálica: _"Capturando momentos que duran para siempre"_
11. ✅ Texto "Documento generado electrónicamente"
12. ✅ Funciones auxiliares reutilizables

**CÓMO VERIFICAR**:
1. Ejecutar `flutter run -d chrome`
2. Login y navegar a "Due List" (Cuentas x Cobrar)
3. Seleccionar una factura con balance pendiente
4. Aplicar un pago parcial o total
5. Generar y descargar el PDF del recibo de pago
6. Verificar que el PDF tiene:
   - Encabezado profesional con banda negra
   - Sección de tipo de documento con fondo gris
   - Datos del cliente con líneas de formulario
   - Dos columnas (Info del Pago + Responsables)
   - Tabla con filas alternas
   - Pie de página elegante con slogan
   - Formato idéntico al PDF de ventas

**COMPARACIÓN ANTES/DESPUÉS**:
- **ANTES**: 869 líneas, diseño básico, sin estructura profesional
- **DESPUÉS**: 752 líneas, diseño profesional DGII, elementos visuales consistentes
- **RESULTADO**: Ambos PDFs (ventas y pagos) ahora tienen el mismo formato profesional

**LECCIONES APRENDIDAS**:
- Todos los PDFs del sistema deben mantener el mismo estilo visual profesional
- `sales_invoice_pdf.dart` es el estándar de referencia para el diseño de PDFs
- Las funciones auxiliares (`_buildFormRow`, `_buildInfoRow`) permiten reutilización de código
- El formato gubernamental/DGII con bandas, fondos grises y bordes da profesionalismo
- Las filas alternas en tablas mejoran significativamente la legibilidad
- El slogan y pie de página consistente refuerza la identidad de marca

---

### Persistencia de Datos de Usuario para Usuarios Multi-Sucursal (Enero 2026)

**PROBLEMA**: Usuarios con acceso a múltiples sucursales (`allowed_branches` con varias sucursales) perdían su identidad después del login. Las transacciones (ventas, pagos, etc.) mostraban "Admin" como `sellerName` en lugar del nombre real del usuario. Los usuarios con acceso a una sola sucursal funcionaban correctamente.

**CAUSA RAÍZ**:
El flujo de login en `lib/Repository/login_repo.dart` tiene dos caminos diferentes:

1. **Usuario con UNA sola sucursal** (líneas 79-86):
   - Login automático a la única sucursal disponible
   - Ejecuta `setUserDataOnLocalData`, `putUserDataImidiyate`, `AuditService().logLogin` (líneas 101-117)
   - Los datos del usuario se guardan correctamente en SharedPreferences

2. **Usuario con MÚLTIPLES sucursales** (líneas 87-98):
   - Muestra modal de selección de sucursal
   - **RETORNA INMEDIATAMENTE** (línea 98: `return;`)
   - Las líneas 101-117 **NUNCA SE EJECUTAN**
   - Los datos del usuario **NO se guardan en SharedPreferences**

**IMPACTO**:
- `SharedPreferences` no contiene `subUserTitle`, `userId`, `isSubUser`
- Cuando `due_popUp.dart` lee `prefs.getString('subUserTitle')`, obtiene `null`
- Por defecto usa `'Admin'` como fallback
- Todas las transacciones del usuario multi-sucursal aparecen como "Admin"

**SOLUCIÓN APLICADA**:

#### 1. Agregar parámetros de usuario al método `_showBranchSelectorModal`

**Líneas 140-147** (Método signature):
```dart
Future<void> _showBranchSelectorModal(
  BuildContext context,
  List<TenantModel> tenants, {
  required String userId,      // ← AGREGADO
  required String userName,    // ← AGREGADO
  required String userEmail,   // ← AGREGADO
  required bool isAdmin,       // ← AGREGADO
}) async {
```

**Líneas 89-96** (Llamada al método):
```dart
await _showBranchSelectorModal(
  context,
  availableTenants,
  userId: userId,        // ← AGREGADO
  userName: userName,    // ← AGREGADO
  userEmail: userEmail,  // ← AGREGADO
  isAdmin: isAdmin,      // ← AGREGADO
);
```

#### 2. Guardar datos del usuario DENTRO del modal al confirmar selección

**Líneas 362-393** (Botón "Continuar" en el modal):
```dart
onPressed: () async {
  // Configurar sucursal seleccionada
  await _apiService.setBranchId(selectedId);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('selected_tenant_id', selectedId);
  html.window.localStorage['selected_tenant_id'] = selectedId;

  // CRÍTICO: Guardar datos del usuario en SharedPreferences
  // Esto es necesario para usuarios multi-sucursal ya que el flujo
  // normal (líneas 101-117) no se ejecuta cuando hay múltiples sucursales
  await setUserDataOnLocalData(
    uid: userId,
    subUserTitle: userName,
    isSubUser: !isAdmin,
  );

  putUserDataImidiyate(
    uid: userId,
    title: userName,
    isSubUse: !isAdmin,
  );

  // Registrar login en auditoría
  await AuditService().logLogin(userId, userName, userEmail);

  // Cerrar modal y navegar
  if (context.mounted) {
    Navigator.of(context).pop();
    context.go('/blank-home');
  }
},
```

**ARCHIVOS MODIFICADOS**:
- `lib/Repository/login_repo.dart` - Líneas 89-96, 140-147, 362-393

**FLUJO CORRECTO DESPUÉS DEL FIX**:

```
Login Multi-Sucursal:
├─ signIn() ejecuta
├─ availableTenants.length > 1 detectado
├─ _showBranchSelectorModal(...) llamado CON userId, userName, userEmail, isAdmin
├─ Usuario selecciona sucursal en modal
├─ Al presionar "Continuar":
│  ├─ setBranchId(selectedId)
│  ├─ setUserDataOnLocalData(userId, userName, !isAdmin) ← NUEVO
│  ├─ putUserDataImidiyate(userId, userName, !isAdmin)   ← NUEVO
│  ├─ AuditService().logLogin(userId, userName, userEmail) ← NUEVO
│  └─ Navegar a /blank-home
└─ SharedPreferences ahora contiene subUserTitle, userId, isSubUser ✅
```

**CÓMO VERIFICAR**:
1. Crear un usuario con `allowed_branches: ["sde", "rom", "sdo"]` (múltiples sucursales)
2. Login con ese usuario
3. Verificar que aparece el modal de selección de sucursales
4. Seleccionar una sucursal y presionar "Continuar"
5. Navegar a "Cuentas por Cobrar" (Due List)
6. Realizar un pago de factura
7. Generar el PDF del recibo de pago
8. Verificar que el campo "Recibido por" muestra el nombre del usuario correcto (NO "Admin")

**VALIDACIÓN ADICIONAL**:
```dart
// En Flutter DevTools console, después de login multi-sucursal:
final prefs = await SharedPreferences.getInstance();
print(prefs.getString('subUserTitle')); // Debe mostrar el nombre del usuario, NO null
print(prefs.getString('userId'));       // Debe mostrar el UUID del usuario
print(prefs.getBool('isSubUser'));      // Debe mostrar true/false según el rol
```

**LECCIONES APRENDIDAS**:
- Los flujos de autenticación con múltiples caminos (single-branch vs multi-branch) deben ejecutar la misma lógica de persistencia
- No asumir que las variables globales (`isSubUser`, `constSubUserTitle`) estarán disponibles en todos los contextos - siempre usar SharedPreferences como fuente de verdad
- Cuando un método retorna temprano (`return;`), toda la lógica posterior se omite - hay que duplicar esa lógica en el camino alternativo
- Los modales que manejan flujos críticos (como selección de sucursal) deben completar TODAS las operaciones necesarias antes de navegar
- Siempre probar AMBOS casos: usuarios con una sucursal Y usuarios con múltiples sucursales
- El registro de auditoría (`AuditService().logLogin`) es crítico y debe ejecutarse en todos los flujos de autenticación

---

### Filtrado Impreciso de Categorías en Reservas y Rentas de Vestimentas (Enero 2026)

**PROBLEMA**: En las pantallas de selección de vestimentas para Reservas y Rentas (paquetes), al elegir una categoría específica, el sistema mostraba vestimentas de múltiples categorías en lugar de solo la categoría seleccionada. Por ejemplo, al buscar "Vestidos Largos" también aparecían "Vestidos", "Vestidos Cortos", etc.

**CONTEXTO**:
- **Administración de vestimentas** ([DressScreen.dart](lib/Screen/Dress/DressScreen.dart)) → ✅ Funcionaba correctamente con filtro exacto
- **Reservas** ([dress_selection_screen.dart](lib/Screen/Reservation/dress_selection_screen.dart)) → ❌ Filtro impreciso
- **Rentas/Paquetes** ([dress_selection_screen_package.dart](lib/Screen/Reservation/dress_selection_screen_package.dart)) → ❌ Filtro impreciso

**CAUSA RAÍZ**:
Las pantallas de Reservas y Rentas usaban `dressesOnceProvider(category)` que implementaba un filtro bidireccional problemático:

```dart
// dress_provider.dart líneas 383-389 (CÓDIGO PROBLEMÁTICO)
if (dressCategory == searchCategory ||
    dressCategory.contains(searchCategory) ||
    searchCategory.contains(dressCategory) ||  // ← PROBLEMA: Bidireccional
    _categoryMatches(searchCategory, dressCategory)) {
  dresses.add(DressModel.fromMap(data, id));
}
```

**Ejemplos del problema**:
- Buscas: **"Vestidos Largos"** → Incluía: "Vestidos" porque `"Vestidos Largos".contains("Vestidos")` = `true`
- Buscas: **"Dama de Honor"** → Incluía: "Dama" porque `"Dama de Honor".contains("Dama")` = `true`
- Buscas: **"Vestidos de Novia"** → Incluía: "Vestidos" por la misma razón

Además, el provider tenía un fallback peligroso que retornaba **TODOS los vestidos** si no encontraba coincidencias exactas (líneas 394-403).

**SOLUCIÓN APLICADA**:

Cambiar ambas pantallas para usar el mismo patrón exitoso de `DressScreen`: filtro local con igualdad exacta.

#### 1. Cambio en [dress_selection_screen.dart](lib/Screen/Reservation/dress_selection_screen.dart)

**ANTES** (líneas 115-118):
```dart
final dressesAsync = isUsingOneTimeProvider
    ? ref.watch(dressesOnceProvider(widget.packagesAsync.category))  // ❌ Filtro impreciso
    : ref.watch(availableDressesByComponentsProvider(widget.packagesAsync.category));
```

**DESPUÉS** (líneas 115-116):
```dart
// Usar dressesProvider (sin categoría) y filtrar localmente
final dressesAsync = ref.watch(dressesProvider);
```

**Filtro exacto agregado** (líneas 227-231):
```dart
// Filtrar por categoría EXACTA primero
final categoryFiltered = dresses.where((dress) {
  // Igualdad exacta como en DressScreen
  return dress.category == widget.packagesAsync.category;
}).toList();
```

#### 2. Cambio en [dress_selection_screen_package.dart](lib/Screen/Reservation/dress_selection_screen_package.dart)

**ANTES** (líneas 116-119):
```dart
final dressesAsync = isUsingOneTimeProvider
    ? ref.watch(dressesOnceProvider(widget.CategoryComposite))  // ❌ Filtro impreciso
    : ref.watch(availableDressesByComponentsProvider(widget.CategoryComposite));
```

**DESPUÉS** (líneas 116-117):
```dart
// Usar dressesProvider (sin categoría) y filtrar localmente
final dressesAsync = ref.watch(dressesProvider);
```

**Filtro exacto agregado** (líneas 231-235):
```dart
// Filtrar por categoría EXACTA primero
final categoryFiltered = dresses.where((dress) {
  // Igualdad exacta como en DressScreen
  return dress.category == widget.CategoryComposite;
}).toList();
```

**ARCHIVOS MODIFICADOS**:
- [lib/Screen/Reservation/dress_selection_screen.dart](lib/Screen/Reservation/dress_selection_screen.dart) - Líneas 115-116, 227-231
- [lib/Screen/Reservation/dress_selection_screen_package.dart](lib/Screen/Reservation/dress_selection_screen_package.dart) - Líneas 116-117, 231-235

**COMPARACIÓN ANTES/DESPUÉS**:

| Categoría Buscada | Categorías en DB | Resultado ANTES ❌ | Resultado AHORA ✅ |
|-------------------|------------------|-------------------|-------------------|
| "Vestidos Largos" | "Vestidos", "Vestidos Largos", "Vestidos Cortos" | Muestra TODOS | Solo "Vestidos Largos" |
| "Dama de Honor" | "Dama", "Dama de Honor" | Muestra AMBOS | Solo "Dama de Honor" |
| "Vestidos de Novia" | "Vestidos", "Vestidos de Novia" | Muestra AMBOS | Solo "Vestidos de Novia" |

**CÓMO VERIFICAR**:
1. Ir a **Reservas** → Seleccionar paquete con categoría específica (ej: "Vestidos Largos")
2. Verificar que SOLO aparecen vestidos con categoría EXACTAMENTE "Vestidos Largos"
3. Ir a **Rentas/Paquetes** → Seleccionar componente con categoría
4. Verificar que SOLO aparecen vestidos de esa categoría exacta
5. Comparar con **Administración** → El filtro debe funcionar idéntico

**LECCIONES APRENDIDAS**:
- El uso de `contains()` bidireccional (`searchCategory.contains(dressCategory)`) en filtros de texto causa falsos positivos
- Para categorías, usar siempre igualdad exacta (`==`) en lugar de coincidencia parcial
- Cuando un patrón funciona bien en una parte del sistema (DressScreen), reusarlo en lugar de reinventar
- Los fallbacks que retornan "todos los registros" cuando no hay coincidencias confunden al usuario - mejor mostrar pantalla vacía
- Mantener consistencia de filtrado en todas las pantallas que manejan el mismo tipo de datos

---

### PDF No Se Genera en Cuentas por Cobrar - Falta Parámetro context (Enero 2026)

**PROBLEMA**: El PDF de recibos de pago en "Cuentas por Cobrar" no se generaba cuando se aplicaba un pago. No aparecía ningún error visible, pero el PDF simplemente no se creaba ni descargaba.

**CAUSA RAÍZ**:
El método `printDueInvoice` en `lib/PDF/print_pdf.dart` invoca internamente a `generateDueDocument` que **requiere el parámetro `context`** para:
1. Obtener la configuración de sucursal mediante `ProviderScope.containerOf(context)`
2. Leer el `branchSettingsProvider` para personalizar el encabezado del PDF con datos de la sucursal
3. Sin este parámetro, la función fallaba silenciosamente y no generaba el PDF

**SOLUCIÓN APLICADA**:

#### Archivo Modificado: `lib/Screen/Due List/due_popUp.dart`

**Cambio 1 - Generación de PDF para WhatsApp (línea 907)**:
```dart
// ❌ ANTES (INCORRECTO - Sin context):
final pdfData = await GeneratePdfAndPrint().printDueInvoice(
  personalInformationModel: data,
  dueTransactionModel: dueTransactionModel,
  setting: setting,
  returnPdfData: true,
  skipWhatsappCheck: true,
);

// ✅ AHORA (CORRECTO - Con context):
final pdfData = await GeneratePdfAndPrint().printDueInvoice(
  personalInformationModel: data,
  dueTransactionModel: dueTransactionModel,
  setting: setting,
  context: context,  // ← AGREGADO
  returnPdfData: true,
  skipWhatsappCheck: true,
);
```

**Cambio 2 - Impresión del PDF (línea 930)**:
```dart
// ❌ ANTES (INCORRECTO - Sin context):
await GeneratePdfAndPrint().printDueInvoice(
  personalInformationModel: data,
  dueTransactionModel: dueTransactionModel,
  setting: setting,
);

// ✅ AHORA (CORRECTO - Con context):
await GeneratePdfAndPrint().printDueInvoice(
  personalInformationModel: data,
  dueTransactionModel: dueTransactionModel,
  setting: setting,
  context: context,  // ← AGREGADO
);
```

**ARCHIVOS MODIFICADOS**:
- `lib/Screen/Due List/due_popUp.dart` - Líneas 911 y 935

**FLUJO COMPLETO**:
1. Usuario aplica pago en Cuentas por Cobrar
2. Se guarda la transacción en PostgreSQL
3. Si el usuario elige enviar por WhatsApp:
   - Se genera el PDF con `context` incluido
   - Se envía el PDF codificado en base64
4. Siempre se imprime/descarga el PDF (con `context` incluido)

**CÓMO VERIFICAR**:
1. Ejecutar `flutter run -d chrome`
2. Login y navegar a **Due List (Cuentas x Cobrar)**
3. Seleccionar un cliente con balance pendiente
4. Click en el botón de pago
5. Ingresar un monto de pago
6. Click en **Submit**
7. Verificar que:
   - El diálogo de WhatsApp aparece (si está configurado)
   - El PDF se genera correctamente
   - El PDF se abre/descarga automáticamente
   - El formato profesional está presente (banda negra, datos de sucursal, etc.)

**POR QUÉ `generateDueDocument` NECESITA `context`**:
```dart
// lib/PDF/due_invoice_pdf.dart - Líneas 29-39
FutureOr<Uint8List> generateDueDocument({
  required DueTransactionModel transactions,
  required PersonalInformationModel personalInformation,
  required GeneralSettingModel setting,
  required BuildContext context,  // ← REQUERIDO
}) async {
  // ...

  // Necesita context para acceder a providers
  final ref = ProviderScope.containerOf(context);
  BranchSettingsModel? branchSettings;
  try {
    branchSettings = await ref.read(branchSettingsProvider.future).timeout(
      const Duration(seconds: 3),
      onTimeout: () => BranchSettingsModel.defaultSettings(''),
    );
  } catch (e) {
    branchSettings = BranchSettingsModel.defaultSettings('');
  }

  // Usa branchSettings para personalizar el PDF...
}
```

**LECCIONES APRENDIDAS**:
- Siempre verificar que todos los parámetros requeridos se pasen correctamente en llamadas a funciones
- Los métodos que acceden a providers (como `branchSettingsProvider`) SIEMPRE necesitan `context`
- Si un PDF no se genera y no hay error visible, verificar que todos los parámetros requeridos estén presentes
- El parámetro `context` es crítico para acceder al árbol de widgets y providers en Flutter
- Usar `context` permite que el PDF tenga datos dinámicos según la sucursal actual del usuario
- La falta de un parámetro requerido puede causar fallas silenciosas sin mensajes de error claros

---

### Campo seller_name No Se Persiste en Cuentas por Cobrar (Enero 2026)

**PROBLEMA**: Al aplicar un pago en "Cuentas por Cobrar", el PDF mostraba siempre "Admin" en el campo "Recibido por", sin importar qué usuario había procesado el pago. Los datos del vendedor no se persistían correctamente en la base de datos.

**CAUSA RAÍZ**:
1. **El endpoint `/api/due-transactions` NO existía en el backend** - El frontend llamaba a este endpoint pero no estaba registrado
2. **La columna `seller_name` NO existía en la tabla `due_transactions`** - Faltaba la columna en PostgreSQL
3. **El endpoint `/api/transactions/due` existente NO guardaba el campo `seller_name`** - Solo guardaba campos básicos

**SOLUCIÓN APLICADA**:

#### 1. Agregar Columna `seller_name` a PostgreSQL
```sql
-- Agregar seller_name a todos los esquemas (stg, sde, sdo, rom)
ALTER TABLE stg.due_transactions ADD COLUMN IF NOT EXISTS seller_name VARCHAR(200);
ALTER TABLE sde.due_transactions ADD COLUMN IF NOT EXISTS seller_name VARCHAR(200);
ALTER TABLE sdo.due_transactions ADD COLUMN IF NOT EXISTS seller_name VARCHAR(200);
ALTER TABLE rom.due_transactions ADD COLUMN IF NOT EXISTS seller_name VARCHAR(200);
```

#### 2. Crear Endpoint Dedicado
**Archivo creado**: `/var/www/victorpos-api/src/routes/due-transactions.js`
- POST endpoint que guarda `seller_name` correctamente
- Mapea campos de `DueTransactionModel` (camelCase) a PostgreSQL (snake_case)
- Registrado en `index.js` como `/api/due-transactions`

**ARCHIVOS BACKEND MODIFICADOS**:
- ✅ `/var/www/victorpos-api/src/routes/due-transactions.js` (creado)
- ✅ `/var/www/victorpos-api/index.js` (ruta agregada)
- ✅ PostgreSQL: Columna `seller_name` en `due_transactions` (todos los esquemas)

**CÓMO VERIFICAR**:
1. Login con usuario específico
2. Aplicar pago en Due List
3. Verificar PDF muestra nombre correcto en "Recibido por"
4. Verificar base de datos:
   ```sql
   SET search_path TO stg;
   SELECT invoice_number, seller_name FROM due_transactions ORDER BY created_at DESC LIMIT 5;
   ```

**CORRECCIÓN ADICIONAL - Variables Globales No Confiables**:

El primer intento usaba las variables globales `isSubUser` y `constSubUserTitle` de `lib/const.dart`:
```dart
// ❌ NO FUNCIONA - Las variables globales no están cargadas correctamente
dueTransactionModel.sellerName = isSubUser ? constSubUserTitle : 'Admin';
```

**Problema**: Las variables globales no siempre están disponibles en el contexto del popup.

**Solución final aplicada** (`lib/Screen/Due List/due_popUp.dart` líneas 838-841):
```dart
// ✅ FUNCIONA - Leer directamente de SharedPreferences
final prefs = await SharedPreferences.getInstance();
final userName = prefs.getString('subUserTitle') ?? 'Admin';
dueTransactionModel.sellerName = userName;
```

**También actualizado** en transferVerification (línea 876):
```dart
sellerName: userName,  // En lugar de: isSubUser ? constSubUserTitle : 'Admin'
```

**ARCHIVOS MODIFICADOS**:
- ✅ `lib/Screen/Due List/due_popUp.dart` - Líneas 838-841 y 876

**LECCIONES APRENDIDAS**:
- Verificar que endpoints backend existan y estén registrados
- Agregar columnas en TODOS los esquemas (stg, sde, sdo, rom)
- El campo `seller_name` es crítico para auditoría
- Persistir datos en BD en lugar de solo mostrarlos en PDF
- **Leer datos de usuario directamente de SharedPreferences en lugar de variables globales**
- Las variables globales de `const.dart` no siempre están cargadas en todos los contextos
- `nb_utils` ya incluye SharedPreferences, no es necesario importarlo por separado

---

### Permisos de Usuario No Se Muestran Actualizados Después de Guardar (Enero 2026)

**PROBLEMA**: Al editar permisos de un usuario desde "User Roles", guardar los cambios, y volver a abrir el mismo usuario para verificar, los permisos aparecían como si no se hubieran guardado (mostraban valores antiguos). Sin embargo, los permisos SÍ se guardaban correctamente en la base de datos.

**CONTEXTO**:
- El problema ocurría en TODAS las sucursales (stg, sde, sdo, rom)
- Los permisos SÍ persistían en PostgreSQL correctamente
- El backend (`PUT /api/users/:id`) funcionaba perfectamente
- La API retornaba los datos actualizados correctamente
- El problema era **exclusivamente en el frontend** al cargar datos para edición

**CAUSA RAÍZ**:

El flujo de edición de usuarios tenía un problema de **datos cacheados**:

1. **Usuario hace cambios**: Actualiza permisos → Guarda → `PUT /api/users/:id` ejecuta correctamente
2. **Backend persiste**: Los cambios se guardan en PostgreSQL sin problemas
3. **Provider se refresca**: `ref.refresh(userRoleProvider)` se ejecuta (línea 1713)
4. **Usuario cierra diálogo**: `GoRouter.of(context).pop()` ejecuta
5. **Lista se actualiza**: El provider carga usuarios frescos del API
6. **PROBLEMA**: Cuando usuario vuelve a abrir el mismo usuario para editar:
   - El diálogo `AddUserRole` recibe el `UserRoleModel` del `paginatedList` como parámetro
   - En `initState()`, el widget carga estos datos en el formulario mediante `setEditData()`
   - **NO hace GET fresco del usuario desde el API**
   - Muestra los datos que estaban en memoria del provider

**Archivos Involucrados**:
- Frontend: `lib/Screen/User Role System/add_user_role_screen.dart`
- Frontend: `lib/Screen/User Role System/user_role_screen.dart` (pantalla lista)
- Backend: `/var/www/victorpos-api/src/routes/users.js` (funcionaba correctamente)
- Provider: `lib/Provider/user_role_provider.dart` (autoDispose provider)

**PRUEBA QUE CONFIRMÓ EL DIAGNÓSTICO**:

Ejecuté un test completo del flujo API directamente con curl:

```bash
# PASO 1: GET inicial - audit.delete=false
curl GET /api/users/735a63b3-a6d8-4b1a-9788-b5134f39e60e
# Resultado: audit: {view: true, edit: true, delete: false}

# PASO 2: PUT actualización - cambiar audit.delete=true
curl PUT /api/users/735a63b3-a6d8-4b1a-9788-b5134f39e60e
# Body: {"permissions": {"audit": {"view": true, "edit": true, "delete": true}}}

# PASO 3: GET después de actualizar
curl GET /api/users/735a63b3-a6d8-4b1a-9788-b5134f39e60e
# Resultado: audit: {view: true, edit: true, delete: true} ✅ CAMBIO PERSISTIÓ

# PASO 4: Verificar en PostgreSQL
SELECT permission_type, can_view, can_edit, can_delete
FROM user_permissions
WHERE user_id = '735a63b3-a6d8-4b1a-9788-b5134f39e60e'
  AND permission_type = 'audit';
# Resultado: audit | t | t | t ✅ EN BASE DE DATOS CORRECTO
```

**Conclusión**: El backend funciona perfectamente. El problema era que el frontend no hacía GET fresco al abrir el diálogo de edición.

**SOLUCIÓN APLICADA**:

#### 1. Agregar método `_loadFreshUserData()` en `add_user_role_screen.dart`

**Líneas 129-181**: Nuevo método que obtiene datos frescos del API al abrir el diálogo de edición

```dart
/// Obtiene datos frescos del usuario desde el API
/// Esto es crítico para evitar mostrar permisos desactualizados
Future<void> _loadFreshUserData() async {
  if (widget.userRoleModel == null) return;

  setState(() {
    _isLoadingFreshData = true;
  });

  try {
    final apiService = ApiService();
    final userId = widget.userRoleModel!.userKey ?? widget.userRoleModel!.databaseId;

    debugPrint('🔄 [AddUserRole] Obteniendo datos frescos del usuario: $userId');

    final response = await apiService.get('users/$userId');

    if (response.success && response.data != null) {
      final userData = response.data['user'];

      // Crear modelo actualizado con datos frescos del API
      _freshUserData = UserRoleModel(
        email: userData['email'] ?? '',
        userTitle: userData['name'] ?? '',
        username: userData['username'] ?? '',
        databaseId: userData['id']?.toString() ?? '',
        userRoleName: userData['role'] ?? 'user',
        branchId: userData['branch_id'] ?? '',
        branchName: userData['branch_name'] ?? '',
        allowedBranches: userData['allowed_branches'] is List
            ? List<String>.from(userData['allowed_branches'])
            : null,
        permissions: _parsePermissions(userData['permissions']),
      );
      _freshUserData!.userKey = userData['id']?.toString();

      debugPrint('✅ [AddUserRole] Datos frescos cargados - Permisos: ${_freshUserData!.permissions.length}');

      // Ahora cargar los datos frescos en el formulario
      setEditData();
    } else {
      debugPrint('⚠️ [AddUserRole] Error obteniendo datos frescos, usando datos del modelo');
      // Fallback: usar datos del modelo original
      setEditData();
    }
  } catch (e) {
    debugPrint('❌ [AddUserRole] Excepción obteniendo datos frescos: $e');
    // Fallback: usar datos del modelo original
    setEditData();
  } finally {
    setState(() {
      _isLoadingFreshData = false;
    });
  }
}
```

#### 2. Modificar `initState()` para llamar al nuevo método

**Líneas 117-125**:
```dart
@override
void initState() {
  super.initState();
  checkCurrentUserAndRestartApp();
  if (widget.userRoleModel != null) {
    // CRÍTICO: Obtener datos frescos del API para evitar usar datos cacheados
    _loadFreshUserData();
  }
}
```

#### 3. Agregar método `_parsePermissions()` para transformar formato API

**Líneas 183-216**: Convierte permisos del formato API (objeto) al formato del modelo (lista)

```dart
/// Convertir permisos del formato API a Permission list
List<Permission> _parsePermissions(dynamic permissionsData) {
  if (permissionsData == null) return [];

  final permissions = <Permission>[];

  if (permissionsData is Map) {
    // API retorna objeto: {type: {view, edit, delete}}
    permissionsData.forEach((key, value) {
      if (value is Map) {
        permissions.add(Permission(
          type: key.toString(),
          view: value['view'] ?? false,
          edit: value['edit'] ?? false,
          delete: value['delete'] ?? false,
        ));
      }
    });
  } else if (permissionsData is List) {
    // Formato array: [{type, view, edit, delete}]
    for (var perm in permissionsData) {
      if (perm is Map) {
        permissions.add(Permission(
          type: perm['type']?.toString() ?? '',
          view: perm['view'] ?? false,
          edit: perm['edit'] ?? false,
          delete: perm['delete'] ?? false,
        ));
      }
    }
  }

  return permissions;
}
```

#### 4. Modificar `setEditData()` para usar datos frescos

**Líneas 218-236**:
```dart
setEditData() {
  // Usar datos frescos si están disponibles, si no usar el modelo original
  final dataSource = _freshUserData ?? widget.userRoleModel;

  if (dataSource == null) return;

  emailController.text = dataSource.email ?? '';
  titleController.text = dataSource.userTitle ?? '';
  userRoleName.text = dataSource.userRoleName ?? '';
  selectedBranchId = dataSource.branchId ?? 'stg';
  selectedAllowedBranches = dataSource.allowedBranches ?? [];

  if (dataSource.permissions.isNotEmpty) {
    // Migrar permisos faltantes antes de asignar
    migrateExistingPermissionsFromData(dataSource);
  }

  debugPrint('📝 [AddUserRole.setEditData] Datos cargados: ${dataSource.userTitle}, permisos: ${dataSource.permissions.length}');
}
```

#### 5. Crear función auxiliar `migrateExistingPermissionsFromData()`

**Líneas 238-271**: Migra permisos faltantes usando el modelo especificado (en lugar del widget.userRoleModel fijo)

```dart
/// Migrar permisos usando el modelo de datos especificado
void migrateExistingPermissionsFromData(UserRoleModel model) {
  // Obtener todos los tipos de permisos que deberían existir
  List<String> allRequiredPermissionTypes = [
    'dashboard', 'inicio', 'tablero',
    'services', 'register_package', 'register_clothing',
    'reservations', 'reservation_calendar', 'rent_clothes', 'reserve_package',
    'sales', 'pos_sales', 'inventory_sales', 'sales_list', 'sales_return', 'quotation_list',
    'purchases', 'pos_purchase', 'purchase_list', 'purchase_return',
    'products', 'categories', 'warehouses', 'inventory_list', 'inventory_equipment',
    'customers', 'suppliers',
    'confirmations',
    'expense', 'income', 'transaction', 'dues', 'ledger', 'loss_profit',
    'reports',
    'audit',
    'hrm', 'employees', 'designations', 'salary_list',
    'user_roles', 'tax_rates',
  ];

  // Verificar qué permisos faltan y agregarlos
  List<String> existingPermissionTypes = model.permissions.map((p) => p.type).toList();

  for (String requiredPermissionType in allRequiredPermissionTypes) {
    if (!existingPermissionTypes.contains(requiredPermissionType)) {
      // Agregar el permiso faltante con valores por defecto
      model.permissions.add(Permission(
        type: requiredPermissionType,
        view: false,
        edit: false,
        delete: false,
      ));
    }
  }
}
```

**ARCHIVOS MODIFICADOS**:
- `lib/Screen/User Role System/add_user_role_screen.dart` - Líneas 113-114 (variables), 117-125 (initState), 129-181 (_loadFreshUserData), 183-216 (_parsePermissions), 218-236 (setEditData), 238-271 (migrateExistingPermissionsFromData), 2073-2076 (backward compatibility wrapper)

**FLUJO CORRECTO DESPUÉS DEL FIX**:

```
Usuario edita permisos:
├─ 1. Abre diálogo de edición
│  ├─ initState() ejecuta
│  ├─ _loadFreshUserData() hace GET /api/users/:id
│  ├─ Recibe datos actualizados del API
│  ├─ Crea _freshUserData con datos frescos
│  └─ setEditData() carga datos frescos en el formulario
│
├─ 2. Usuario modifica permisos (ej: audit.delete = true)
│
├─ 3. Usuario presiona "Update"
│  ├─ PUT /api/users/:id ejecuta
│  ├─ Backend persiste en PostgreSQL
│  ├─ ref.refresh(userRoleProvider) invalida caché
│  └─ GoRouter.of(context).pop() cierra diálogo
│
├─ 4. Lista de usuarios se recarga (provider autoDispose)
│
└─ 5. Usuario vuelve a abrir el mismo usuario
   ├─ initState() ejecuta nuevamente
   ├─ _loadFreshUserData() hace OTRO GET fresco
   ├─ Recibe datos con audit.delete = true ✅
   └─ Formulario muestra valores actualizados ✅
```

**CÓMO VERIFICAR**:
1. Login como admin
2. Ir a "User Roles"
3. Seleccionar usuario (ej: Brianna)
4. Editar permisos (cambiar algún checkbox)
5. Guardar cambios
6. Cerrar diálogo
7. Volver a abrir el mismo usuario
8. Verificar que los checkboxes muestran los valores actualizados ✅
9. En logs de debug deberías ver:
   ```
   🔄 [AddUserRole] Obteniendo datos frescos del usuario: 735a63b3-a6d8-4b1a-9788-b5134f39e60e
   ✅ [AddUserRole] Datos frescos cargados - Permisos: 42
   📝 [AddUserRole.setEditData] Datos cargados: Brianna Test, permisos: 42
   ```

**LECCIONES APRENDIDAS**:
- **Nunca confiar en datos cacheados del provider para pantallas de edición** - Siempre hacer GET fresco del API
- Los providers `autoDispose` se recrean al regresar a la pantalla, pero los parámetros pasados al diálogo siguen siendo los mismos objetos en memoria
- `ref.refresh()` invalida el provider, pero NO actualiza los objetos `UserRoleModel` que ya están instanciados y pasados como parámetros
- El backend puede estar funcionando perfectamente (guardando y retornando datos correctos), pero el frontend puede mostrar datos viejos si no hace GET fresco
- Cuando un formulario de edición depende de datos actualizados, debe hacer su propia consulta al API en `initState()`, NO confiar en los datos del parámetro
- Siempre implementar fallback (try-catch) para que si el GET fresco falla, al menos se muestren los datos del modelo original
- Los debug logs son esenciales para diagnosticar problemas de datos cacheados vs frescos

---

## 📋 Resumen Ejecutivo de Soluciones Recientes

### ✅ v2.1.103 - Fix de Persistencia de Permisos de Usuario (Enero 2026)

**Problema**: Los permisos de usuario no se mostraban actualizados en el diálogo de edición después de guardar cambios.

**Solución**: Implementado GET fresco del API en `initState()` de `AddUserRole` para cargar datos actualizados en lugar de usar datos cacheados del provider.

**Archivo modificado**: `lib/Screen/User Role System/add_user_role_screen.dart`

**Método clave agregado**: `_loadFreshUserData()` - Hace GET del usuario al abrir el diálogo de edición.

**Deployment**: v2.1.103 (Build: 20260119-1252)

**Instrucciones para verificar**:
1. Recargar página con CTRL+SHIFT+R (hard reload) para limpiar caché
2. Verificar versión = v2.1.103 en esquina superior derecha
3. Editar usuario → Modificar permisos → Guardar
4. Cerrar y reabrir usuario → Los checkboxes deben mostrar valores actualizados ✅

**Diagnóstico rápido**:
```bash
# Ejecutar script de diagnóstico para cualquier usuario
/tmp/diagnose_miguel_permissions.sh

# Verificar que API y BD coinciden
# Si coinciden → Backend OK, problema es caché del navegador
# Solución: CTRL+SHIFT+R para limpiar caché
```

**Comandos útiles**:
```bash
# Ver permisos de un usuario específico
curl -H "Authorization: Bearer $TOKEN" \
  "https://sistema.victorguzmanfotografia.com/api/users/{user_id}"

# Verificar en PostgreSQL
sshpass -p "password" ssh root@72.62.163.74 \
  "sudo -u postgres psql victorpos -c \
  'SELECT permission_type, can_view, can_edit, can_delete
   FROM user_permissions WHERE user_id = ''{user_id}''
   ORDER BY permission_type;'"
```

**NOTA IMPORTANTE**: Si después de CTRL+SHIFT+R los permisos aún no se muestran correctamente:
- Cerrar completamente el navegador y volver a abrir
- O usar modo incógnito (CTRL+SHIFT+N)
- Verificar que la versión sea v2.1.103

---

## 🔍 Guía de Troubleshooting Rápido

### Problema: "Los permisos no se muestran después de guardar"

**Paso 1**: Verificar versión desplegada
```bash
curl -s "https://sistema.victorguzmanfotografia.com/app-version.json" | jq .
```

**Paso 2**: Verificar datos en API
```bash
curl -H "Authorization: Bearer $TOKEN" \
  "https://sistema.victorguzmanfotografia.com/api/users/{user_id}" | jq '.user.permissions'
```

**Paso 3**: Verificar datos en PostgreSQL
```bash
ssh root@72.62.163.74 "sudo -u postgres psql victorpos -c \
  'SELECT COUNT(*) FROM user_permissions WHERE user_id = ''{user_id}''
   AND (can_view OR can_edit OR can_delete);'"
```

**Paso 4**: Comparar resultados
- Si API y BD coinciden → Problema de caché del navegador
- Si API y BD NO coinciden → Problema en backend (poco probable después de v2.1.103)

**Solución**:
- Caché del navegador: CTRL+SHIFT+R
- Backend: Verificar logs del servidor y reiniciar con `pm2 restart victorpos-api`