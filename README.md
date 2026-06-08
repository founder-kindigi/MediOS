# MediOS - Pharmacy Management System

Cross-platform pharmacy management system built with Flutter, SQLite, and Provider state management. Local-first architecture with support for Android, iOS, Web, and Windows.

## Features

- **Inventory Management** — medicines, categories, stock tracking, barcode scanning
- **Sales & Billing** — retail/wholesale pricing, discounts, tax, 80mm PDF invoices
- **Supplier Management** — supplier records, purchase orders, order fulfillment
- **Customer Management** — customer profiles, sales history
- **User Authentication** — login/logout, admin/pharmacist roles, biometric auth (fingerprint/FaceID)
- **Dashboard & Reports** — monthly revenue, top medicines, sales by payment method, daily/weekly summaries, inventory stats
- **Returns Management** — return processing with refund tracking
- **Multi-store Support** — create and manage multiple store locations
- **Prescriptions** — patient prescriptions with dosage/frequency/duration, create sale from prescription
- **Customer Orders** — order management with fulfill/cancel workflow
- **Data Sync** — database import/export, last sync timestamp
- **Push Notifications** — low stock and expiry alerts on app launch
- **Invoice Printing** — 80mm thermal printer format PDF invoices

## Architecture

```
lib/
├── core/
│   ├── constants/        — App constants, theme data
│   ├── database/         — SQLite database helper (conditional imports)
│   ├── services/         — Seed data, notifications, invoice generation
│   ├── theme/            — AppTheme with light/dark mode
│   └── utils/            — helpers.dart (formatCurrency, formatDate, etc.)
├── features/
│   ├── auth/             — Login, biometric auth, user management
│   ├── inventory/        — Medicines, categories, stock, barcode scanning
│   ├── sales/            — Point of sale, billing, invoice
│   ├── suppliers/        — Supplier records
│   ├── customers/        — Customer management
│   ├── dashboard/        — Dashboard home screen
│   ├── purchases/        — Purchase orders
│   ├── reports/          — Reports and analytics
│   ├── returns/          — Return management
│   ├── stores/           — Multi-store management
│   ├── prescriptions/    — Prescription management
│   ├── orders/           — Customer orders
│   └── settings/         — App settings, sync, coupons, tax
├── models/               — 16 data models
├── widgets/              — Common widgets (AppDrawer, SearchBar, LoadingOverlay)
└── main.dart             — App entry point with routing
```

## Platforms

| Platform | Status |
|----------|--------|
| Android  | ✅ |
| iOS      | ✅ |
| Web      | ✅ (SQLite via sqflite_common_ffi_web) |
| Windows  | ✅ |

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run on your platform
flutter run

# Build for web
flutter build web --release

# Build for Windows
flutter build windows --release
```

## Default Login

- **Username:** `admin`
- **Password:** `admin123`

## Database

Local SQLite database (`pharmacy.db`) with auto-migration (v1→v7). Schema includes 17 tables covering all features. Seed data includes default admin user, 6 default categories, and the Main Store.

## Testing

```bash
# Run all tests
flutter test

# Run service tests
flutter test test/services/

# Run model tests
flutter test test/models/
```

- 62 service tests across all 13 feature services
- 9 model unit tests covering all 16 models
- In-memory SQLite via sqflite_common_ffi for isolated testing
- `test/test_helper.dart` provides `createAndSetTestDb()` / `resetTestDb()` pattern

## Medicine Data

The project includes a Python scraper (`tools/scraper/scrape_dawaai.py`) that scrapes 19,060 products from dawaai.pk, with generic names enriched via drugsinfo.pk API (18,451 mapped, 96.8% coverage).

## Tech Stack

- **Framework:** Flutter (single codebase)
- **State Management:** Provider
- **Database:** SQLite (sqflite_common_ffi + sqflite_common_ffi_web)
- **Camera/Barcode:** mobile_scanner
- **Biometrics:** local_auth
- **Notifications:** flutter_local_notifications
- **File Picker:** file_picker
- **Share/Export:** share_plus
- **Invoicing:** pdf + printing
