# 🎖️ Game of the Generals (Salpakan)
A Flutter Web implementation of the classic Filipino strategy board game, with real-time 2-player support via Firebase Realtime Database.

---

## 📋 Features
- ✅ Full 21-piece set per player with correct rank hierarchy
- ✅ Automated arbiter — challenges resolved silently
- ✅ Real-time sync via Firebase Realtime Database
- ✅ Room code system — no accounts needed
- ✅ Drag-and-drop + tap-to-place piece setup
- ✅ Challenge flash animation (no rank revealed)
- ✅ Move history toggle panel
- ✅ Resign / Draw offer / Accept draw
- ✅ All win conditions: flag captured, flag marched, resignation, draw
- ✅ Responsive — mobile portrait/landscape + desktop

---

## 🚀 Setup Instructions

### 1. Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x or higher)
- A [Firebase](https://console.firebase.google.com) project

### 2. Clone & Install
```bash
cd game_of_generals
flutter pub get
```

### 3. Firebase Setup
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project (or use an existing one)
3. Enable **Realtime Database** (not Firestore)
   - Start in **test mode** for development
4. Add a **Web app** to your project
5. Copy your config values into `lib/firebase_options.dart`:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  databaseURL: 'https://YOUR_PROJECT_default-rtdb.firebaseio.com',
  storageBucket: 'YOUR_PROJECT.appspot.com',
);
```

### 4. Apply Firebase Security Rules
In Firebase Console → Realtime Database → Rules, paste the contents of `firebase_rules.json`.

### 5. Run the App
```bash
# Run in Chrome (web)
flutter run -d chrome

# Build for web deployment
flutter build web
```

---

## 🎮 How to Play

### Starting a Game
1. **Player 1** opens the app and clicks **CREATE ROOM**
2. A 6-character room code appears — share it with Player 2
3. **Player 2** opens the app on their device, clicks **JOIN ROOM**, enters the code
4. Both players are taken to the setup screen

### Setup Phase
- Each player places all 21 pieces on their **first 3 rows**
- Tap a piece in the tray to select it, then tap a square to place it
- Or drag pieces directly from the tray to the board
- When all 21 pieces are placed, click **CONFIRM DEPLOYMENT**
- Game starts when **both players** confirm

### Gameplay
- Tap your piece to select it (valid moves highlighted)
- Tap a highlighted square to move
- Tap a highlighted enemy square to challenge
- The app (arbiter) silently resolves challenges — no ranks are revealed
- A "CHALLENGE!" flash appears on both screens when a battle occurs

### Winning
- Capture the enemy Flag
- March your Flag to the opponent's back row (must be 2+ squares from any enemy)
- Opponent resigns
- Mutual draw agreement

---

## 🗂️ Project Structure
```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # 🔧 Firebase config (fill this in!)
├── models/
│   ├── piece.dart               # Piece ranks, challenge resolution logic
│   ├── board_position.dart      # Grid position model
│   └── game_state.dart          # Game state models
├── services/
│   ├── firebase_service.dart    # Firebase CRUD + arbiter logic
│   └── game_provider.dart       # State management (Provider)
├── screens/
│   ├── lobby_screen.dart        # Create/Join room
│   ├── setup_screen.dart        # Piece placement phase
│   └── game_screen.dart         # Main gameplay
├── widgets/
│   ├── board_widget.dart        # 8×9 game board
│   ├── piece_tray_widget.dart   # Setup piece tray
│   └── move_history_panel.dart  # Move log panel
└── utils/
    └── app_theme.dart           # Colors, typography, theme
```

---

## ⚠️ Known Limitations & Future Improvements
- **Arbiter fairness**: Challenge resolution runs on the moving player's client. For a competitive/tournament setup, move this to a Firebase Cloud Function.
- **Reconnection**: If a player refreshes mid-game, they'll need to re-enter the room code (no persistent session yet).
- **Timer**: No move timer implemented. Add one for competitive play.
- **Sound effects**: Hooks are in place; add audio with `just_audio` package.

---

## 🏗️ Tech Stack
- **Flutter** (Web target)
- **Firebase Realtime Database** (real-time game sync)
- **Provider** (state management)
- **flutter_animate** (animations)
- **google_fonts** (Rajdhani + Source Code Pro)
