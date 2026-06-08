# Development Guide

## Project Structure

```
lib/
├── core/
│   ├── constants/         — AppConstants, route constants
│   ├── database/          — DatabaseHelper + platform implementations
│   ├── services/          — SeedDataService, NotificationService, InvoiceService
│   ├── theme/             — AppTheme (light + dark)
│   └── utils/             — helpers.dart (formatCurrency, formatDate, bill/order number generators)
├── features/
│   └── {feature_name}/
│       ├── screens/       — UI screens per feature
│       └── services/      — ChangeNotifier services
├── models/                — 16 data models
├── widgets/               — Shared widgets (AppDrawer, SearchBarWidget, LoadingOverlay)
└── main.dart              — App entry, routing, Provider setup
```

## Adding a New Feature

1. Create `lib/features/{feature}/screens/` and `lib/features/{feature}/services/`
2. Create a service class extending `ChangeNotifier` with business logic
3. Create screen files that consume the service via Provider
4. Add route constant and screen registration to `main.dart`
5. Add drawer entry in `AppDrawer`
6. Add Provider registration in the `MultiProvider` tree in `main.dart`

## Database Migrations

The database uses numbered versions (1–7). To add a migration:

1. Increment `AppConstants.dbVersion`
2. Add an `ALTER TABLE` or `CREATE TABLE` statement in `_onUpgrade()` in both `db_io.dart` and `db_web.dart`
3. Add the new table creation to `_createTables()` in both files
4. Add the new table to `test/test_helper.dart` `_createTables()`
5. If the new table needs seed data, add it to `_seedDefaultData()` in `db_io.dart`

## Testing

### Test Pattern

All service tests follow this pattern:

```dart
late Database db;
late MyService service;

setUp(() async {
  db = await createAndSetTestDb();
  service = MyService();
});

tearDown(() async {
  await db.close();
  resetTestDb();
});
```

### test_helper.dart

`test/test_helper.dart` exports:
- `createTestDb()` — creates an in-memory SQLite database with all tables
- `createAndSetTestDb()` — creates DB + sets it on DatabaseHelper + seeds default data
- `resetTestDb()` — clears the test database reference

### Writing Tests

```dart
test('my test', () async {
  await service.doSomething();
  expect(service.someValue, expectedValue);
});
```

### Running Tests

```bash
# All tests
flutter test

# Single test file
flutter test test/services/auth_service_test.dart

# Model tests
flutter test test/models/model_tests.dart
```

## Medicine Scraping

Tools are in `tools/scraper/`:

- **scrape_dawaai.py** — scrapes 19k+ products from dawaai.pk A-Z pages
- **scrape_generic.py** — enriches products with generic names via drugsinfo.pk API
- **medicines_with_composition.json** — final output imported as seed data

## Code Style

- No comments in production code unless asked
- Feature-first folder structure
- Services are ChangeNotifiers with Provider
- Models have `fromMap`/`toMap` for SQLite serialization
- Routes use named constants in main.dart

## Conditional Imports

The database layer uses Dart conditional imports:

```dart
export 'src/db_stub.dart'
  if (dart.library.io) 'src/db_io.dart'
  if (dart.library.js_util) 'src/db_web.dart';
```

This ensures the correct SQLite implementation is compiled for each platform without runtime checks.

## Build Commands

```bash
# Analyze
flutter analyze

# Web release
flutter build web --release

# Windows release
flutter build windows --release

# APK
flutter build apk --release
```
