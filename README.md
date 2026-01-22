# Pavra
**Slogan:** *The Smarter Roads, The Safer Journeys.*

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/WeiXuan-C/Pavra)  
![Flutter](https://img.shields.io/badge/Flutter-3.35.7+-02569B?logo=flutter&logoColor=white)  
![Dart](https://img.shields.io/badge/Dart-3.9.2+-0175C2?logo=dart&logoColor=white)  
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-blue)  
![AI](https://img.shields.io/badge/AI-Google%20Gemma%203-orange)

---

## 📑 Table of Contents
- [Overview](#-overview)
- [Problem Statement](#-problem-statement)
- [Solution](#-solution)
- [System Architecture](#-system-architecture)
- [Tech Stack](#-tech-stack)
- [Key Features](#-key-features)
- [Workflow Overview](#-workflow-overview)
- [Roles & Access Levels](#-roles--access-levels)
- [Deployment](#-deployment)

---

## 🌍 Overview
**Pavra** is an AI-powered, community-driven road safety application designed to detect, report, and visualize road hazards such as potholes, cracks, and uneven surfaces.

By combining **vision-based artificial intelligence**, **GPS location services**, and **crowdsourced participation**, Pavra enables early hazard detection and real-time safety awareness, helping drivers make safer and more informed decisions.

---

## 🚧 Problem Statement
Road hazards remain a major contributor to traffic accidents and vehicle damage. Existing solutions rely heavily on manual reporting, periodic inspections, or expensive hardware-based scanning systems, which often result in delayed responses.

As a result, many road issues are only addressed after accidents occur.

---

## 💡 Solution
Pavra introduces a **software-based, AI-driven, and community-powered solution** that enables everyday drivers to actively contribute to road safety.

Users capture road images using their mobile devices, while the system automatically detects damage, assesses severity, tags locations, and notifies nearby users in real time.

---

## 🏗️ System Architecture
Pavra is designed as a **front-end–centric application** without a traditional custom backend server.

- Authentication, database, and file storage are handled by **Supabase**
- AI inference is performed via **external AI APIs**
- Push notifications are delivered using **OneSignal integrated with Firebase**
- The architecture prioritizes performance, scalability, and real-time interaction

---

## 🧠 Tech Stack

| Layer | Technology | Purpose |
|------|-----------|---------|
| Frontend | Flutter (Dart) | Cross-platform application |
| Architecture | Frontend-centric (Serverless-style) | No custom backend server |
| Authentication | Supabase Auth (Email OTP) | Passwordless login |
| Database | Supabase (PostgreSQL) | Stores users, reports, and metadata |
| Storage | Supabase Storage | Stores road images and evidence |
| AI Model | Google Gemma 3 4B (Vision-Language) | Road damage detection |
| AI Inference | External AI API | Model execution |
| Maps & Navigation | Google Maps Platform | Maps and routing |
| Geolocation | Geolocator | Real-time location |
| Push Notifications | OneSignal + Firebase | Hazard alerts |
| Voice Search | Speech-to-Text API | Hands-free navigation |
| State Management | Provider | App-wide state |
| Internationalization | Flutter i18n | EN / ZH support |
| Version Control | GitHub | Source management |

---

## ✨ Key Features
- AI-powered road damage detection and severity classification  
- GPS-based hazard tagging  
- Interactive map with severity markers  
- Real-time hazard alerts with adjustable radius  
- Location-based voting for report validation  
- Route planning with hazard summary  
- Voice search for navigation  
- Light and Dark mode  
- Multi-language support (English / Chinese)  
- User statistics and reputation scoring  

---

## 🔁 Workflow Overview
1. User opens the Pavra application  
2. Logs in using email-based OTP authentication  
3. Captures or uploads a road image  
4. AI analyzes the image and detects road damage  
5. Severity and issue type are generated  
6. User reviews and submits the report  
7. Report is stored and displayed on the map  
8. Nearby users receive hazard alerts  
9. Users near the location can vote to confirm accuracy  

---

## 👥 Roles & Access Levels

| Role | Description | Capabilities |
|------|------------|--------------|
| User | Community drivers | Report hazards, view maps, receive alerts |
| Developer | Internal testing role | Debug and experimental features |

**Developer Mode:**  
Profile → About → Tap app version **7 times**

---

## 🚀 Deployment
- Frontend: Flutter 3.35.7+  
- Platforms: Android, iOS, Web, Desktop  
- Database & Storage: Supabase  
- AI Services: External AI API (Google Gemma 3 4B)  
- Maps: Google Maps Platform  
- Notifications: OneSignal + Firebase  

---

## 🏁 Conclusion
Pavra demonstrates how vision AI, real-time location services, and cloud platforms can work together to improve road safety.

By empowering drivers to contribute to hazard detection, Pavra shifts road safety from reactive response to proactive prevention.

---

**Made with ❤️ by the Pavra Team**  
*Building smarter roads for safer journeys*
