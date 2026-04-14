# M.S. Group Properties - Setup & Build Guide

## Project Overview
- **Project Name:** M.S. Group Properties
- **Type:** Mobile Application (Android)
- **Description:** Plot booking and customer management system
- **Version:** 1.0.0+1
- **Theme:** Orange (#FF6600) & White

---

## Environment Setup

### Required Software

#### 1. Flutter SDK
- **Location:** `D:\flutter_sdk`
- **Executable:** `D:\flutter_sdk\bin\flutter.bat`
- **Version:** Flutter 3.24.5

#### 2. Java Development Kit (JDK)
- **JAVA_HOME:** `C:\Program Files\Java\jdk-22`
- **Required:** Yes (for Android builds)

#### 3. Android SDK
- Usually bundled with Flutter or requires separate installation
- Location varies based on installation

---

## Project Structure

```
ms_group_properties/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app.dart                  # Main navigation
│   ├── config/
│   │   ├── theme.dart           # Orange & White theme
│   │   └── constants.dart        # App constants
│   ├── models/                  # Data models
│   │   ├── customer_model.dart
│   │   ├── nominee_model.dart
│   │   ├── id_proof_model.dart
│   │   ├── booking_model.dart
│   │   ├── payment_model.dart
│   │   └── quotation_model.dart
│   ├── services/                # Business logic
│   │   ├── database_service.dart
│   │   ├── receipt_pdf_service.dart
│   │   ├── booking_pdf_service.dart
│   │   └── quotation_pdf_service.dart
│   ├── screens/                 # UI screens
│   │   ├── dashboard/
│   │   ├── customer/
│   │   ├── booking/
│   │   ├── payment/
│   │   ├── quotation/
│   │   ├── ledger/
│   │   ├── customers/           # Wrapper screens
│   │   │   └── customers_wrapper_screen.dart
│   │   └── finance/            # Wrapper screens
│   │       └── finance_wrapper_screen.dart
│   ├── services/
│   │   ├── ledger_image_service.dart  # Image handling for proof
│   └── utils/                   # Utilities
│       ├── formatters.dart
│       ├── validators.dart
│       ├── calculator.dart
│       └── date_utils.dart
├── assets/                      # Static assets
├── android/                     # Android platform files
├── pubspec.yaml                 # Dependencies
└── install.md                   # This file
```

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter | SDK | Core framework |
| cupertino_icons | ^1.0.8 | iOS icons |
| sqflite | ^2.4.1 | SQLite database |
| path_provider | ^2.1.5 | File system access |
| pdf | ^3.11.1 | PDF generation |
| printing | ^5.13.3 | Print/share PDFs |
| share_plus | ^10.1.4 | Share functionality |
| image_picker | ^1.1.2 | Image selection |
| intl | ^0.20.1 | Internationalization |
| path | ^1.9.0 | Path utilities |
| flutter_slidable | ^3.1.1 | Swipe actions |
| signature | ^5.5.0 | Signature capture |
| flutter_image_compress | ^2.3.0 | Image compression for WebP |
| uuid | ^4.5.1 | Unique filename generation |

---

## Build Commands

### Debug Build (Recommended for Development)
```powershell
cd Z:\formv5\ms_group_properties
[Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Java\jdk-22', 'Process')
D:\flutter_sdk\bin\flutter.bat build apk --debug
```

### Single Line Command
```powershell
[Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Java\jdk-22', 'Process'); cd Z:\formv5\ms_group_properties; D:\flutter_sdk\bin\flutter.bat build apk --debug
```

### Release Build (For Production)
```powershell
[Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Java\jdk-22', 'Process'); cd Z:\formv5\ms_group_properties; D:\flutter_sdk\bin\flutter.bat build apk --release
```

### Clean & Rebuild
```powershell
[Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Java\jdk-22', 'Process'); cd Z:\formv5\ms_group_properties; D:\flutter_sdk\bin\flutter.bat clean; D:\flutter_sdk\bin\flutter.bat pub get; D:\flutter_sdk\bin\flutter.bat build apk --debug
```

---

## Build Output

| Build Type | Location |
|------------|----------|
| Debug APK | `build\app\outputs\flutter-apk\app-debug.apk` |
| Release APK | `build\app\outputs\flutter-apk\app-release.apk` |
| Generated AAB | `build\app\outputs\bundle\app-release.aab` |

---

## App Features

### 1. Dashboard
- Overview statistics (Customers, Bookings, Payments, Quotations)
- Financial summary with collection rate
- Quick actions for common tasks
- Recent activity feed

### 2. Customer Management
- Add/Edit/Delete customers
- Customer details with KYC info
- Nominee management
- Booking history with payment progress
- Search functionality

### 3. Booking Management
- Create plot bookings
- Auto-calculation of dimensions & pricing
- EMI calculation
- Payment terms configuration

### 4. Payment Tracking
- Record payments (Token, Down Payment, EMI, Final Payment)
- Multiple payment modes (Cash, Bank Transfer, Cheque, UPI, etc.)
- Receipt generation with PDF
- Search and filter by payment type

### 5. Quotation System
- Create quotations for customers
- Auto-calculation of pricing
- Validity period tracking
- Status management (Pending, Accepted, Expired)
- PDF generation

### 6. Ledger Management
- Party management (Debtors/Creditors)
- Track "You Gave" and "You Took" transactions
- Proof image attachments (max 4 per transaction)
- Balance calculation per party
- PDF statement generation

---

## Theme Configuration

### Color Palette
- **Primary:** #FF6600 (Orange)
- **Primary Dark:** #E55A00
- **Primary Light:** #FF8533
- **Background:** #F8F9FA (Light Grey)
- **Card:** #FFFFFF (White)
- **Text Primary:** #212121
- **Text Secondary:** #757575

### Theme Components
- Material 3 design
- Custom TabBar styling
- Enhanced Navigation Bar
- Elevated cards with shadows
- Consistent typography hierarchy

---

## Common Issues & Solutions

### Issue: JAVA_HOME not set
**Error:** `JAVA_HOME is set to an invalid directory`
**Solution:** Set JAVA_HOME before running Flutter commands:
```powershell
[Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Java\jdk-22', 'Process')
```

### Issue: Build fails with dependency errors
**Solution:** Run pub get first:
```powershell
D:\flutter_sdk\bin\flutter.bat pub get
```

### Issue: Gradle build timeout
**Solution:** Clean and rebuild:
```powershell
D:\flutter_sdk\bin\flutter.bat clean
D:\flutter_sdk\bin\flutter.bat build apk --debug
```

---

## Development Workflow

1. **Clone repository**
2. **Install dependencies:** `flutter pub get`
3. **Run in debug mode:** `flutter run`
4. **Build debug APK:** `flutter build apk --debug`
5. **Build release APK:** `flutter build apk --release`

---

## Git Information
- **Branch:** main
- **Last Commit:** view mode for payment and booking

---

## UI Overflow Fixes & View Mode

### Dashboard Screen
- Stats grid: Responsive `childAspectRatio` using `MediaQuery` (1.4 for wide, 1.2 for narrow)
- Stat cards: Reduced padding to 12px, icon size to 20px, font sizes (28→24, 11→10)
- Activity items: Wrapped amount in `Flexible`, added text overflow protection

### Payment List Screen
- Customer name: Added `maxLines: 1` + `overflow: ellipsis`
- Amount column: Wrapped in `Flexible` with `overflow: ellipsis`
- Plot/Payment type: Changed to `Wrap` widget with responsive spacing

### Add Payment Screen - View Mode
- Clicking payment shows view-only mode (not edit form)
- Read-only display: Booking info, Payment details, Receipt
- Actions: Print PDF, Share PDF, Delete Payment

### Booking Form Screen - View Mode
- Clicking booking shows view-only mode (not edit form)
- Read-only display: Customer info, Plot details, Dimensions, Payment terms, Dates, Remarks
- Actions: Print booking form, Share booking form, Delete Booking

---

## Bottom Navigation Structure

### Current Structure (3 Main Tabs with Segmented Control)
| Tab | Contains | Internal Tabs |
|-----|----------|---------------|
| Dashboard | Dashboard | None |
| Customers | Customers + Bookings | Segmented Control |
| Finance | Payments + Quotations + Ledger | Segmented Control |

### Visual Layout
```
┌─────────────────────────────────────────────────┐
│  [Dashboard]  [Customers]  [Finance]             │ ← Main Nav (bottom)
├─────────────────────────────────────────────────┤
│  [ Customers │ Bookings ]                        │ ← Segmented Control (top)
│  [Search.................................]        │
│  [All] [Active] [Completed]                    │ ← Filter Chips (Bookings)
│  Content...                                     │
└─────────────────────────────────────────────────┘
```

### Wrapper Screens
| Screen | File | Purpose |
|--------|------|---------|
| CustomersWrapper | `screens/customers/customers_wrapper_screen.dart` | Hosts CustomerList + BookingList with SegmentedButton |
| FinanceWrapper | `screens/finance/finance_wrapper_screen.dart` | Hosts PaymentList + QuotationList + LedgerDashboard with SegmentedButton |

### inStandaloneMode Parameter
All list screens support `inStandaloneMode` parameter:
- `inStandaloneMode: true` (default) - Full Scaffold with AppBar, used for direct navigation
- `inStandaloneMode: false` - Content only, used inside wrapper screens

### Filter Chips
| Screen | Filter Options |
|--------|---------------|
| Bookings | All, Active, Completed |
| Payments | All, Token, Down, EMI |
| Ledger | All, Debtors, Creditors |

### Navigation Control
- `MainNavigationState` in `app.dart` provides methods to switch tabs
- `switchToCustomersTab()`, `switchToBookingsTab()`, `switchToPaymentsTab()`, `switchToQuotationsTab()`, `switchToLedgerTab()`
- Dashboard stat cards use these methods to navigate to correct tab/sub-tab

---

## Ledger Proof Images

### Features
- Attach up to 4 proof images per transaction
- Capture from camera or select from gallery
- Images resized to 1200px width
- Stored as WebP format for smaller file size
- Full screen viewer with zoom/pan
- Swipe between multiple images

### Image Storage
- Location: `{app_docs}/ledger_proofs/`
- Format: WebP (lossless)
- Naming: UUID-based for uniqueness
- Cleanup: Auto-deleted when transaction deleted

### Database Schema
```sql
ledger_transaction (
  ...
  proof_images TEXT  -- JSON array of file paths
)
```

---

## Contact & Support
For issues or questions, refer to the project documentation or contact the development team.
