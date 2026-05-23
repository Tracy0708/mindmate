# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run in debug mode
flutter build apk        # Build Android APK
flutter analyze          # Lint (uses flutter_lints)
flutter test             # Run all tests
flutter test test/path/to/test.dart  # Run a single test file
```

To seed demo data into Firestore (requires Node.js 22+):
```bash
node functions/seed-demo-data.js
```

Demo accounts (from `SEED_DATA_README.md`): see that file for credentials.

## Architecture

MindMate is a Firebase-backed mental health Flutter app using **MVVM with Provider**.

### Layer responsibilities

- **`lib/models/`** — Plain data classes (`UserModel`, `EmotionLog`, `GamificationHistory`, `ChatbotSession`, `Badge`, `Activity`, `EmotionInsight`, `NotificationModel`, `UserSettings`, `AiAssistant`). No logic here.
- **`lib/services/`** — All Firebase and platform I/O. Services talk to Firestore/Auth/FCM directly and are injected into ViewModels. Key services: `AuthService`, `EmotionService`, `GamificationService`, `ChatbotService`, `NotificationService`, `AdminService`, `FCMService`, `LocalNotificationService`, `InteractiveMessageService`.
- **`lib/viewmodels/`** — Seven `ChangeNotifier` classes that hold screen state and call services. Registered globally via `MultiProvider` in `main.dart`. Never read Firestore directly — always go through a service.
- **`lib/screens/`** — UI only. Screens call `context.read<XViewModel>()` to trigger actions and `context.watch<XViewModel>()` to rebuild on state changes.
- **`lib/widgets/`** — Reusable UI components shared across screens.

### ViewModels

| ViewModel | Responsibility |
|---|---|
| `ThemeViewModel` | Dark mode toggle, persisted via SharedPreferences |
| `ProfileViewModel` | User settings, notification preferences |
| `EmotionViewModel` | Mood logging, daily check-ins, streak tracking |
| `InsightsViewModel` | Analytics with date-range filtering (week/month/3 months) |
| `GamificationViewModel` | Points, badges, leaderboard |
| `ChatbotViewModel` | Chat sessions and message history |
| `AdminViewModel` | User management, mood-risk detection, platform stats |

### App startup & routing

`main()` initializes Firebase, Google Sign-In, local notifications, and FCM background handler, then registers all ViewModels via `MultiProvider`.

Initial route is `/splash` — a `StreamBuilder` on `FirebaseAuth.instance.authStateChanges()` that routes admins to `/admin-dashboard` and regular users to `/dashboard`. A global `NavigatorKey` allows FCM push notifications to navigate programmatically.

The main user flow is a bottom-navigation shell (`/dashboard`) with five tabs: Home, Insights, Calendar, Chat, Profile.

### Firebase

- **Auth**: Email/password + Google Sign-In
- **Firestore**: Primary store. Collections: `users`, `emotion_logs`, `activities`, `notifications`, `gamification`. Custom compound indexes defined in `firestore.indexes.json`.
- **FCM**: Push notifications that can deep-link into the notification center screen.
- **Cloud Functions**: Referenced in pubspec; backend logic lives in `functions/`.

### Theme

Custom color palette (`AppColors`) uses a Golden/Cream/Brown/Dark scheme. Light and dark themes are both defined in `main.dart` and switched via `ThemeViewModel`.
