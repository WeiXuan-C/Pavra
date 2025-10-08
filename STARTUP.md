# Pavra Startup Guide

This guide helps you set up your free development environment to build the **Pavra** mobile app — a Flutter-based AI solution for smarter and safer roads.

> 💡 Pavra Slogan: **“The Smarter Roads, The Safer Journeys.”**

---

## 🧭 Overview

Pavra will be developed using **Windsurf** for lightweight coding and **Android Studio** for APK building and emulator testing.  
Everything here is **free** — no subscriptions or paid tools required.

---

## 🪄 Step 1: Install Flutter SDK (Free)

1. Go to [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)  
2. Download **Flutter SDK** for your OS (Windows, macOS, or Linux).
3. Extract it somewhere permanent (e.g., `C:\flutter`).
4. Add it to your system PATH:

   ```bash
   setx PATH "%PATH%;C:\flutter\bin"
   ```

5. Verify installation:

   ```bash
   flutter doctor
   ```

   Ensure all checkmarks are ✅. If Android SDK shows as missing, don’t worry — it will be fixed when Android Studio is installed.

---

## 🧰 Step 2: Install Windsurf (Main IDE)

1. Download Windsurf from [https://windsurf.app](https://windsurf.app)
2. Open Windsurf → Sign in (optional, free tier is enough)
3. Install the **Flutter** and **Dart** extensions if not already preinstalled.
4. Enable **AI Cascade** (Windsurf’s built-in AI assistant).
5. You can now use Cascade to generate and refactor Flutter code easily.

Example prompt inside Windsurf:

> “Create a Flutter page that captures road images and shows GPS coordinates.”

---

## ⚙️ Step 3: Install Android Studio (For Testing & Building)

1. Download Android Studio from [https://developer.android.com/studio](https://developer.android.com/studio)
2. During setup, ensure these components are selected:
   - ✅ Android SDK
   - ✅ Android Virtual Device
   - ✅ Flutter Plugin
   - ✅ Dart Plugin
3. Once installed, open Android Studio → Run **“flutter doctor”** again to confirm integration.

---

## 📦 Step 4: Create the Pavra Project

In Windsurf terminal:

```bash
flutter create pavra
cd pavra
flutter run
```

If everything works, you’ll see the Flutter default app running on your phone or emulator.

---

## 🔧 Step 5: Connect Android Device (Optional but Recommended)

1. Enable **Developer Options** on your phone:
   - Go to *Settings → About Phone → Tap Build Number 7 times*
2. Enable **USB Debugging**.
3. Connect your phone to your computer via USB.
4. Run:
   ```bash
   flutter devices
   ```
   It should list your phone name. You can then run:
   ```bash
   flutter run
   ```

---

## 🤖 Step 6: Integrate AI & GPS

- Use **YOLOv8n (TensorFlow Lite)** for road damage detection.
- Use **Google Maps Flutter** plugin for GPS visualization.
- Use **Supabase** (free database) to store reports.

Ask Cascade for help with code snippets, for example:

> “How do I use tflite_flutter in Dart for image object detection?”  
> “Show me how to use Google Maps Flutter plugin to display location markers.”

---

## ☁️ Step 7: Connect to Supabase (Free Backend)

1. Go to [https://supabase.com](https://supabase.com)
2. Create a new project (choose free tier).
3. Copy your API URL and public key.
4. In Flutter, install the package:

   ```bash
   flutter pub add supabase_flutter
   ```

5. Initialize in `main.dart`:

   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_PUBLIC_KEY',
   );
   ```

---

## 🚀 Step 8: Build Your APK in Android Studio

Once development is complete:

1. Open your Pavra project folder in Android Studio.
2. Go to **Build → Flutter → Build APK**  
   or use terminal:

   ```bash
   flutter build apk --release
   ```

3. Find the generated file at:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

4. Install on your phone and test!

---

## 🧠 Step 9: Learn Dart While You Build

No need to master everything before starting. You can learn while coding.  
Recommended free resources:
- [https://dart.dev/guides](https://dart.dev/guides)
- [https://dartpad.dev](https://dartpad.dev) (Online sandbox)

Focus on:
- Variables and functions  
- Classes and objects  
- Async/await (for API calls)

---

## 🧩 Optional Free Tools

| Tool | Use |
|------|------|
| **GitHub** | Backup your project (free private repo) |
| **Canva / Figma** | Design app UI mockups |
| **Hugging Face Space** | Host AI models (free tier) |
| **Vercel / Supabase** | Cloud backend or API hosting |

---

## ✅ Summary Workflow

| Phase | Tool | Purpose |
|--------|------|----------|
| Coding | Windsurf | Write Flutter code efficiently |
| Testing | Flutter CLI or Android Studio Emulator | Run app and debug |
| Backend | Supabase | Store reports, images, data |
| AI | YOLOv8n (TFLite) | Detect road damage locally |
| Deployment | Android Studio | Build `.apk` for Pavra |
| Design | Figma / Canva | Optional UI prototyping |

---

## 🎯 Final Notes

- Keep everything open-source and lightweight.  
- Use Windsurf to speed up coding.  
- Use Android Studio only when building `.apk`.  
- No paid dependencies required.

**You’re ready to build Pavra — the smarter way to care for roads.** 🚗💡
