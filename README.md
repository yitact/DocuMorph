# DocuMorph 📄✨

[![Flutter Version](https://img.shields.io/badge/Flutter-3.3.0%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3.0%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20Android-4E86E4)](#prerequisites)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Architecture](https://img.shields.io/badge/Architecture-Offline--First%20%2B%20Zero--Knowledge-green)](#architecture)

> **Scan reality. Extract structure.**  
> An offline-first mobile document scanner, multimodal financial parser, and expense intelligence suite built with Flutter.

---

## 🌟 Overview

**DocuMorph** bridges physical documents and structured digital data. It combines on-device machine learning OCR, 4-point homography perspective warping, structured regex and multimodal AI parsers, local NoSQL persistence, financial analytics, CPA-ready tax exports, and client-side zero-knowledge encrypted cloud backups.

---

## 🚀 Key Features

* **📷 Multi-Modal Capture & OCR:** High-resolution on-device OCR powered by Google ML Kit, real-time QR code/barcode scanning, and multi-page batch scanning to searchable PDFs.
* **📐 Interactive Polygon Perspective Warping:** Homography-based 4-point corner pinning to flatten, crop, and normalize distorted document photos.
* **🧠 Structured Parsing (JSON / CSV):**
  * *Offline Fast Path:* Rule-based regex parser extracting vendors, dates, invoice numbers, tax, line items, and totals.
  * *Multimodal Cloud AI:* Gemini Vision parser generating strict JSON schemas for complex receipts.
* **🏷️ Automated Expense Tagging:** On-device keyword taxonomy engine categorizing receipts (*Meals & Dining*, *Groceries*, *Travel*, *Office & Tech*, *Utilities*, *Healthcare*, etc.).
* **💾 Offline-First Storage & Search:** Zero-latency Hive NoSQL storage with full-text search across titles, OCR text, and vendor metadata.
* **📊 Analytics & Tax Statement Generation:** Interactive monthly spending bar charts, vendor distribution pie charts using `fl_chart`, and formal Schedule C CPA-ready PDF statement exports.
* **🛡️ Smart Financial Protections:** Duplicate receipt detection, recurring subscription cadence analysis, and monthly category budget threshold notifications.
* **🔒 Enterprise-Grade Security:** Biometric authentication (Face ID / Touch ID / Fingerprint) with OS fallback and auto-locking background lifecycle management.
* **☁️ Zero-Knowledge Cloud Sync:** Client-side AES-256-GCM encryption before syncing to Firebase Firestore and Firebase Storage.
* **💳 Subscription Ready:** RevenueCat integration for Monthly and Annual Pro tier gating.

---

## 🏗️ Architecture

```text
DocuMorph Application Architecture
├── 📷 Capture Engine       -> Google ML Kit OCR, mobile_scanner, image_picker
├── 📐 Geometry             -> flutter_perspective_crop (Homography Warping)
├── 🧠 Parsing Pipeline     -> Regex Parser + Gemini 1.5 Flash Multimodal AI
├── 💾 Storage Layer        -> Hive NoSQL (Offline-first local database)
├── 📊 Analytics & Reports  -> fl_chart, pdf, printing, intl
├── 🛡️ Financial Guards     -> Duplicate Engine, Recurring Detector, Budget Alerts
├── 🔒 Security             -> local_auth (Biometrics), AppLifecycleState Auto-Lock
├── ☁️ Cloud Sync           -> Firebase Firestore & Storage + Client-Side AES-256
└── 💳 In-App Purchases     -> RevenueCat (purchases_flutter)

  Here is a complete, production-ready `README.md` formatted for your repository at **[yitact/DocuMorph](https://github.com/yitact/DocuMorph)**.

Create a file named `README.md` in the root of your project directory and paste the content below:

```markdown
# DocuMorph 📄✨

[![Flutter Version](https://img.shields.io/badge/Flutter-3.3.0%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3.0%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20Android-4E86E4)](#prerequisites)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Architecture](https://img.shields.io/badge/Architecture-Offline--First%20%2B%20Zero--Knowledge-green)](#architecture)

> **Scan reality. Extract structure.**  
> An offline-first mobile document scanner, multimodal financial parser, and expense intelligence suite built with Flutter.

---

## 🌟 Overview

**DocuMorph** bridges physical documents and structured digital data. It combines on-device machine learning OCR, 4-point homography perspective warping, structured regex and multimodal AI parsers, local NoSQL persistence, financial analytics, CPA-ready tax exports, and client-side zero-knowledge encrypted cloud backups.

---

## 🚀 Key Features

* **📷 Multi-Modal Capture & OCR:** High-resolution on-device OCR powered by Google ML Kit, real-time QR code/barcode scanning, and multi-page batch scanning to searchable PDFs.
* **📐 Interactive Polygon Perspective Warping:** Homography-based 4-point corner pinning to flatten, crop, and normalize distorted document photos.
* **🧠 Structured Parsing (JSON / CSV):**
  * *Offline Fast Path:* Rule-based regex parser extracting vendors, dates, invoice numbers, tax, line items, and totals.
  * *Multimodal Cloud AI:* Gemini Vision parser generating strict JSON schemas for complex receipts.
* **🏷️ Automated Expense Tagging:** On-device keyword taxonomy engine categorizing receipts (*Meals & Dining*, *Groceries*, *Travel*, *Office & Tech*, *Utilities*, *Healthcare*, etc.).
* **💾 Offline-First Storage & Search:** Zero-latency Hive NoSQL storage with full-text search across titles, OCR text, and vendor metadata.
* **📊 Analytics & Tax Statement Generation:** Interactive monthly spending bar charts, vendor distribution pie charts using `fl_chart`, and formal Schedule C CPA-ready PDF statement exports.
* **🛡️ Smart Financial Protections:** Duplicate receipt detection, recurring subscription cadence analysis, and monthly category budget threshold notifications.
* **🔒 Enterprise-Grade Security:** Biometric authentication (Face ID / Touch ID / Fingerprint) with OS fallback and auto-locking background lifecycle management.
* **☁️ Zero-Knowledge Cloud Sync:** Client-side AES-256-GCM encryption before syncing to Firebase Firestore and Firebase Storage.
* **💳 Subscription Ready:** RevenueCat integration for Monthly and Annual Pro tier gating.

---

## 🏗️ Architecture

```text
DocuMorph Application Architecture
├── 📷 Capture Engine       -> Google ML Kit OCR, mobile_scanner, image_picker
├── 📐 Geometry             -> flutter_perspective_crop (Homography Warping)
├── 🧠 Parsing Pipeline     -> Regex Parser + Gemini 1.5 Flash Multimodal AI
├── 💾 Storage Layer        -> Hive NoSQL (Offline-first local database)
├── 📊 Analytics & Reports  -> fl_chart, pdf, printing, intl
├── 🛡️ Financial Guards     -> Duplicate Engine, Recurring Detector, Budget Alerts
├── 🔒 Security             -> local_auth (Biometrics), AppLifecycleState Auto-Lock
├── ☁️ Cloud Sync           -> Firebase Firestore & Storage + Client-Side AES-256
└── 💳 In-App Purchases     -> RevenueCat (purchases_flutter)

```

---

## 📂 Project Structure

```text
lib/
├── main.dart                                # App entry point & lifecycle observer
├── models/
│   ├── stored_document.dart                 # Hive storage schema
│   └── parsed_document.dart                 # Receipt, invoice & line item models
├── screens/
│   ├── perspective_editor.dart              # Interactive 4-point polygon crop view
│   ├── qr_scanner_screen.dart               # Real-time barcode & QR scanner
│   ├── batch_scanner_sheet.dart             # Multi-page collation to PDF
│   ├── structured_result_screen.dart        # JSON/CSV/Table viewer & exporter
│   ├── document_history_screen.dart         # Searchable local ledger & history
│   ├── expense_dashboard_screen.dart        # Charts & visual analytics
│   ├── recurring_expenses_screen.dart       # Subscription cadence tracker
│   ├── budget_settings_screen.dart          # Thresholds & progress bars
│   └── security_settings_screen.dart        # Biometric lock toggles
├── services/
│   ├── ocr_service.dart                     # Abstract OCR interface
│   ├── mlkit_ocr_service.dart               # Google ML Kit OCR implementation
│   ├── structured_parser_service.dart       # Regex & Gemini AI extraction engine
│   ├── categorization_service.dart          # Automated expense taxonomy rules
│   ├── storage_service.dart                 # Hive local database CRUD & search
│   ├── analytics_service.dart               # Metric aggregations for charts
│   ├── tax_report_service.dart              # PDF Schedule C statement generator
│   ├── duplicate_and_recurring_service.dart # Duplicate guard & cadence detector
│   ├── budget_service.dart                  # Budget threshold evaluation
│   ├── notification_service.dart            # Local push notifications
│   ├── auth_service.dart                    # Biometric verification manager
│   ├── app_lock_manager.dart                # Background timeout auto-lock logic
│   ├── encryption_service.dart              # Client-side AES-256-GCM cipher
│   ├── cloud_sync_service.dart              # Firebase Firestore & Storage sync
│   ├── backup_service.dart                  # ZIP backup export
│   ├── restore_service.dart                 # ZIP backup restore
│   └── subscription_service.dart            # RevenueCat Pro tier management
└── widgets/
    ├── app_lock_overlay.dart                # Privacy shield overlay
    ├── biometric_guard.dart                 # Route authentication wrapper
    ├── pro_paywall_sheet.dart               # Pro subscription paywall
    ├── duplicate_warning_dialog.dart        # Pre-save duplicate conflict modal
    ├── tax_report_dialog.dart               # Billing period PDF generator dialog
    ├── backup_export_dialog.dart            # Full ZIP export dialog
    ├── backup_restore_dialog.dart           # Full ZIP restore dialog
    └── cloud_sync_dialog.dart               # Passphrase & sync progress dialog

```

---

## 🛠️ Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.3.0`)
* [Dart SDK](https://dart.dev/get-dart) (`>= 3.3.0`)
* Android Studio / Xcode
* Android device or emulator (API 21+) / iOS device or simulator (iOS 13.0+)

### Installation

1. **Clone the repository:**
```bash
git clone [https://github.com/yitact/DocuMorph.git](https://github.com/yitact/DocuMorph.git)
cd DocuMorph

```


2. **Install dependencies:**
```bash
flutter pub get

```


3. **Generate App Icons & Splash Screens:**
```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create

```


4. **Run the app:**
```bash
flutter run

```



---

## 🔐 Environment & API Configuration

Create a local configuration file or pass environment variables for external integrations:

| Integration | Variable / Config File | Description |
| --- | --- | --- |
| **Google Gemini API** | `GEMINI_API_KEY` | Multimodal AI invoice & receipt parsing |
| **RevenueCat iOS** | `_appleApiKey` in `subscription_service.dart` | Apple App Store subscription billing |
| **RevenueCat Android** | `_googleApiKey` in `subscription_service.dart` | Google Play Store subscription billing |
| **Firebase** | `google-services.json` / `GoogleService-Info.plist` | Firestore & Storage encrypted backup |

---

## 📦 Building for Production

### Android (AAB)

```bash
flutter build appbundle --release

```

*Output: `build/app/outputs/bundle/release/app-release.aab*`

### iOS (IPA)

```bash
flutter build ipa --release

```

*Output: `build/ios/ipa/DocuMorph.ipa*`

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.

```text
Copyright (c) 2026 Samuel. All rights reserved.
Designed and engineered by Samuel with AI co-development assistance.

```

```

---

### Push this README to your GitHub Repository

Run these commands in your terminal to add and push the new `README.md`:

```bash
git add README.md
git commit -m "docs: add comprehensive project README, architecture guide, and setup instructions"
git push origin main

```
Step 1: Configure Dependencies

Add these dependencies to your pubspec.yaml file:

dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.1.2
  google_mlkit_text_recognition: ^0.14.0
  share_plus: ^10.0.0
  flutter/services.dart:
  ---
  Step 2: Platform Permissions Setup
  iOS (ios/Runner/Info.plist):

<key>NSCameraUsageDescription</key>
<string>This app requires camera access to scan documents.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app requires photo library access to import images.</string>
