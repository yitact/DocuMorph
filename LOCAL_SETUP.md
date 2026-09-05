# DocuMorph - Local Setup & Testing Guide

## Quick Start

### Prerequisites
- Git installed
- Flutter SDK (>= 3.3.0) - [Download](https://flutter.dev/docs/get-started/install)
- Android Studio OR Xcode for emulator
- An Android/iOS device or emulator

---

## Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/yitact/DocuMorph.git
cd DocuMorph

# Verify you're on main branch
git branch
git pull origin main
```

---

## Step 2: Install Dependencies

```bash
# Get all Flutter dependencies
flutter pub get

# Generate code (Hive models, JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs
```

If you encounter errors, try:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Step 3: Configure Environment

### Create `.env` file (Optional but recommended)
```bash
# Copy from example
cp .env.example .env

# Edit with your API keys
nano .env
```

Add these values:
```env
FIREBASE_PROJECT_ID=your-project-id
GEMINI_API_KEY=your-gemini-key
APP_ENVIRONMENT=development
ENABLE_ANALYTICS=false
```

---

## Step 4: Run on Android

### Using Android Emulator

```bash
# List available emulators
flutter emulators

# Launch an emulator (replace "Pixel_4_API_30" with your emulator name)
flutter emulators --launch Pixel_4_API_30

# Wait for emulator to start, then run
flutter run

# Or run in debug mode with verbose output
flutter run --verbose
```

### Using Physical Android Device

1. **Enable Developer Mode** on your device:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings → Developer Options
   - Enable "USB Debugging"

2. **Connect device via USB**

3. **Run the app:**
   ```bash
   flutter devices  # Verify device is connected
   flutter run
   ```

---

## Step 5: Run on iOS

### Using iOS Simulator

```bash
# Open simulator
open -a Simulator

# Run the app
flutter run

# Or specify iPhone model
flutter run -d "iPhone 14 Pro"
```

### Using Physical iOS Device

1. **Open Xcode project:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Set up signing:**
   - Select "Runner" in left sidebar
   - Go to Signing & Capabilities
   - Select your Team
   - Update Bundle Identifier if needed

3. **Run:**
   ```bash
   flutter run
   ```

---

## Step 6: Development Features

### Run with Hot Reload
```bash
# Start app in debug mode (press 'r' to reload, 'R' for full restart)
flutter run
```

### Run with Logs
```bash
flutter run -v  # Verbose mode - shows all logs
```

### Run Tests
```bash
flutter test
```

### Check Code Quality
```bash
flutter analyze    # Check for code issues
dart format .     # Format all files
```

---

## Step 7: Build for Testing

### Android APK (For testing on device)
```bash
# Debug APK
flutter build apk --debug
# Output: build/app/outputs/flutter-app-debug.apk

# Install on connected device
adb install build/app/outputs/flutter-app-debug.apk

# Run
adb shell am start -n com.yitact.documorph/.MainActivity
```

### Android AAB (For Google Play)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS IPA (For testing)
```bash
flutter build ipa --release
# Output: build/ios/ipa/DocuMorph.ipa
```

---

## Troubleshooting

### Issue: "Flutter not found"
```bash
# Add Flutter to PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# Or check Flutter installation
flutter doctor
```

### Issue: "No connected devices"
```bash
# List devices
flutter devices

# Start emulator
flutter emulators --launch <emulator_name>

# For iOS
open -a Simulator
```

### Issue: Pod dependencies (iOS)
```bash
cd ios
rm -rf Pods Podfile.lock
cd ..
flutter pub get
flutter run
```

### Issue: Gradle issues (Android)
```bash
flutter clean
rm -rf android/build
flutter pub get
flutter run
```

### Issue: Build runner fails
```bash
flutter pub global activate build_runner
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Development Workflow

### 1. Create a feature branch
```bash
git checkout -b feature/your-feature-name
```

### 2. Make changes
```bash
# Edit files in lib/
# Test with: flutter run
```

### 3. Run tests and linter
```bash
flutter test
flutter analyze
dart format .
```

### 4. Commit and push
```bash
git add .
git commit -m "feat: your feature description"
git push origin feature/your-feature-name
```

### 5. Create Pull Request on GitHub

---

## Testing Different Scenarios

### Test OCR Functionality
1. Run the app
2. Tap "Scan Camera" button
3. Take a photo of a receipt/document
4. Verify text extraction

### Test Budget Alerts
1. Go to Settings
2. Set a low budget for a category
3. Add expenses that exceed it
4. Should see alerts

### Test Dark Mode
1. Run: `flutter run`
2. In your device settings, enable Dark Mode
3. App should adapt to theme

---

## Useful Commands Reference

```bash
# Flutter commands
flutter --version                      # Check Flutter version
flutter doctor                         # Diagnose issues
flutter pub upgrade                    # Upgrade dependencies
flutter pub outdated                   # Check for updates
flutter devices                        # List connected devices
flutter emulators                      # List available emulators

# Development
flutter run                            # Run debug app
flutter run -v                         # Verbose mode
flutter run -d <device_id>            # Run on specific device
flutter run --release                  # Release mode

# Building
flutter build apk                      # Build Android debug APK
flutter build apk --release            # Build Android release APK
flutter build appbundle --release      # Build Android App Bundle
flutter build ipa --release            # Build iOS release IPA

# Code generation
flutter pub run build_runner build     # One-time generation
flutter pub run build_runner watch     # Watch mode

# Testing & Analysis
flutter test                           # Run all tests
flutter analyze                        # Code analysis
dart format .                          # Format code
dart fix --apply                       # Auto-fix issues

# Cleaning
flutter clean                          # Clean build artifacts
flutter pub get                        # Reinstall dependencies
```

---

## IDE Setup

### Android Studio / IntelliJ
1. Install Flutter plugin
2. Open project folder
3. IDE auto-detects Flutter SDK
4. Press `Shift + F10` to run

### VS Code
1. Install Flutter extension
2. `Ctrl+Shift+D` → Select Flutter
3. `F5` to debug or run

### Xcode (iOS)
1. Open `ios/Runner.xcworkspace`
2. Select "Runner" target
3. Press Play button to build & run

---

## Next Steps

- ✅ App is running locally
- 📚 Read [README.md](README.md) for architecture
- 🔧 Configure Firebase for cloud sync
- 🧪 Run tests: `flutter test`
- 📦 Build release: `flutter build appbundle --release`

---

## Getting Help

- **Flutter Docs**: https://flutter.dev/docs
- **GitHub Issues**: https://github.com/yitact/DocuMorph/issues
- **Dart Docs**: https://dart.dev/guides
- **Firebase Docs**: https://firebase.google.com/docs

---

**Happy Testing! 🚀**
