# PDF Editor Pro 📄

A full-featured PDF editor built with Flutter — runs on **Android (APK)** and **Windows (EXE)** from a single codebase.

---

## ✨ Features

| Feature | Description |
|---|---|
| **Edit Text** | Add draggable, resizable, styled text anywhere on any page |
| **Draw / Freehand** | Draw freely with custom color and stroke width |
| **Highlight** | Semi-transparent highlight brush tool |
| **Underline / Strikethrough** | Annotation tools for marking content |
| **Add Images** | Insert images from gallery, drag to reposition, resize with handle |
| **Sign Documents** | Built-in signature pad with ink color options |
| **Merge PDFs** | Drag-to-reorder multi-file merger |
| **Split PDF** | Page-by-page extraction to separate files |
| **Undo / Redo** | Full undo/redo stack (50 levels) |
| **Save / Share** | Save to Downloads (Android) or chosen path (Windows), share via OS sheet |

---

## 📥 Download Pre-built Releases

### GitHub Actions Builds

Every push to the main branch automatically builds:
- **Android APKs** (arm64-v8a, armeabi-v7a, x86_64)
- **Windows EXE** (with all dependencies)
- **Windows ZIP** (portable version)

**To download:**
1. Go to the [Actions tab](../../actions)
2. Click on the latest successful build
3. Scroll to "Artifacts" section
4. Download your preferred package:

#### Available Artifacts:

| Artifact Name | Contents | Size | Use For |
|---|---|---|---|
| **PDFEditorPro-Android-APKs** | 3 .apk files (arm64, armeabi, x86_64) | ~31 MB | Android devices |
| **PDFEditorPro-Windows-ZIP** | PDFEditorPro.exe + DLLs in single .zip | ~16 MB | Windows (portable) |
| **PDFEditorPro-Windows-Portable** | Complete folder structure | ~16 MB | Windows (extract & run) |

### Installation:

**Android:**
1. Download `PDFEditorPro-Android-APKs`
2. Extract the ZIP to get 3 .apk files
3. Install the one that matches your device:
   - Most phones: `PDFEditorPro-Android-arm64-v8a.apk`
   - Older phones: `PDFEditorPro-Android-armeabi-v7a.apk`
   - Emulators: `PDFEditorPro-Android-x86_64.apk`

**Windows:**
1. Download either `PDFEditorPro-Windows-ZIP` or `PDFEditorPro-Windows-Portable`
2. Extract the contents
3. Run `PDFEditorPro.exe`
4. No installation required - it's portable!

---

## 🛠️ Build from Source

If you prefer to build from source instead of downloading pre-built releases:

### Prerequisites

Install the following **before** anything else:

### 1. Flutter SDK
```bash
# Download from https://docs.flutter.dev/get-started/install
# Or use snap (Linux):
sudo snap install flutter --classic

# Verify installation:
flutter doctor
```

