# Pavra
**Slogan:** *The Smarter Roads, The Safer Journeys.*

## 🌍 Project Description
Pavra is a mobile application that leverages AI and geolocation technology to enhance road care, quality, and safety. The app empowers road users, drivers, and local authorities to detect, report, and analyze road conditions in real-time. By combining mobile intelligence and computer vision, Pavra aims to create smarter roads and safer journeys for everyone.

---

## 🧠 Tech Stack
- **Framework:** Flutter (Dart)
- **AI Model:** YOLOv8n (lightweight on-device image detection)
- **Database:** Supabase (free tier)
- **Backend:** Firebase Functions / Supabase Edge Functions (optional)
- **Map & GPS:** Google Maps API (free tier under daily limit)
- **Hosting / Storage:** Supabase or Firebase Storage
- **IDE:** Android Studio / Windsurf
- **Version Control:** GitHub (free)

---

## ⚙️ Key Modules
1. **Road Condition Detection**
   - Capture or upload road images.
   - AI model identifies potholes, cracks, or obstacles.
2. **Report Management**
   - Submit detected issues with location and photo evidence.
   - Sync data with cloud backend.
3. **Map Visualization**
   - View reported issues on a map with status indicators.
4. **User Roles**
   - *Public Users:* Report road issues.
   - *Authorities:* View aggregated reports and respond.
5. **Analytics Dashboard**
   - Show insights on frequently reported areas.
6. **Safety Alerts**
   - Notify users of unsafe road sections nearby.

---

## 🧩 Key Features
- Real-time AI road damage detection (via phone camera)
- GPS-based location tagging
- Offline detection support (optional)
- Cloud-synced reports
- Simple and intuitive UI for quick submissions
- View nearby road safety alerts

---

## 🔁 Workflow Overview
1. **User opens Pavra app**
2. **Captures a road photo**
3. **AI model (YOLOv8n) analyzes the image**
4. **Detected damage tagged with GPS coordinates**
5. **User reviews and submits the report**
6. **Data stored in Supabase**
7. **Authorities access data through dashboard**
8. **Users receive notifications of dangerous routes**

---

## 🚀 Build Steps
1. Install Flutter SDK  
2. Open project in Android Studio or Windsurf  
3. Connect Android device or use emulator  
4. Run the command:  
   ```bash
   flutter run
