# MediOS — Full Codebase Audit Report

**Date:** 2026-06-09
**Scope:** All 13 feature modules + all core subsystems
**Files reviewed:** 90+

---

## Table of Contents

1. [Severity Legend](#severity-legend)
2. [🔴 Critical Findings](#-critical-findings)
3. [🟠 High Findings](#-high-findings)
4. [🔵 Low / Enhancement Findings](#-low--enhancement-findings)
5. [Module-by-Module Breakdown](#module-by-module-breakdown)
   - [Inventory](#1-inventory-module)
   - [Sales](#2-sales-module)
   - [Purchase Orders](#3-purchase-orders-module)
   - [Returns](#4-returns-module)
   - [Customer Orders](#5-customer-orders-module)
   - [Prescriptions](#6-prescriptions-module)
   - [Reports](#7-reports-module)
   - [Stores](#8-stores-module)
   - [Suppliers](#9-suppliers-module)
   - [Customers](#10-customers-module)
   - [Dashboard](#11-dashboard-module)
   - [Settings](#12-settings-module)
   - [Auth](#13-auth-module)
   - [Core Service Locator](#14-core-service-locator)
   - [Core Widgets](#15-core-widgets)
   - [Core Security](#16-core-security)
   - [Core Database](#17-core-database)
   - [Core Services](#18-core-services)
   - [Core Errors](#19-core-errors)
6. [Architecture-Wide Issues](#architecture-wide-issues)

---

## Severity Legend

| Severity | Meaning |
|----------|---------|
| **🔴 Critical** | Data loss, incorrect financials, security vulnerability, or app crash on normal use |
| **🟠 High** | Incorrect behavior, performance bottleneck, silent data corruption, security weakness |
| **🔵 Low** | Code quality, edge cases, UX polish, best practices |

---

## 🔴 Critical Findings

| # | Module | File:Line | Issue | Impact |
|---|--------|-----------|-------|--------|
| C1 | Inventory | `inventory_service.dart` | **Race condition in `updateStock`**: stock is decremented in-memory on `_medicines` list first, then written to DB. Concurrent updates from sales + returns + adjustments can interleave, producing incorrect final stock. No DB transaction isolation. | Incorrect stock counts — finances and reorder decisions based on wrong data |
| C2 | Sales | `sales_service.dart` | **`createSale` not atomic with stock decrement**: sale record is inserted, then `updateStock` is called separately. If the app crashes between the two, stock is deducted but sale is lost (or vice versa). | Financial records and inventory can permanently diverge |
| C3 | Reports | `reports_service.dart` (entire) | **25+ separate DB queries per report page load**: each of `getMonthlyRevenue` (12), `getDailySalesCount` (7), `getWeeklyRevenue` (7), `getSalesSummary` (4), and others runs sequential queries. | Page load takes seconds on real data; poor UX |
| C4 | Dashboard | `dashboard_service.dart:40-71` | **18 separate DB queries per dashboard load**: same pattern as Reports. Worst-perceived-performance page in the app. | Home screen is the slowest; fresh 18 queries every visit |
| C5 | Core Security | `input_validator.dart:9-31` | **`sanitizeSql()` is a broken keyword-stripper** that removes words like "SELECT", "DROP", "UNION" from input. Can be trivially bypassed (`SE/**/LECT`, `SelECT`) AND corrupts legitimate data (medicine named "Selectra" → "ra"). **The app already uses parameterized queries — this function creates false security.** | False sense of SQL injection protection; corrupts real data |

---

## 🟠 High Findings

### Inventory Module

| # | File:Line | Issue |
|---|-----------|-------|
| H1 | `inventory_service.dart` | Empty `medicine_name` logged in `_logTransaction` when `MedicineModel.name` is empty |
| H2 | `inventory_service.dart:deleteMedicine` | No FK check before delete — crashes if medicine is referenced by sale_items, purchase_order_items, etc. |
| H3 | `inventory_service.dart:addMedicine` | No duplicate-name check within same store — two medicines can have identical names |
| H4 | `inventory_service.dart:updateStock` | Negative stock possible (no `WHERE stock_quantity >= ?` guard) |
| H5 | `inventory_screen.dart` | `loadMedicines()` not awaited in initState — shimmer shows but error goes nowhere |
| H6 | `inventory_screen.dart` | Expired medicines not visually distinguished in list |

### Sales Module

| # | File:Line | Issue |
|---|-----------|-------|
| H7 | `sales_service.dart:createSale` | Sale + stock decrement not in a DB transaction |
| H8 | `new_sale_screen.dart` | Customer "Walk-in" always stored as customer_name even when customer ID is selected — `customerId` from selection is ignored if name is manually typed |
| H9 | `new_sale_screen.dart` | Coupon discount not recalculated if items change after coupon applied |
| H10 | `new_sale_screen.dart` | Dead `_discount` field — set but never read |
| H11 | `sales_screen.dart` | `updateStatus` not awaited — snackbar shown before DB write completes |

### Purchase Orders Module

| # | File:Line | Issue |
|---|-----------|-------|
| H12 | `purchase_order_service.dart:deleteOrder` | No status check — received POs can be deleted, **orphaning the stock** that was added to inventory |
| H13 | `purchase_order_service.dart:receiveOrder` | `updateStock` called with no error handling. If stock update fails, PO is marked received but stock not updated |
| H14 | `purchase_order_service.dart:getOrderById` | Returns `null` silently if order not found — caller may crash on null access |
| H15 | `purchase_order_service.dart:updateOrder` | `supplier.id` nullable in WHERE — silent no-op if null |

### Returns Module

| # | File:Line | Issue |
|---|-----------|-------|
| H16 | `return_service.dart:getReturns` | `INNER JOIN sale_items` and `INNER JOIN sales` — returns whose sale was deleted (`ON DELETE SET NULL`) are **invisible** and their stock is never restored |
| H17 | `return_service.dart:processReturn` | Stock restoration has `WHERE stock_quantity >= ?` guard but **no error rollback** — if stock UPDATE fails, the return is saved but stock is wrong |
| H18 | `return_service.dart:processReturn` | No duplicate-return check — same sale items can be returned multiple times, inflating refunds |
| H19 | `return_service.dart:getReturns` | Filters by `s.store_id` but uses `INNER JOIN` so orphaned returns (sale deleted) aren't attributed to any store |

### Customer Orders Module

| # | File:Line | Issue |
|---|-----------|-------|
| H20 | `order_service.dart:loadOrders` | N+1 query — loads orders, then loads items eagerly per order |
| H21 | `order_service.dart:updateStatus` | Silent error swallowing — status change success snackbar shown before DB write |
| H22 | `order_service.dart` | No `store_id` scope — `loadOrders` loads all stores' orders |

### Prescriptions Module

| # | File:Line | Issue |
|---|-----------|-------|
| H23 | `prescription_service.dart:loadPrescriptions` | N+1 query — loads prescriptions, then loads items per prescription |
| H24 | `prescription_service.dart` | No `store_id` filtering — prescriptions from all stores are visible regardless of current selection |
| H25 | `prescription_service.dart:updateStatus` | Silent error swallowing — success snackbar before DB write |

### Reports Module

| # | File:Line | Issue |
|---|-----------|-------|
| H26 | `reports_service.dart:17-36` | `getMonthlyRevenue` — 12 queries in loop (one per month). Single `GROUP BY` replaces all |
| H27 | `reports_service.dart:69-85` | `getSalesSummary` — 4 separate queries (today, week, month, total) |
| H28 | `reports_service.dart:118-135` | `getDailySalesCount` — N=7 queries in loop |
| H29 | `reports_service.dart:137-154` | `getWeeklyRevenue` — 7 queries in loop |
| H30 | `reports_service.dart:87-116` | `getInventoryStats` — 6 separate queries |
| H31 | `reports_screen.dart:44` | `inv.loadMedicines()` called but results never used — unnecessary full inventory reload |

### Stores Module

| # | File:Line | Issue |
|---|-----------|-------|
| H32 | `store_service.dart:71-73` | `updateStore` uses nullable `store.id` in WHERE — silent no-op if null |

### Suppliers Module

| # | File:Line | Issue |
|---|-----------|-------|
| H33 | `supplier_service.dart:35-36` | `updateSupplier` uses nullable `supplier.id` — silent no-op if null |
| H34 | `supplier_detail_screen.dart:25-31` | Loads ALL purchase orders then filters by name — full-table scan |
| H35 | `supplier_detail_screen.dart:29` | Filters by `supplierName` (string) not `supplierId` — name collisions show wrong orders |

### Customers Module

| # | File:Line | Issue |
|---|-----------|-------|
| H36 | `customer_service.dart:35-36` | `updateCustomer` uses nullable `customer.id` — silent no-op if null |
| H37 | `customer_detail_screen.dart:27-30` | Loads ALL sales then filters by customerId — full-table scan. Uses `customerId` (correct field) but still wasteful |

### Dashboard Module

| # | File:Line | Issue |
|---|-----------|-------|
| H38 | `dashboard_service.dart:73-88` | `_calcWeeklyRevenue` — 7 queries in loop |
| H39 | `dashboard_service.dart:99-119` | `getMonthlyRevenue` — 12 queries in loop (exact duplicate of Reports method) |
| H40 | `dashboard_service.dart:40-71` | No try-catch — any query failure silently shows zeroes |

### Settings Module

| # | File:Line | Issue |
|---|-----------|-------|
| H41 | `settings_service.dart:20-22` | `loadSettings()` called fire-and-forget in constructor — SharedPreferences read race |
| H42 | `settings_service.dart:181-193` | `clearAllData()` deletes `categories` despite dialog saying preserved; leaves `prescriptions` + `customer_orders` orphaned |
| H43 | `settings_screen.dart:464-468` | `removeCoupon()` not awaited before `_load()` — stale data read race |
| H44 | `settings_service.dart:63-93` | `importDatabase()` replaces file but never reopens DB connection — old data shown until restart |

### Auth Module

| # | File:Line | Issue |
|---|-----------|-------|
| H45 | `auth_service.dart:36,51` | `isRateLimited()` called twice per failed login — each call records an attempt. Effective rate limit: ~3 failures instead of 5. Lockout-triggering attempt shows "Invalid" not "Too many attempts" |
| H46 | `first_time_setup_screen.dart:222-230 + 139` | Password UI lists uppercase/lowercase/number/special requirements but `_validatePassword` only checks length ≥ 12 — form passes then service rejects |
| H47 | `biometric_auth_service.dart:56-63` | `enable()` empty catch — if storage fails, user thinks biometric is enabled but it wasn't saved |
| H48 | `auth_service.dart:68-94` | `BCrypt.hashpw('dummy_password', BCrypt.gensalt())` runs on EVERY login including successful ones — ~100ms wasted computation |

### Core Service Locator

| # | File:Line | Issue |
|---|-----------|-------|
| H49 | `service_locator.dart` | `AuthService` registered in GetIt AND passed as `ChangeNotifierProvider.value` in `main.dart:123` — **two different instances**, auth state may not sync |
| H50 | `service_locator.dart` | `RateLimiter` not injected into `AuthService` — `new RateLimiter()` inside `login()` creates a fresh instance each call, losing rate-limit state |

### Core Widgets

| # | File:Line | Issue |
|---|-----------|-------|
| H51 | `main_shell.dart:125,393` | `auth.logout()` called BEFORE navigation — if logout throws, user is stuck with no recovery |
| H52 | `app_drawer.dart:84-86` | Same pattern — `auth.logout()` before navigation |
| H53 | `error_handler.dart:14,28` | All non-AppError exceptions hardcoded as `ErrorType.database` — network errors, permission errors all mislabeled as DB errors |

### Core Security

| # | File:Line | Issue |
|---|-----------|-------|
| H54 | `input_validator.dart:34-54` | `sanitizeHtml()` regex-based sanitization is provably incomplete for XSS: `<svg onload=alert(1)>`, `&#106;avascript:`, etc. all bypass |
| H55 | `input_validator.dart:43-45` | Protocol stripping (`javascript:`, `data:`) is case-sensitive — `JavaScript:` bypasses |
| H56 | `secure_storage_service.dart:10-11,123-124` | AES-256 encryption key and IV stored in same secure storage with guessable key names — encryption provides zero additional security |

### Core Database

| # | File:Line | Issue |
|---|-----------|-------|
| H57 | `db_io.dart:74-83` / `db_web.dart:74-83` | Migration v8 reads ALL password hashes into memory and re-hashes with BCrypt — on web, BCrypt in WASM causes severe jank |
| H58 | `db_io.dart:183-201` | `getCount()` and `getSum()` use string interpolation for `$table`, `$column`, and `$where` — if any caller passes user input, this is SQL injection |

### Core Services

| # | File:Line | Issue |
|---|-----------|-------|
| H59 | `invoice_service.dart:44` | `sale.items` not null-checked — crashes at runtime if items is null |
| H60 | `invoice_service.dart:75` | Tax calculated on `totalAmount` but should be on `totalAmount - discount` for correct financial math |
| H61 | `seed_data_service.dart:41-43` | Empty catch block silently swallows ALL seed data errors — malformed JSON or DB corruption is invisible |

---

## 🔵 Low / Enhancement Findings

### Inventory (8)

| # | File:Line | Issue |
|---|-----------|-------|
| L1 | `inventory_service.dart` | No pagination for large datasets |
| L2 | `inventory_screen.dart` | Search is client-side only — no DB query |
| L3 | `inventory_screen.dart` | Pull-to-refresh doesn't show loading indicator |
| L4 | `inventory_service.dart` | `loadMedicines()` called fire-and-forget |
| L5 | `stock_adjustment_screen.dart` | No reason/notes required for adjustment |
| L6 | `expiry_management_screen.dart` | No bulk expiry date update |
| L7 | `barcode_scan_screen.dart` | No camera permission error handling |
| L8 | `transaction_history_screen.dart` | No filter by transaction type |

### Sales (4)

| # | File:Line | Issue |
|---|-----------|-------|
| L9 | `new_sale_screen.dart` | Out-of-stock items selectable (no `stock_quantity > 0` guard in UI) |
| L10 | `new_sale_screen.dart` | `_discount` field declared, set, but never read — dead code |
| L11 | `sales_screen.dart` | No total sales row in list |
| L12 | `sales_screen.dart` | `loadSales()` fire-and-forget in initState |

### Purchase Orders (4)

| # | File:Line | Issue |
|---|-----------|-------|
| L13 | `purchase_orders_screen.dart` | `loadOrders()` fire-and-forget in initState |
| L14 | `new_purchase_order_screen.dart` | No supplier credit limit check |
| L15 | `purchase_order_service.dart` | No PO number validation for uniqueness (DB has UNIQUE constraint) |
| L16 | `purchase_order_service.dart` | `updateOrder` return value discarded |

### Returns (4)

| # | File:Line | Issue |
|---|-----------|-------|
| L17 | `return_service.dart` | `processReturn` not in a DB transaction |
| L18 | `return_service.dart` | No return reason categorization |
| L19 | `return_service.dart` | `loadReturns()` fire-and-forget |
| L20 | `new_return_screen.dart` | No loading state during return processing |

### Customer Orders (5)

| # | File:Line | Issue |
|---|-----------|-------|
| L21 | `order_service.dart` | `loadOrders()` fire-and-forget |
| L22 | `new_order_screen.dart` | No stock availability check before order |
| L23 | `order_list_screen.dart` | No status filter tabs |
| L24 | `order_service.dart` | No pagination |
| L25 | `order_service.dart` | No `store_id` scope |

### Prescriptions (5)

| # | File:Line | Issue |
|---|-----------|-------|
| L26 | `prescription_service.dart` | `loadPrescriptions()` fire-and-forget |
| L27 | `new_prescription_screen.dart` | No medicine search autocomplete |
| L28 | `prescription_list_screen.dart` | No status filter tabs |
| L29 | `prescription_service.dart` | No expiry/age limit on prescriptions |
| L30 | `prescription_service.dart` | No `store_id` scope |

### Reports (3)

| # | File:Line | Issue |
|---|-----------|-------|
| L31 | `reports_screen.dart:56-59` | Empty `catch (e) {}` — errors silently swallowed |
| L32 | `reports_service.dart` | No date range selector — always current year |
| L33 | `reports_service.dart` | No caching — fresh 25+ queries every visit |

### Stores (4)

| # | File:Line | Issue |
|---|-----------|-------|
| L34 | `store_list_screen.dart:113-121` | 6 fire-and-forget reloads on store switch |
| L35 | N/A | No `deleteStore` method |
| L36 | `store_list_screen.dart` | No edit/update UI |
| L37 | `store_service.dart:28-32` | `selectStore(id)` no validation ID exists in `_stores` |

### Suppliers (3)

| # | File:Line | Issue |
|---|-----------|-------|
| L38 | `suppliers_screen.dart:189` | `supplier.id!` null assertion risk on delete |
| L39 | `supplier_service.dart:41-43` | `deleteSupplier` no FK-side effect warning (POs lose supplier ref) |
| L40 | `suppliers_screen.dart:119-176` | No unsaved-changes confirmation |

### Customers (2)

| # | File:Line | Issue |
|---|-----------|-------|
| L41 | `customer_detail_screen.dart:31` | `setState` without `mounted` check after await |
| L42 | `customers_screen.dart:186` | `customer.id!` null assertion risk on delete |

### Dashboard (4)

| # | File:Line | Issue |
|---|-----------|-------|
| L43 | `dashboard_screen.dart:26` | `loadDashboard()` fire-and-forget in initState |
| L44 | `dashboard_screen.dart:305` | Magic string route `'${AppRouter.inventory}/add'` |
| L45 | `admin_users_screen.dart:72-77` | Field `passwordHash` stores plaintext before hashing (misleading name) |
| L46 | `admin_users_screen.dart` | No delete/deactivate user |

### Settings (4)

| # | File:Line | Issue |
|---|-----------|-------|
| L47 | `settings_service.dart:207-240` | Coupons in SharedPreferences as unencrypted JSON, no store-scoping |
| L48 | `settings_service.dart:126-168` | CSV export without BOM — Excel may garble UTF-8 |
| L49 | `settings_service.dart:64-66` | `kIsWeb` throws UnsupportedError — no graceful degradation |
| L50 | `settings_screen.dart:422` | Snackbar fires before `_load()` completes |

### Auth (5)

| # | File:Line | Issue |
|---|-----------|-------|
| L51 | `biometric_auth_service.dart:10` | `SecureStorageService` created directly (not via DI) |
| L52 | `first_time_setup_screen.dart:113-157` | Validation duplicated from shared `InputValidator`/`PasswordPolicy` |
| L53 | `first_time_setup_screen.dart:32` | `_passwordController.addListener` never removed |
| L54 | `auth_service.dart:51` | `rateLimiter.isRateLimited()` with discarded return — confusing semantics |
| L55 | `input_validator.dart:153` | `isValidFullName` rejects accented characters — not i18n-friendly |

### Core Widgets & Utils (9)

| # | File:Line | Issue |
|---|-----------|-------|
| L56 | `main_shell.dart:52` | Hardcoded `5` in `List.generate(5, ...)` instead of `_tabs.length` |
| L57 | `main_shell.dart:316` | Empty `onPressed: () {}` — dead placeholder |
| L58 | `app_drawer.dart:56` | Reports listed in both drawer AND `_MoreTab` — duplicate navigation |
| L59 | `app_snackbar.dart:28-52` | No `mounted` check — can throw if called during disposal |
| L60 | `helpers.dart:22,28` | `substring(5)` on milliseconds timestamp — fragile uniqueness |
| L61 | `validators.dart:13` | Email regex `{2,4}` TLD too restrictive (`.photography` rejected) |
| L62 | `validators.dart:24` | Phone regex `^[\d\-+() ]{7,15}$` — `()-()----` passes |
| L63 | `app_error.dart:14` | `dynamic originalError` should be `Object?` |
| L64 | `error_handler.dart:6-32` | Code duplication between `tryOrThrow` and `tryOrThrowVoid` |

### Core Services (6)

| # | File:Line | Issue |
|---|-----------|-------|
| L65 | `invoice_service.dart:112-113` | Currency hardcoded to `Rs` |
| L66 | `invoice_service.dart:116-118` | Manual date formatting instead of `DateFormat` |
| L67 | `notification_service.dart:47,56` | Notification IDs hardcoded integers (1, 2) |
| L68 | `seed_data_service.dart:19` | Entire JSON file loaded into memory (no streaming) |
| L69 | `secure_storage_service.dart:27,37` | `initialize()` called on every `store()`/`retrieve()` |
| L70 | `theme_provider.dart:18` | `SharedPreferences.getInstance()` on every `setMode()` |
| L71 | `theme_provider.dart:12` | `notifyListeners()` called even when mode hasn't changed |
| L72 | `db_web.dart:110-115` | Seed default store named "Main Pharmacy" vs migration "Main Store" |
| L73 | `db_stub.dart:17-23` | `UnsupportedError` with empty string — no debugging context |

---

## Architecture-Wide Issues

| # | Pattern | Affected Modules | Description |
|---|---------|------------------|-------------|
| A1 | **`updateStatus` not awaited** | Sales, Purchase Orders, Returns, Orders, Prescriptions | Every screen calls `service.updateStatus(...)` without `await`. Success snackbar appears before DB write completes. Silent error loss. |
| A2 | **N+1 query loading items** | Orders, Prescriptions | `loadX()` queries the list, then iterates per-record to load items. Single JOIN would replace N+1. |
| A3 | **No store-scoping** | Orders, Prescriptions, Coupons | Records from all stores visible regardless of selected store. Data leak across locations. |
| A4 | **Stock operations not atomic** | Sales, Returns, Purchase Orders | Stock mutation is a separate call after the transaction record. Crash between leaves inconsistent state. |
| A5 | **Loop-per-item queries** | Reports, Dashboard | `getMonthlyRevenue` (12×), `getWeeklyRevenue` (7×), `getDailySalesCount` (7×), `getInventoryStats` (6×) — all should be single `GROUP BY` queries |
| A6 | **fire-and-forget in initState** | Every screen | `loadX()` called without `await` in `initState` — errors never propagate. Works because of `watch()`/`notifyListeners()`, but errors are invisible. |
| A7 | **Nullable `id` in WHERE clause** | Stores, Suppliers, Customers | `updateX(model)` uses `WHERE id = ?` with `[model.id]` — if `id` is null, update silently succeeds with 0 rows affected. |
| A8 | **DI bypass** | Auth (RateLimiter, BiometricAuth), Notifications, SeedData | Core services instantiated with `new` instead of resolved from DI container. Multiple instances possible. |
| A9 | **No DB-level transactions** | Sales + stock, Returns + stock restore | Multi-table writes not wrapped in `db.transaction()`. |
| A10 | **No pagination anywhere** | Every list screen | All queries load every row. Datasets >1000 rows will cause memory pressure and jank. |

---

## Stats Summary

| Severity | Count |
|----------|-------|
| **🔴 Critical** | 5 |
| **🟠 High** | 61 |
| **🔵 Low** | 73 |
| **Architecture-Wide** | 10 |
| **Total** | **149** |