### 2. Android Development (for APK)
- Install [Android Studio](https://developer.android.com/studio)
- Install Android SDK via SDK Manager (API 34 recommended)
- Accept licenses:
  ```bash
  flutter doctor --android-licenses
  ```

### 3. Windows Development (for EXE)
- Install **Visual Studio 2022** with:
  - "Desktop development with C++" workload
  - Windows 10/11 SDK
- Enable Windows desktop support:
  ```bash
  flutter config --enable-windows-desktop
  ```

---

## 🚀 Setup

### Step 1 — Clone / place the project
Put this entire folder on your machine. For example:
```
C:\Projects\pdf_editor_pro\    (Windows)
~/projects/pdf_editor_pro/     (Linux/Mac)
```

### Step 2 — Get dependencies
```bash
cd pdf_editor_pro
flutter pub get
```

### Step 3 — Check everything
```bash
flutter doctor -v
```
All required sections should show ✅ (Android and/or Windows).

---

## 📱 Build Android APK

### Debug APK (for testing)
```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK (for distribution)
```bash
flutter build apk --release --split-per-abi
```
Output files in `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk`   ← Use this for most modern Android phones
- `app-armeabi-v7a-release.apk` ← Older 32-bit devices
- `app-x86_64-release.apk`      ← Emulators

### Install directly to connected device
```bash
flutter install
# Or:
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Signing the release APK (for Play Store)
1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```
2. Create `android/key.properties`:
   ```properties
   storePassword=<your-password>
   keyPassword=<your-password>
   keyAlias=upload
   storeFile=<path-to>/upload-keystore.jks
   ```
3. Add signing config to `android/app/build.gradle`:
   ```gradle
   android {
       signingConfigs {
           release {
               keyAlias keystoreProperties['keyAlias']
               keyPassword keystoreProperties['keyPassword']
               storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
               storePassword keystoreProperties['storePassword']
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
           }
       }
   }
   ```
4. Rebuild: `flutter build apk --release`

---

## 🖥️ Build Windows EXE

### Debug (for testing)
```bash
flutter build windows --debug
```
Output: `build\windows\x64\runner\Debug\pdf_editor_pro.exe`

### Release EXE
```bash
flutter build windows --release
```
Output: `build\windows\x64\runner\Release\pdf_editor_pro.exe`

> ⚠️ The `.exe` requires ALL files in the `Release\` folder. Copy the entire folder, not just the `.exe`.

### Create installer (optional)
Install [Inno Setup](https://jrsoftware.org/isinfo.php), then create a script:
```iss
[Setup]
AppName=PDF Editor Pro
AppVersion=1.0.0
DefaultDirName={autopf}\PDF Editor Pro
OutputBaseFilename=PDFEditorProSetup

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\PDF Editor Pro"; Filename: "{app}\pdf_editor_pro.exe"
```
Compile with Inno Setup to get a single installer `.exe`.

---

## 🔧 Project Structure

```
pdf_editor_pro/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── screens/
│   │   ├── home_screen.dart         # Home with tool cards
│   │   ├── editor_screen.dart       # Main PDF editor
│   │   └── merge_split_screen.dart  # Merge & split PDFs
│   ├── widgets/
│   │   ├── editor_toolbar.dart      # Top toolbar with tools
│   │   ├── annotation_layer.dart    # Canvas overlay for annotations
│   │   ├── text_editor_dialog.dart  # Text insertion dialog
│   │   ├── signature_pad.dart       # Signature drawing pad
│   │   ├── color_picker_panel.dart  # Color picker + properties panel
│   │   └── properties_panel.dart    # Bold/italic toggles
│   ├── services/
│   │   ├── pdf_state.dart           # Global state (Provider)
│   │   └── pdf_service.dart         # File I/O, export, merge, split
│   ├── models/                      # Data models
│   └── utils/                       # Helpers
├── android/
│   └── app/
│       ├── build.gradle
│       └── src/main/
│           ├── AndroidManifest.xml
│           └── res/xml/file_paths.xml
├── windows/
│   └── CMakeLists.txt
└── pubspec.yaml
```

---

## 📋 Key Dependencies

| Package | Purpose |
|---|---|
| `syncfusion_flutter_pdfviewer` | Render PDF pages |
| `syncfusion_flutter_pdf` | Read/write/export PDF content |
| `file_picker` | Cross-platform file browser |
| `image_picker` | Gallery image selection |
| `flutter_colorpicker` | Color picker dialog |
| `provider` | State management |
| `flutter_animate` | Smooth animations |
| `share_plus` | OS-level share sheet |
| `path_provider` | Platform file paths |

> **Syncfusion License**: For production apps, register for a free [Syncfusion community license](https://www.syncfusion.com/products/communitylicense) to remove the watermark on the PDF viewer.

---

## ⚡ Quick Commands Reference

```bash
# Run in debug mode (connected device/emulator)
flutter run

# Run on Windows desktop
flutter run -d windows

# Build Android APK
flutter build apk --release --split-per-abi

# Build Windows EXE
flutter build windows --release

# Clean build cache
flutter clean && flutter pub get
```

---

## 🐛 Common Issues

**"SDK not found"**
→ Run `flutter doctor` and follow the setup guide for your platform.

**"Gradle build failed"**
→ Make sure Android SDK is installed and `ANDROID_HOME` environment variable is set.

**"Syncfusion watermark on PDF viewer"**
→ [Get a free community license](https://www.syncfusion.com/products/communitylicense) and initialize it in `main.dart`:
```dart
SyncfusionLicense.registerLicense('YOUR_LICENSE_KEY');
```

**"Permission denied on Android 13+"**
→ The app already requests `READ_MEDIA_IMAGES`. Make sure you tap "Allow" when prompted.

**"Windows build: cannot find Visual Studio"**
→ Install Visual Studio 2022 with the "Desktop development with C++" workload.

---

## 📬 Support

Built with Flutter 3.x. Tested on Android 10+ and Windows 10/11.
