# Pavra  
**Slogan:** *The Smarter Roads, The Safer Journeys.*  

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/WeiXuan-C/Pavra)
![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.9.2+-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blue)
![AI](https://img.shields.io/badge/AI-NVIDIA%20%7C%20Gemini-orange)

---

## 📑 Table of Contents
- [Overview](#-overview)
- [Tech Stack](#-tech-stack)
- [Roles & Access Levels](#-roles--access-levels)
- [Key Features](#-key-features)
- [Workflow Overview](#-workflow-overview)
- [Deployment](#-deployment)

---

## 🌍 Overview  
**Pavra** is an intelligent mobile application that combines **AI-powered road damage detection**, **geolocation**, and **community-driven reporting** to improve road safety and infrastructure management.  

Users can **detect**, **report**, and **analyze** road conditions in real time — helping authorities and drivers build **smarter roads** and ensure **safer journeys**.

### 🎯 Mission
To create a safer driving experience by leveraging AI technology and community collaboration to identify and report road hazards before they cause accidents.

### 💡 Why Pavra?
- **Proactive Safety**: Detect hazards before accidents happen
- **Community-Driven**: Crowdsourced data for comprehensive coverage
- **AI-Powered**: State-of-the-art vision models for accurate detection
- **Real-Time Alerts**: Instant notifications for nearby hazards
- **Open Platform**: Transparent and accessible to all users

---

## 🧠 Tech Stack  

| Layer | Technology | Purpose |
|-------|-------------|----------|
| **Frontend** | Flutter (Dart) | Cross-platform mobile development |
| **Backend** | Serverpod | API server and custom business logic |
| **Database** | Supabase (PostgreSQL) | Store users, reports, and metadata |
| **Storage** | Supabase Storage | Road image and report history storage |
| **AI Detection Model** | NVIDIA Nemotron Nano 12B V2 VL (OpenRouter) | Vision-language model for road damage detection |
| **AI Image Model** | Google Gemini 2.0 Flash Exp (OpenRouter) | Advanced image analysis and description |
| **Map & GPS** | Google Maps Flutter, Geolocator | Visualize reports and get user location |
| **Push Notifications** | OneSignal | Send hazard and system alerts |
| **State Management** | Provider | Manage authentication, theme, locale, notifications |
| **Version Control** | GitHub | Source management and collaboration |

---

## 👥 Roles & Access Levels  

Pavra provides **two distinct user roles** to ensure a secure and organized experience:  

| Role | Description | Key Capabilities |
|------|--------------|------------------|
| **User** | Regular drivers and community members | Detect and report road issues, view maps, receive hazard alerts, earn points, badges, and reputation scores |
| **Developer** | Internal testers or system maintainers | Access debug tools, monitor logs, and test experimental features |

### 🧑‍💻 How to Enter Developer Mode  
To activate **Developer Mode**, go to **Profile → About Page**, then **tap the app version number 7 times**.  

---

## 🧩 Key Features  
- 🤖 **AI-powered real-time damage detection** using NVIDIA Nemotron & Google Gemini models  
- 📍 **GPS-based location tagging** with precise coordinates  
- ☁️ **Cloud-synced reporting** via Supabase  
- 🌗 **Dark/Light theme** with full internationalization (EN/ZH)  
- 📶 **Offline queue management** - detections retry automatically when online  
- 🎚️ **Adjustable sensitivity** (1-5 levels) for detection confidence  
- 👥 **Role-based access** (User / Developer)  
- 🗺️ **Interactive map** with color-coded severity markers  
- 📊 **Detection history** with filtering by type, severity, and date  
- 🔔 **Push notifications** via OneSignal for hazard alerts  
- 📸 **Camera & gallery support** for image capture and upload  

---

## 🔁 Workflow Overview  
1. User opens Pavra app  
2. Captures or uploads a road image  
3. AI models (NVIDIA Nemotron + Google Gemini) perform damage detection via OpenRouter  
4. Pavra tags results with GPS coordinates  
5. Voice alert triggers if hazards are nearby (severity-based)  
6. User confirms and submits report  
7. Report data and image stored in Supabase  
8. Points and reputation score updated in user profile  
9. Failed detections queued for retry when offline  

---

## 🚀 Deployment  
- **Frontend:** Flutter 3.9.2+ (Android & iOS)  
- **Database & Storage:** Supabase  
- **AI Service:** OpenRouter API (NVIDIA Nemotron Nano 12B V2 VL + Google Gemini 2.0 Flash Exp)  
- **Push Notifications:** OneSignal  
- **Maps:** Google Maps Platform  

---

**Made with ❤️ by the Pavra Team**  
*Building smarter roads for safer journeys*  
