# Jumandi Flutter App

Mobile app for **Jumandi** gas delivery — customer and delivery agent sides.

> **Note:** Current UI is a **placeholder**. Send your design (Figma, screenshots, mockups) and we will match the exact look and feel.

## What's built

| Side | Features |
|------|----------|
| **Customer** | Register/login, book gas (kg + address + GPS), view bookings, live map tracking |
| **Delivery** | Register/login, pending orders, accept, start delivery, share GPS, complete |

## Run locally

```bash
cd jumandi_app
flutter pub get
flutter run
```

Start the Python backend first (`uvicorn app.main:app --reload`).

### Backend URL

Edit `lib/config/app_config.dart`:

```dart
static const String apiBaseUrl = 'http://10.0.2.2:8000';  // Android emulator
// static const String apiBaseUrl = 'https://jumandi-api.onrender.com';  // Production
```

### Google Maps

Add your API key in `android/app/src/main/AndroidManifest.xml` for the tracking map.

## Project structure

```
lib/
├── config/       # API URL + theme (theme updated when design arrives)
├── models/
├── services/     # API, WebSocket, GPS
├── providers/
├── screens/
│   ├── auth/
│   ├── customer/
│   └── delivery/
├── widgets/
└── routes/
```

## When you send your UI design

We will update:

- Colors, fonts, spacing in `lib/config/theme.dart`
- Each screen in `lib/screens/`
- Custom widgets and assets in `assets/images/`
