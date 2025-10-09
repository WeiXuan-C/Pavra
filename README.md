# Pavra  
**Slogan:** *The Smarter Roads, The Safer Journeys.*  

---

## 🌍 Project Description  
**Pavra** is a mobile application that leverages **AI** and **geolocation technology** to enhance road care, quality, and safety.  
The app empowers road users, drivers, and local authorities to **detect**, **report**, and **analyze** road conditions in real time.  

By combining **mobile intelligence**, **computer vision**, and **gamified engagement**, Pavra aims to create **smarter roads and safer journeys** for everyone.

---

## 🧠 Tech Stack
- **Framework:** Flutter (Dart) – cross-platform mobile development  
- **AI Model:** YOLOv8n – deployed on Hugging Face Spaces (cloud inference)  
- **Database:** Supabase – store reports, user data, and metadata  
- **Storage:** Supabase Storage – road image storage and history  
- **Map & GPS:** Google Maps Flutter plugin – visualize reports and user position  
- **Location Services:** geolocator – GPS tracking and location tagging  
- **Push Notifications:** OneSignal – road alerts and authority updates  
- **Text-to-Speech:** flutter_tts – real-time road safety voice alerts  
- **State Management:** Provider – manage user state, detection data, and UI updates  
- **Version Control:** GitHub – collaborative development  

---

## ⚙️ Key Modules
1. **Authentication & User Roles**  
   - Email/password login & registration  
   - Role-based access: *User* (reporter) & *Authority* (reviewer)

2. **Road Condition Detection**  
   - Capture or upload road images  
   - AI (YOLOv8n) detects potholes, cracks, or obstacles in real time  

3. **Report Management**  
   - Review and submit detected issues with geotagged images  
   - Sync data to Supabase for public + authority visibility  

4. **Map Visualization**  
   - Display reported issues with color-coded markers based on status or severity  

5. **Real-time Voice Safety Alerts**  
   - *Smart Drive Mode* analyzes the road in front of the vehicle using the camera  
   - AI detects damage and triggers **voice alerts** via Text-to-Speech  
   - Example: “⚠️ Pothole detected ahead. Please slow down.”  
   - Integrates with Google Maps distance tracking to warn of nearby hazards  

6. **Gamification: Road Hero System**  
   - Users earn points for reporting or verifying road issues  
   - Unlock badges for milestones (e.g., “First 10 Reports”, “Safety Guardian”)  
   - Global leaderboard to encourage engagement and local impact  
   - Points & badges stored in Supabase and synced to user profiles  

7. **Analytics Dashboard**  
   - Visual insights into frequently reported areas and issue types  

8. **Safety Alerts & Notifications**  
   - Notify users of nearby hazards or new authority updates via OneSignal  

---

## 🧩 Key Features
- Real-time AI damage detection  
- GPS-based tagging  
- Cloud-synced reports  
- Real-time **voice warnings for road hazards**  
- **Gamified user engagement** (points, badges, leaderboard)  
- Clean, intuitive UI for quick use while driving  

---

## 🔁 Workflow Overview
1. User opens Pavra app  
2. Captures or streams a road video/image  
3. AI model (YOLOv8n) analyzes the frame  
4. Detected damage tagged with GPS coordinates  
5. Pavra triggers **voice warning** if a hazard is detected nearby  
6. User reviews and submits the report  
7. Report stored in Supabase and visible on the map  
8. User earns **points and badges** for contribution  
9. Authorities view data and issue public safety alerts  

---

## 🚀 Build Steps
1. Install Flutter SDK  
2. Clone repository:  
   ```bash
   git clone https://github.com/<your-username>/pavra.git
   cd pavra
   ```
3. Install dependencies:  
   ```bash
   flutter pub get
   ```
4. Connect your device or emulator  
5. Run the app:  
   ```bash
   flutter run
   ```
6. (Optional) Set up environment variables for Supabase and Hugging Face endpoints  

---

## 🌟 Hackathon Highlights
| Feature | Description | Impact |
|----------|--------------|--------|
| **AI Detection** | Real-time YOLOv8n model detects road damage | Smart, automated road awareness |
| **Voice Alerts** | Warn drivers in real time about nearby hazards | Improves road safety instantly |
| **Gamification** | Reward users for helping their community | Boosts engagement & data reliability |
| **Open Data Dashboard** | Insights for authorities | Enables preventive maintenance |

---

## 🧭 Future Enhancements
- AR-based reporting (mark damage directly on camera view)  
- Predictive analytics to forecast high-risk areas  
- Integration with municipal maintenance systems  
- Offline AI detection support  

---

## 🏁 License
MIT License © 2025 Pavra Team  