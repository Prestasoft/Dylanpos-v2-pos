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