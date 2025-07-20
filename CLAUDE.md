# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Dylanpos v2** (package name: `salespro_admin`) is a comprehensive Flutter web application for a dress rental and photography reservation system (Sistema de reservas y renta de vestidos para fotografías). It's built as a Point of Sale (POS) system with advanced inventory management, customer management, and business analytics.

## Technology Stack

- **Framework**: Flutter (Web-focused with responsive design)
- **Backend**: Firebase (Firestore, Auth, Storage, Database, Messaging)
- **State Management**: Riverpod + Provider
- **Navigation**: GoRouter with shell routes
- **UI Framework**: Material Design with responsive breakpoints
- **Internationalization**: Flutter Intl (50+ languages supported)
- **PDF Generation**: Syncfusion PDF libraries
- **Payment Processing**: PayPal integration

## Development Commands

### Essential Commands
```bash
# Install dependencies
flutter pub get

# Run the app (web)
flutter run -d chrome --web-renderer html

# Build for web
flutter build web --web-renderer html

# Analyze code
flutter analyze

# Run tests
flutter test

# Generate localization files
flutter gen-l10n

# Clean build files
flutter clean
```

### Code Quality
```bash
# Check for linting issues (uses flutter_lints)
flutter analyze

# Format code
dart format .
```

## Project Architecture

### Directory Structure

**Core Business Logic**:
- `lib/Provider/` - Business logic providers (Riverpod)
- `lib/Repository/` - Data access layer
- `lib/model/` - Data models and DTOs
- `lib/services/` - Service layer implementations

**UI Layer**:
- `lib/Screen/` - Feature-based screen organization
- `lib/Route/` - Navigation and routing logic
- `lib/Screen/Widgets/` - Reusable UI components

**Key Feature Modules**:
- `Reservation/` - Dress reservation system with calendar
- `Inventory Sales/` - POS and inventory management
- `Due List/` - Accounts receivable and invoice management
- `Reports/` - Business analytics and reporting
- `HRM/` - Human Resource Management
- `Authentication/` - User authentication and profiles

### Firebase Integration

The app heavily relies on Firebase services:
- **Firestore**: Primary database for all business data
- **Authentication**: User management and role-based access
- **Storage**: Image and document storage
- **Database**: Real-time data synchronization
- **Messaging**: Push notifications

### State Management Pattern

Uses a hybrid approach:
- **Riverpod**: Modern reactive state management for new features
- **Provider**: Legacy state management (being migrated)
- Data flows: Repository → Provider → UI

### Responsive Design

- Breakpoints: sm: 576px, md: 1240px, lg: infinity
- Mobile-first approach with tablet-specific screens
- Responsive grid system for adaptive layouts

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

### Testing
- Widget tests in `test/` directory
- Use `flutter test` for running tests
- Multiple validation scripts found in `lib/Screen/Inventory Sales/` for payment method validation
- Business logic validation scripts for specific features like payment flows

### Code Style
- Uses `flutter_lints` for code quality
- Follow existing patterns for consistency
- Provider-based architecture for state management

### Firebase Configuration
- Development and production environments configured
- Web push notifications implemented
- Database rules defined in `database.rules.json`

### Critical Business Logic
- Payment flow validation in `lib/Screen/Inventory Sales/`
- Invoice generation and PDF handling in `lib/PDF/`
- Reservation system calendar logic in `lib/Screen/Reservation/`
- Financial calculations in `lib/Screen/Reports/`

## Common Development Tasks

When working with this codebase:

1. **Adding new screens**: Follow the feature-folder pattern in `lib/Screen/`
2. **Database operations**: Use the Repository pattern in `lib/Repository/`
3. **State management**: Prefer Riverpod for new features
4. **Routing**: Add routes to `lib/Route/app_routes.dart`
5. **Localization**: Add strings to `lib/l10n/*.arb` files
6. **PDF generation**: Use Syncfusion PDF libraries for consistency

## Security Notes

- Firebase security rules are critical for data protection
- User role validation is implemented throughout the app
- Payment processing uses secure PayPal integration
- Sensitive business data requires appropriate access controls