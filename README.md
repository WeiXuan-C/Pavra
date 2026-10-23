# Pavra
**Slogan:** *The Smarter Roads, The Safer Journeys.*
  
![Flutter](https://img.shields.io/badge/Flutter-3.35.7+-02569B?logo=flutter&logoColor=white)  
![Dart](https://img.shields.io/badge/Dart-3.9.2+-0175C2?logo=dart&logoColor=white)  
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-blue)  
![AI](https://img.shields.io/badge/AI-Google%20Gemma%203-orange)

---

## 📑 Table of Contents
- [Overview](#-overview)
- [Problem Statement](#-problem-statement)
- [Solution](#-solution)
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
- Multiple issue type support with dynamic category management  
- Reviewer attribution — reports track who reviewed and acted on each submission  

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
10. Authority users review submissions and are recorded as the responsible reviewer  

---

## 🛣️ Supported Issue Types

### AI-Detected Types
The AI model classifies road images into one of 8 categories:

| Type | Description |
|------|-------------|
| Road Crack | Visible cracks or fractures on the road surface |
| Pothole | Holes or cavities formed in the road |
| Uneven Surface | Bumps, dips, or irregular road surfaces |
| Flood | Water accumulation blocking or covering the road |
| Accident | Vehicle collisions or accident scenes |
| Debris | Fallen objects, rubble, or scattered materials |
| Obstacle | Objects blocking or partially obstructing the road |
| Normal | No road hazard detected |

### User-Reported Issue Types
Beyond AI detection, issue categories are managed dynamically through the database, allowing administrators to add, edit, or remove types as needed. Each type has a name, description, and icon for display on the map and in reports.

---

## 👤 Reviewer Attribution
Each submitted report tracks **who reviewed it**. When an authority user verifies or flags a report, their identity is recorded alongside a timestamp and optional comment. This reviewer information is visible in the authority management interface, providing full accountability for every review action.

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

**Please fill in the feedback form here:**  
🔗 https://docs.google.com/forms/d/e/1FAIpQLScducuwUb_UX4cGW4x5HVGZMgEJ7ZynZdCzcfgMyrhK-kbNOA/viewform?usp=publish-editor

---

**Made with ❤️ by the Pavra Team**  
*Building smarter roads for safer journeys*
