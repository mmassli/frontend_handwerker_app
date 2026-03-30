# Handwerker Marketplace — Flutter Frontend

A production-ready Flutter mobile app for an on-demand repair marketplace connecting customers (Kunden) with verified craftsmen (Handwerker). Supports both iOS and Android with responsive design and micro-animations.

## Architecture

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── theme/app_theme.dart           # Design system (dark/light, typography, colors)
│   ├── constants/api_constants.dart   # API endpoints & app constants
│   ├── animations/micro_animations.dart # Custom animation widgets
│   └── navigation/app_router.dart     # GoRouter configuration
├── data/
│   ├── models/models.dart             # All data models (JSON serializable)
│   ├── services/api_service.dart      # Dio HTTP client with auth interceptor
│   └── providers/app_providers.dart   # Riverpod state management
└── presentation/
    ├── screens/
    │   ├── auth/                      # Login, OTP, Onboarding, Consent
    │   ├── customer/                  # Home, Create Order, Proposals, Tracking, Rating, Profile
    │   ├── craftsman/                 # Dashboard, Job Requests, Active Job, Wallet, Profile
    │   └── shared/                    # Chat, Notifications
    └── widgets/                       # Reusable components (cards, forms, maps)
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.19+ / Dart 3.2+ |
| **State Management** | Riverpod 2.x |
| **Navigation** | GoRouter (declarative, deep-link ready) |
| **Networking** | Dio with JWT auth interceptor + token refresh |
| **Animations** | Custom micro-animations + flutter_animate |
| **Maps** | Google Maps Flutter |
| **Payments** | Flutter Stripe |
| **Push** | Firebase Cloud Messaging |
| **Storage** | flutter_secure_storage (tokens), Hive (cache) |

## Design System

- **Theme**: Industrial-craft aesthetic with dark slate backgrounds and warm amber (#E8A917) accents
- **Typography**: Satoshi (display) + GeneralSans (body) — distinctive, non-generic
- **Animations**: Staggered entry animations, tap-scale micro-interactions, pulsing glow indicators, animated counters
- **Dark/Light mode**: Full theme support with automatic system detection

## Setup

```bash
# 1. Clone and install
cd handwerker_app
flutter pub get

# 2. Generate code (JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Add fonts
# Download Satoshi and GeneralSans from fontsource.org
# Place .otf files in assets/fonts/

# 4. Configure API
# Edit lib/core/constants/api_constants.dart
# Set baseUrl to your Spring Boot backend

# 5. Firebase setup (for push notifications)
# flutterfire configure

# 6. Google Maps API key
# Android: android/app/src/main/AndroidManifest.xml
# iOS: ios/Runner/AppDelegate.swift

# 7. Stripe publishable key
# Set in initialization or environment config

# 8. Run
flutter run
```

## Backend Integration

The app is designed to work with the Spring Boot 4.x / Kotlin backend defined in `handwerker-api.yaml`. All API endpoints are mapped in `ApiConstants` and called through `ApiService`.

**Auth flow**: Phone OTP → JWT tokens → Secure storage → Auto-refresh interceptor

## Screens Overview

### Auth Flow
1. **Onboarding** — 3-page introduction with animated page transitions
2. **Login** — Phone number input with German flag prefix
3. **OTP** — 6-digit code input with auto-advance and shake error animation
4. **GDPR Consent** — Three checkboxes for terms, privacy, data processing

### Customer Flow
1. **Home** — Emergency banner, service categories grid, active orders carousel
2. **Create Order** — 4-step form: category → type → description/media → review
3. **Proposals** — Live-polling ranked list with craftsman cards
4. **Order Tracking** — Map view, status timeline, action buttons
5. **Rating** — 4-category star rating with recommend toggle

### Craftsman Flow
1. **Dashboard** — Online toggle with pulse animation, wallet card, active jobs
2. **Job Request** — Order details with proposal form (price, ETA, comment)
3. **Active Job** — Step-by-step status progression (on-the-way → arrived → started → complete)
4. **Wallet** — Balance with animated counter, payout request bottom sheet

### Shared
- **Chat** — Order-scoped messaging with bubble UI
- **Notifications** — Typed notification list with read/unread states
- **Profile** — Settings, dark mode toggle, logout

## Key Features

- **Offline-aware**: Connectivity handling ready for background sync
- **Responsive**: Text scaling clamped, adaptive layouts
- **Accessible**: Semantic labels, sufficient contrast ratios
- **Secure**: Tokens in flutter_secure_storage, refresh rotation, no plaintext secrets
- **German-first**: All UI strings in German (i18n-ready structure for English/other)

## Next Steps

- [ ] Add `flutter_localizations` and ARB files for i18n
- [ ] Implement WebSocket for real-time chat and order status updates
- [ ] Add Google Maps integration with live craftsman tracking
- [ ] Stripe payment sheet integration
- [ ] Firebase push notification handlers
- [ ] Unit and widget tests
- [ ] CI/CD pipeline (Codemagic or GitHub Actions)
