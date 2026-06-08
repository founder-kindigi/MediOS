# Setup Guide

## Prerequisites

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- For Web: modern browser (Chrome, Firefox, Edge)
- For Windows: Windows 10+
- For Android: Android Studio or command-line SDK
- For iOS: macOS with Xcode

## Installation

```bash
# Clone the repository
git clone https://github.com/founder-kindigi/MediOS.git
cd MediOS

# Install dependencies
flutter pub get

# Run on your platform
flutter run
```

## Web Setup

The web build requires a SQLite WASM worker:

```bash
# Install SQLite web worker
dart run sqflite_common_ffi_web:setup

# Build for production
flutter build web --release
```

The web build serves the PWA with offline SQLite support via `sqflite_common_ffi_web` and a SQLite WASM binary.

## Windows Setup

```bash
flutter build windows --release
```

The build output will be in `build/windows/runner/Release/`.

## Database

The app creates `pharmacy.db` on first launch in the app's documents directory. The database includes:

- **Default admin user:** admin / admin123
- **6 default categories:** Tablet, Capsule, Syrup, Injection, Ointment, Drop
- **Default store:** Main Store

### Seed Data

To import the scraped Pakistani medicine catalog:

```bash
# The seed data service checks on app launch and imports if the
# medicines table is empty. Seed data is loaded from:
#   tools/scraper/medicines_with_composition.json
```

## Barcode Scanning

The barcode scanner uses `mobile_scanner` package and requires camera permission:

- **Android:** Camera permission is requested at runtime
- **iOS:** Add `NSCameraUsageDescription` to Info.plist
- **Web:** Uses browser `getUserMedia()` API

## Biometric Authentication

Uses `local_auth` package. The biometric login checkbox appears on the login screen. Settings toggle enables/disables biometric login.

- **Android:** Fingerprint or face unlock
- **iOS:** FaceID or TouchID
- **Web/Windows:** Unavailable (checkbox hidden automatically)

## Push Notifications

Uses `flutter_local_notifications`. Notifications fire on app launch for:

- Low stock medicines (stock <= reorder level)
- Near-expiry medicines (expiring within 30 days)

Configure notification channels in `NotificationService.init()`.

## Database Import/Export

- **Export:** Settings screen → Export Database — copies the .db file and opens the share sheet
- **Import:** Settings screen → Import Database — uses file_picker to select a .db file, replaces current database (app restart required)

## Configuration

Settings can be adjusted in `lib/core/constants/app_constants.dart`:

```dart
static const String appName = 'MediOS';
static const String dbName = 'pharmacy.db';
static const int dbVersion = 7;
static const String defaultCurrency = '₨';
```

## Environment Variables

No environment variables required. All configuration is compile-time constants or runtime user settings.

## Troubleshooting

### Web: "sqlite3.wasm not found"
Run: `dart run sqflite_common_ffi_web:setup`

### sqflite errors on web
Run: `flutter clean && dart run sqflite_common_ffi_web:setup && flutter pub get`

### Imported database not reflecting
Restart the app after importing a database file.
