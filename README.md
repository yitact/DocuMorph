# DocuMorph

A Flutter document scanner with on-device OCR and an encrypted local
document library. Scan a receipt or document with the camera (or pick an
image), extract its text on-device, and keep it in a library that is
encrypted at rest behind a passphrase only you know.

## What works today

- **Capture & OCR** — Take a photo or pick an image; text is recognized
  on-device with Google ML Kit. No image leaves the phone for OCR.
- **Encrypted library** — Saved documents are stored locally as a single
  encrypted envelope:
  - AES-256-GCM encryption
  - Key derived from your passphrase with PBKDF2-HMAC-SHA256
    (210,000 iterations, per-library salt)
  - A passphrase gate (Unlock Library screen) guards access
  - **If you forget the passphrase, the library cannot be recovered.**
    There is no back door, by design.
- **Saved documents** — Browse and open your saved scans in the app.
- **Share** — Share recognized text out of the app with the system share
  sheet.
- **Firebase configured** — The app initializes Firebase at startup from
  `android/app/google-services.json` (project `documorph-ad103`) and
  initializes the cloud sync service, which encrypts document payloads
  client-side before writing them to Cloud Firestore. If Firebase is
  unreachable or unconfigured, the app simply runs local-only — the
  encrypted local library is always the source of truth.

## In the codebase, not yet wired into the UI

The service layer also contains analytics, category budgets,
duplicate/recurring-expense detection, local notifications, and a
biometric auth wrapper (`local_auth`). These are implemented and covered
by the project structure, but they are not yet surfaced in the app's
screens.

## Roadmap

- Automatic cloud sync triggers and Firebase Auth user accounts
- Document image sync via Firebase Storage
- Analytics and budget screens
- AI-assisted receipt parsing
- Subscriptions / Pro tier

## Tech

- Flutter 3.x (Dart SDK `>=3.0.0 <4.0.0`)
- `google_mlkit_text_recognition` for on-device OCR
- `cryptography` for AES-256-GCM + PBKDF2
- `firebase_core`, `cloud_firestore`, `firebase_storage`
- `path_provider` for the file-backed document store

## Getting started

```bash
flutter pub get
```

### Firebase (Android)

Download `google-services.json` from the Firebase console
(Project settings → Your apps → DocuMorph) and place it at:

```text
android/app/google-services.json
```

The file is intentionally **not** committed to git (see `.gitignore`).
Without it, the app still builds and runs in local-only mode.

### Run / verify

```bash
flutter run
flutter analyze
flutter test
```

Current status: `flutter analyze` reports no issues and the full test
suite (29 tests) passes.

## Project layout

```text
lib/
├── main.dart                 # App entry; wires OCR, store, encryption, Firebase
├── models/
│   ├── parsed_document.dart  # Receipt/invoice models (line items, summaries)
│   └── stored_document.dart  # Saved document model
├── screens/
│   ├── saved_documents_screen.dart
│   └── unlock_library_screen.dart
└── services/
    ├── cloud_sync_service.dart          # Firestore sync (client-side encrypted)
    ├── document_store.dart              # File-backed encrypted library
    ├── encryption_service.dart          # AES-256-GCM + PBKDF2
    ├── mlkit_ocr_service.dart           # ML Kit OCR implementation
    ├── ocr_service.dart                 # OCR interface
    ├── analytics_service.dart           # (not yet in UI)
    ├── auth_service.dart                # (not yet in UI)
    ├── budget_service.dart              # (not yet in UI)
    ├── duplicate_and_recurring_service.dart # (not yet in UI)
    └── notification_service.dart        # (not yet in UI)
```

---

© 2026 Samuel Arega. Built with AI development assistance.
