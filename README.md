# Pavra  
**Slogan:** *The Smarter Roads, The Safer Journeys.*  

---

## 🌍 Overview
**Pavra** is a mobile application that leverages **AI** and **geolocation technology** to enhance road care, quality, and safety.  
The app empowers users and drivers to **detect**, **report**, and **analyze** road conditions in real time.  

By combining **mobile intelligence**, **computer vision**, and **gamified engagement**, Pavra helps create **smarter roads and safer journeys** for everyone.

---

## 🧠 Tech Stack

| Layer | Technology | Purpose |
|-------|-------------|----------|
| **Frontend** | Flutter (Dart) | Cross-platform mobile development |
| **Backend** | Serverpod | Custom server logic and Redis caching |
| **Database** | Supabase (PostgreSQL) | Manage user and report data |
| **Storage** | Supabase Storage | Store road images and history |
| **AI Model** | YOLOv8n (Hugging Face Spaces) | Detect road damages such as cracks or potholes |
| **Map & GPS** | Google Maps Flutter, Geolocator | Display and track report locations |
| **Push Notifications** | OneSignal | Send nearby hazard alerts |
| **Text-to-Speech** | flutter_tts | Real-time voice safety alerts |
| **State Management** | Provider | Manage user, report, and UI state |
| **Cache Layer** | Redis | Store short-term data such as action logs |
| **Version Control** | GitHub | Collaborative development and versioning |

---

## ⚙️ Core Modules

### 1. Authentication
- Email/password registration and login via Supabase Auth
- Persistent session management
- Route guard middleware for authenticated navigation

### 2. Road Condition Detection
- Capture or upload road images  
- YOLOv8n detects potholes, cracks, or obstacles  
- Real-time inference through Hugging Face API  

### 3. Report Management
- Submit detected issues with geolocation  
- Upload road images to Supabase Storage  
- View and manage past reports  

### 4. Map Visualization
- Interactive Google Map to view all reports  
- Color-coded markers based on severity or status  
- Tap marker → open detailed report info  

### 5. Smart Drive Mode (Voice Alerts)
- Live GPS tracking  
- Detect nearby hazards in real time  
- Text-to-Speech warnings such as  
  > “⚠️ Pothole detected ahead. Please slow down.”  

### 6. Gamification System
- Users earn points for contributing valid reports  
- Unlock badges for milestones (e.g. “First 10 Reports”)  
- Leaderboard to encourage engagement  
- Data synced to Supabase  

### 7. Notifications & Alerts
- Push alerts for nearby hazards or updates  
- Powered by OneSignal  

### 8. Analytics Dashboard *(Future Phase)*
- Visualize reported issues and patterns  
- Useful for identifying high-risk road areas  

---

## 🧩 Key Features
- 🤖 Real-time AI road damage detection  
- 📍 GPS-based location tagging  
- ☁️ Cloud-synced reports  
- 🔊 Voice alerts for nearby hazards  
- 🏅 Gamified user engagement (points, badges, leaderboard)  
- 🌗 Light/Dark mode + i10n localization  

---

## 🔁 Workflow Overview
1. User opens Pavra  
2. Captures or uploads a road image/video  
3. YOLOv8n detects damage and returns predictions  
4. App tags result with GPS coordinates  
5. Pavra issues voice alert if a nearby hazard is found  
6. User confirms and submits the report  
7. Report stored in Supabase and displayed on map  
8. User earns points and badges  