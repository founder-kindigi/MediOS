# Architecture

## Overview

MediOS uses a feature-first architecture with Provider for state management and a singleton DatabaseHelper for all SQLite operations. The app is built for Android, iOS, Web, and Windows from a single Flutter codebase.

## Layer Diagram

```
┌──────────────────────────────────────────────┐
│                  UI Layer                     │
│  Screens (per feature) / Common Widgets      │
├──────────────────────────────────────────────┤
│              Service Layer                    │
│  AuthService / InventoryService / ...         │
│  ChangeNotifier + Provider pattern            │
├──────────────────────────────────────────────┤
│              Database Layer                   │
│  DatabaseHelper (singleton, conditional)     │
│  db_io.dart / db_web.dart / db_stub.dart     │
├──────────────────────────────────────────────┤
│               SQLite                         │
│  sqflite_common_ffi / sqflite_common_ffi_web │
└──────────────────────────────────────────────┘
```

## Database Layer

`lib/core/database/database_helper.dart` exports the correct implementation using Dart conditional imports:

- **db_io.dart** — uses `sqflite_common_ffi` for native platforms (Android, iOS, Windows)
- **db_web.dart** — uses `sqflite_common_ffi_web` for web with SQLite WASM worker
- **db_stub.dart** — stub for unsupported platforms

### Singleton Pattern

```dart
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  factory DatabaseHelper() => _instance;
}
```

### Test Injection

Each platform implementation provides `setTestDatabase(Database? db)` that overrides the singleton `_database` field. Tests use `sqflite_common_ffi` with `inMemoryDatabasePath`.

### DB Versioning (v1 → v7)

| Version | Changes |
|---------|---------|
| v1 | Initial schema: users, categories, medicines, sales, sale_items, suppliers, customers, purchase_orders, purchase_order_items, inventory_transactions |
| v2 | Added returns + return_items tables |
| v3 | Added barcode column to medicines |
| v4 | Added stores table, store_id columns on medicines/sales/purchase_orders/inventory_transactions |
| v5 | Added prescriptions + prescription_items tables |
| v6 | Added wholesale_price column to medicines |
| v7 | Added customer_orders + customer_order_items tables |

## Feature Modules

Each feature follows this structure:

```
features/{feature}/
├── services/
│   └── {feature}_service.dart    — ChangeNotifier with business logic
└── screens/
    └── ...                       — UI screens
```

Services extend `ChangeNotifier` and are provided via `ChangeNotifierProvider` in `main.dart`. The provider tree is built at the app root level.

## State Management

Provider is used with `MultiProvider` in `main.dart`. Each feature service is registered as a `ChangeNotifierProvider`. UI components use `context.watch<T>()` or `context.read<T>()` to access state.

## Routing

Named routes are defined in `main.dart` with a static `RouteConfig` class. The AppDrawer in `lib/widgets/` provides navigation to all feature screens.

## Model Classes

16 models in `lib/models/` with `fromMap()` / `toMap()` methods for SQLite serialization. Models are pure Dart classes with no external dependencies.

## Theme

`AppTheme` in `lib/core/theme/` defines light and dark themes with Teal primary color and consistent text/component styles.
