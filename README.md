# Pavra  
**Slogan:** *The Smarter Roads, The Safer Journeys.*  

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/WeiXuan-C/Pavra)

---

## 🌍 Overview  
**Pavra** is an intelligent mobile application that combines **AI-powered road damage detection**, **geolocation**, and **community-driven reporting** to improve road safety and infrastructure management.  

Users can **detect**, **report**, and **analyze** road conditions in real time — helping authorities and drivers build **smarter roads** and ensure **safer journeys**.  

---

## 🧠 Tech Stack  

| Layer | Technology | Purpose |
|-------|-------------|----------|
| **Frontend** | Flutter (Dart) | Cross-platform mobile development |
| **Backend** | Serverpod | API server and custom business logic |
| **Database** | Supabase (PostgreSQL) | Store users, reports, and metadata |
| **Storage** | Supabase Storage | Road image and report history storage |
| **AI Model** | YOLOv8n (Hugging Face Spaces) | Detect potholes, cracks, and obstacles |
| **Map & GPS** | Google Maps Flutter, Geolocator | Visualize reports and get user location |
| **Push Notifications** | OneSignal | Send hazard and system alerts |
| **Task Queue** | Upstash QStash | Background task scheduling |
| **Cache Layer** | Upstash Redis | Temporary data and action logs |
| **State Management** | Provider | Manage authentication, theme, locale, notifications |
| **Version Control** | GitHub | Source management and collaboration |

---

## 👥 Roles & Access Levels  

Pavra provides **three distinct user roles** to ensure a secure and organized experience for all participants in the ecosystem:  

| Role | Description | Key Capabilities |
|------|--------------|------------------|
| **User** | Regular drivers and community members | Detect and report road issues, view maps, receive hazard alerts, earn points and badges |
| **Authority** | Authorized government or maintenance personnel | Review and verify reports, manage road maintenance updates, access analytics |
| **Developer** | Internal testers or system maintainers | Access debug tools, monitor logs, and test experimental features |

### 🧑‍💻 How to Enter Developer Mode  
To activate **Developer Mode**, go to **Profile → About Page**, then **tap the app version number 7 times**.  

---

## ⚙️ Core Modules  

### 🔐 Authentication  
- Supabase Auth for email/password login  
- Session persistence and token handling  
- RouteGuard middleware for navigation protection  

### 🧭 Road Condition Detection  
- Capture or upload road images using device camera  
- AI inference via YOLOv8n model hosted on Hugging Face  
- Detects potholes, cracks, and foreign obstacles in real time  

### 🗂️ Report Management  
- Submit AI-detected issues with GPS metadata  
- Upload road photos to Supabase Storage  
- Access personal report history and status tracking  

### 🗺️ Map Visualization  
- Interactive Google Map display  
- Color-coded markers by severity or report type  
- Detailed pop-up info for each detected issue  

### 🚗 Smart Drive Mode  
- Background GPS tracking during driving  
- Voice-based hazard alerts using Text-to-Speech  
- Example:  
  > “⚠️ Pothole detected ahead. Please slow down.”  

### 🏅 Gamification System  
- Earn points for validated reports  
- Unlock achievement badges  
- Real-time leaderboard synced to Supabase  

### 🔔 Notifications & Alerts  
- Push alerts for nearby road hazards  
- System updates powered by OneSignal  

### 📊 Analytics Dashboard *(Future Development)*  
- Insights into road conditions by area  
- Identify high-risk and frequently reported zones  

---

## 🧩 Key Features  
- 🤖 AI-powered real-time damage detection  
- 📍 GPS-based location tagging  
- ☁️ Cloud-synced reporting  
- 🔊 Voice alerts for nearby hazards  
- 🏅 Gamified user engagement system  
- 🌗 Dark/Light theme with full i18n (EN/ZH)  
- 📶 Offline caching & reconnect logic  
- 👥 Role-based access (User / Authority / Developer)  

---

## 🔁 Workflow Overview  
1. User opens Pavra app  
2. Captures or uploads a road image  
3. YOLOv8n performs AI damage detection  
4. Pavra tags results with GPS coordinates  
5. Voice alert triggers if hazards are nearby  
6. User confirms and submits report  
7. Report data and image stored in Supabase  
8. Points and badges updated in user profile  

---

## 🚀 Deployment  
- **Frontend:** Flutter 3.9.2+ (Android & iOS)  
- **Backend:** Serverpod hosted on **Railway**  
- **Cache & Queue:** Upstash Redis + QStash  
- **Database & Storage:** Supabase  
- **AI Service:** Hugging Face Spaces  
