<div align="center">

<img src="images/logo.jpeg" width="120" height="120" style="border-radius: 50%;" alt="CropIntel Logo"/>

# 🌿 CropIntel

### *AI-Powered Smart Farming Assistant*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)](https://flask.palletsprojects.com)
[![MongoDB](https://img.shields.io/badge/MongoDB_Atlas-47A248?style=for-the-badge&logo=mongodb&logoColor=white)](https://mongodb.com)
[![Gemini](https://img.shields.io/badge/Google_Gemini-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev)
[![Ollama](https://img.shields.io/badge/Ollama-llama3.2--vision-black?style=for-the-badge&logo=llama&logoColor=white)](https://ollama.com)

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&size=22&pause=1000&color=00EFDF&center=true&vCenter=true&width=600&lines=Detect+Plant+Diseases+with+AI+📸;Get+Real-Time+Crop+News+📰;Chat+with+an+Agricultural+Expert+🤖;Smart+Farming+Starts+Here+🌾" alt="Typing SVG" />

</div>

---

## 🌾 What is CropIntel?

**CropIntel** is a full-stack AI-powered mobile application built for farmers and agricultural professionals. It combines **on-device image analysis**, **LLM-powered chat**, **Gemini AI news**, and a **secure cloud backend** to give farmers intelligent, real-time insights about their crops — right from their phone.

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 📸 Plant Disease Detection
Upload or capture a photo of your crop. The AI model (`llama3.2-vision:11b` via Ollama) analyzes it and returns:
- Disease / deficiency identified
- Confidence level
- Recommended treatment

</td>
<td width="50%">

### 🤖 AI Crop Chat
Ask any farming question and get real-time answers from your locally-hosted LLM — diseases, soil, pests, irrigation, and more. Full **chat history saved to MongoDB**.

</td>
</tr>
<tr>
<td width="50%">

### 📰 Personalized News Feed
Powered by **Google Gemini 2.0 Flash**, generates 8 contextual news articles per request based on your region, weather, soil, and crops of interest.

</td>
<td width="50%">

### 🔐 Secure Authentication
- Email OTP verification on signup
- Password reset via OTP
- Biometric login (Fingerprint / Face ID)
- Secure password hashing (bcrypt)

</td>
</tr>
<tr>
<td width="50%">

### 👤 User Profiles
Full profile management — name, profile photo (upload to server), personalization settings (crop type, region, soil type, age, gender).

</td>
<td width="50%">

### 📡 BLE / ESP32 Integration
Scans for nearby BLE beacons (ESP32-based soil sensors) using `flutter_blue_plus` for IoT-enabled smart farming.

</td>
</tr>
</table>

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  📱 Flutter Mobile App                   │
│  Login · Signup · Chat · News · Profile · Personalize   │
└────────┬──────────────┬──────────────────┬──────────────┘
         │              │                  │
         ▼              ▼                  ▼
┌──────────────┐ ┌─────────────┐ ┌────────────────────┐
│  Flask API   │ │ Gemini News │ │ FastAPI Local AI   │
│  app.py      │ │ Server      │ │ local_ai_server.py │
│  :5000       │ │ :8001       │ │ :8000              │
│              │ │             │ │                    │
│ • Auth/OTP   │ │ • News Feed │ │ • /analyze-plant   │
│ • Profiles   │ │ • Gemini AI │ │ • /chat            │
│ • Chat Store │ └─────────────┘ └────────┬───────────┘
│              │                          │
└──────┬───────┘                          ▼
       │                         ┌─────────────────┐
       ▼                         │  Ollama Server  │
┌─────────────┐                  │ llama3.2-vision │
│ MongoDB     │                  │  :11434         │
│ Atlas       │                  └─────────────────┘
│             │
│ • users     │
│ • chat_     │
│   sessions  │
└─────────────┘
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | ≥ 3.x |
| Python | 3.11 |
| MongoDB Atlas | Cloud account |
| Ollama | Latest + `llama3.2-vision:11b` pulled |
| Google Gemini API Key | [Get one here](https://ai.google.dev) |

---

### 📱 Flutter App Setup

```bash
# 1. Clone the repository
git clone https://github.com/somesh-opps/BitVerse.git
cd BitVerse

# 2. Install Flutter dependencies
flutter pub get

# 3. Run on your device
flutter run
```

> **Set your server IP** in `lib/chat_screen.dart`:
> ```dart
> static const String _serverBaseUrl = 'http://<YOUR_PC_IP>:8000';
> static const String _appBaseUrl    = 'http://<YOUR_PC_IP>:5000';
> ```
> And in `lib/api_service.dart`:
> ```dart
> static const String _base        = 'http://<YOUR_PC_IP>:5000';
> static const String _geminiBase  = 'http://<YOUR_PC_IP>:8001';
> ```

---

### 🐍 Backend Setup (Main API — Flask)

```bash
cd backend

# Create virtual environment
python -m venv .venv
.venv\Scripts\activate        # Windows
source .venv/bin/activate     # macOS/Linux

# Install dependencies
pip install flask flask-cors pymongo werkzeug

# Run
python app.py
# ✅ Serving on http://0.0.0.0:5000
```

---

### 🤖 Local AI Server Setup (FastAPI + Ollama)

```bash
# Install dependencies
pip install fastapi uvicorn httpx python-multipart

# Make sure Ollama is running with the vision model
ollama pull llama3.2-vision:11b
ollama serve

# Run the AI server
uvicorn local_ai_server:app --host 0.0.0.0 --port 8000
# ✅ Serving on http://0.0.0.0:8000
```

---

### 📰 Gemini News Server Setup

```bash
# Install dependencies
pip install flask flask-cors google-genai

# Set API key (or edit gemini_news_server.py directly)
set GEMINI_API_KEY=your_key_here   # Windows
export GEMINI_API_KEY=your_key_here # Linux/macOS

# Run
python gemini_news_server.py
# ✅ Serving on http://0.0.0.0:8001
```

---

## 🌐 API Reference

### Main Backend (`app.py` — port `5000`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/send-otp` | Send OTP to email for registration |
| `POST` | `/register` | Register new user |
| `POST` | `/login` | Login with username/email + password |
| `POST` | `/reset-password/send-otp` | Send OTP for password reset |
| `POST` | `/reset-password/verify-otp` | Verify reset OTP |
| `POST` | `/reset-password/reset` | Set new password |
| `POST` | `/personalization` | Save personalization settings |
| `GET`  | `/personalization` | Get personalization settings |
| `POST` | `/profile/update` | Update profile name |
| `POST` | `/profile/upload-image` | Upload profile photo |
| `POST` | `/chat/sessions/save` | Save a chat session |
| `GET`  | `/chat/sessions` | Load all chat sessions |
| `DELETE` | `/chat/sessions/<id>` | Delete a chat session |

### Local AI Server (`local_ai_server.py` — port `8000`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/analyze-plant` | Analyze plant image for disease |
| `POST` | `/chat` | Ask agricultural text questions |

### Gemini News Server (`gemini_news_server.py` — port `8001`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/news-feed` | Generate 8 contextual news articles |

---

## 📁 Project Structure

```
CropIntel/
├── lib/                          # Flutter source
│   ├── main.dart                 # Entry point
│   ├── splash_screen.dart        # Animated splash
│   ├── login_screen.dart         # Login with biometrics
│   ├── signup_screen.dart        # OTP-verified signup
│   ├── forgot_password_screen.dart
│   ├── home_screen.dart          # Dashboard
│   ├── chat_screen.dart          # AI chat + image diagnosis
│   ├── news_detail_screen.dart   # News article viewer
│   ├── personalization_screen.dart
│   ├── profile_screen.dart       # Profile + photo upload
│   ├── api_service.dart          # HTTP service layer
│   ├── user_session.dart         # Singleton session store
│   └── gradient.dart             # Aurora background widget
│
├── backend/
│   ├── app.py                    # Flask main API (auth, profiles, chat)
│   ├── gemini_news_server.py     # Gemini 2.0 Flash news generator
│   ├── local_ai_server.py        # FastAPI Ollama vision wrapper
│   ├── ollama_server.py          # Alternate Ollama Flask wrapper
│   └── uploads/
│       └── profile_images/       # Stored user profile photos
│
├── android/                      # Android configuration
├── images/                       # App assets (logo etc.)
└── pubspec.yaml                  # Flutter dependencies
```

---

## 📦 Tech Stack

### Mobile (Flutter)
| Package | Purpose |
|---------|---------|
| `http` + `http_parser` | HTTP requests & multipart uploads |
| `image_picker` | Camera / gallery image selection |
| `local_auth` | Fingerprint / Face ID |
| `flutter_blue_plus` | BLE / ESP32 sensor scanning |
| `shared_preferences` | Local storage |
| `fl_chart` + `syncfusion_flutter_charts` | Data visualisation |
| `lottie` | Animated illustrations |
| `shimmer` | Loading skeleton UI |

### Backend (Python)
| Library | Purpose |
|---------|---------|
| `Flask` | REST API framework |
| `FastAPI` + `uvicorn` | Async AI server |
| `pymongo` | MongoDB Atlas driver |
| `werkzeug` | Password hashing |
| `httpx` | Async HTTP client (Ollama) |
| `google-genai` | Gemini AI SDK |

---

## 🗄️ Database Schema (MongoDB Atlas)

### `users` collection
```json
{
  "name": "string",
  "user_id": "string (unique)",
  "email": "string (unique)",
  "password_hash": "string",
  "profile_image": { "filename": "...", "url": "..." },
  "personalization": {
    "age": 28, "gender": "Male",
    "crop_type": "Rice", "region": "South India", "soil_type": "Loamy"
  },
  "created_at": "ISODate"
}
```

### `chat_sessions` collection
```json
{
  "user_id": "string",
  "session_id": "string",
  "title": "string",
  "messages": [
    { "text": "...", "is_user": true, "time": "9:00 AM", "has_image": false }
  ],
  "created_at": "ISODate",
  "updated_at": "ISODate"
}
```

---

## ⚙️ Android Permissions

The following permissions are declared in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
```

`android:usesCleartextTraffic="true"` is enabled for local Wi-Fi server communication.

---

## 🔮 Roadmap

- [ ] 🌤️ Live weather integration (OpenWeatherMap)
- [ ] 🗺️ GPS-based field mapping
- [ ] 📊 Crop yield prediction dashboard
- [ ] 🌍 Multi-language support (Hindi, Telugu, Tamil)
- [ ] 🔔 Push notifications for disease alerts
- [ ] 📴 Offline mode with cached AI responses
- [ ] 🤝 Farmer community forum

---

## 👥 Team

Built with 💚 by **BitVerse**

---

## 📄 License

This project is private and proprietary to **BitVerse**.

---

<div align="center">

**🌿 Empowering Farmers with AI — CropIntel 🌿**

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&size=14&pause=2000&color=00C896&center=true&vCenter=true&width=500&lines=Made+with+💚+by+BitVerse;Smarter+Farming+for+a+Better+Tomorrow" alt="footer" />

</div>
