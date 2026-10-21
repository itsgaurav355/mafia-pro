# 🎭 Mafia Pro — Offline Moderator Console

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Author](https://img.shields.io/badge/Author-Gaurav%20Prajapati-orange.svg)](https://github.com/itsgaurav355)
[![GitHub](https://img.shields.io/badge/GitHub-itsgaurav355-181717.svg?logo=github)](https://github.com/itsgaurav355)
[![Instagram](https://img.shields.io/badge/Instagram-@gaurav.build-E4405F.svg?logo=instagram&logoColor=white)](https://instagram.com/gaurav.build)
[![YouTube](https://img.shields.io/badge/YouTube-@gaurav.build1-FF0000.svg?logo=youtube&logoColor=white)](https://youtube.com/@gaurav.build1)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green.svg)](#-pre-built-releases--downloads)
[![Storage](https://img.shields.io/badge/Storage-100%25%20Offline%20SQLite-blueviolet.svg)](#-architecture--tech-stack)
[![Tests](https://img.shields.io/badge/Tests-29%20Passing-success.svg)](#-running-tests)
[![License](https://img.shields.io/badge/License-MIT-amber.svg)](LICENSE)

A standalone, **100% offline mobile game-moderation console** engineered in Flutter by **Gaurav Prajapati**. **Mafia Pro** replaces paper slips, handwritten notes, spreadsheets, and complex physical setups for real-world **Mafia / Werewolf** social deduction party games.

With a single smartphone, the game moderator manages a saved player roster, cryptographically shuffles roles, conducts private "Hold-to-Reveal" handoffs, orchestrates complex night actions with zero information leakage, enforces game balance, and automatically resolves win conditions.

---

## 📦 Pre-Built Releases & Downloads

Pre-compiled production releases for both **Android** and **iOS** are available directly in the repository under the [`releases/`](file:///Users/gauravprajapati/Desktop/Gaurav%20Work/mafia_pro/releases) directory:

| Platform | Format | Release File | Size | Compatibility | Installation Method |
| :--- | :---: | :--- | :---: | :---: | :--- |
| **Android** | `.apk` | [**`releases/MafiaPro-v1.0.0.apk`**](file:///Users/gauravprajapati/Desktop/Gaurav%20Work/mafia_pro/releases/MafiaPro-v1.0.0.apk) | `~59 MB` | Android 7.0+ (API 24+) | Direct APK Install / Sideloading |
| **iOS** | `.ipa` | [**`releases/MafiaPro-v1.0.0.ipa`**](file:///Users/gauravprajapati/Desktop/Gaurav%20Work/mafia_pro/releases/MafiaPro-v1.0.0.ipa) | `~8.4 MB` | iOS 13.0+ | AltStore / Sideloadly / TrollStore / Xcode |
| **iOS (App)** | `.app` | [`build/ios/iphoneos/Runner.app`](file:///Users/gauravprajapati/Desktop/Gaurav%20Work/mafia_pro/build/ios/iphoneos/Runner.app) | `~21 MB` | iOS 13.0+ (ARM64) | Xcode / Apple Configurator deployment |

### 📲 How to Install the Builds

#### Android (.apk)
1. Transfer or download [`releases/MafiaPro-v1.0.0.apk`](file:///Users/gauravprajapati/Desktop/Gaurav%20Work/mafia_pro/releases/MafiaPro-v1.0.0.apk) to your Android device.
2. Tap the downloaded `.apk` in your file manager or browser downloads.
3. If prompted, toggle **"Allow installation from unknown sources"** for your browser/file manager.
4. Tap **Install** and launch **Mafia Pro**.

#### iOS (.ipa)
Because iOS requires apps to be code-signed before running on non-jailbroken devices, use any standard sideloading tool:
* **Option A — AltStore / SideStore:** Open AltStore on your iPhone, tap `+` in My Apps, select `MafiaPro-v1.0.0.ipa`, and install with your free Apple ID.
* **Option B — Sideloadly (macOS / Windows):** Connect your iPhone via USB, drag `MafiaPro-v1.0.0.ipa` into Sideloadly, enter your Apple ID, and click **Start**.
* **Option C — Xcode (Developers):**
  ```bash
  xcrun devicectl device install app --device <YOUR_DEVICE_ID> "releases/MafiaPro-v1.0.0.ipa"
  ```
* **Option D — TrollStore:** If running a supported iOS version with TrollStore, open the `.ipa` directly in TrollStore for instant installation without revokes.

---

## ✨ Key Capabilities

* 📱 **Single-Device Host System:** Only the moderator needs the app installed. Players never need to download anything or join Wi-Fi networks.
* 👥 **Persistent Roster Management:** Add friends once with custom avatar colors and nicknames. Reusable across every party session with soft-delete support to preserve historical records.
* ⚖️ **Dynamic Auto-Balancer & Ratios:** Live party balance calculation. Warns when Mafia is overpowered (≥50%) or nonexistent, with one-tap automatic role balancing according to group size (4–30+ players).
* 🔒 **Anti-Peeking "Hold to Reveal":** Pass-the-phone handoff screen featuring capacitive hold-to-reveal cards, tactile haptics, and a shielded handoff veil that prevents accidental shoulder-surfing.
* 🌙 **Guided Night Phase Orchestrator:** Step-by-step role call sequence (Mafia, Doctor, Commissioner, Vigilante, Bodyguard, Escort, Maniac). Roles with eliminated players are skipped silently so the narrator's screen never leaks deaths.
* ☀️ **Automated Dawn Resolution:** Computes cross-interactions between Mafia attacks, Doctor saves, Bodyguard sacrifices, and Escort role-blocks, generating an instant morning summary.
* ⏱️ **Integrated Day Discussion Timer:** Built-in configurable countdown timer (with preset durations) to keep arguments and trials moving quickly.
* 🏆 **Instant Win Detection:** Continuously evaluates Town, Mafia, Jester, and Maniac victory triggers after every morning death or town vote.
* 🔄 **Fail-Safe Resume & Event Sourcing:** Full SQLite event sourcing records every decision. If the phone turns off or the app restarts, the ongoing round can be resumed seamlessly with zero state loss.
* 🕯️ **Cyber-Noir Aesthetic:** Handcrafted dark palette (`#090B10`), glowing neon accents, card borders, and smooth Lottie micro-animations designed for low-light party rooms.
* 🔋 **Wakelock Protection:** Keeps the screen awake during active matches to prevent annoying lock-screen timeouts mid-round.

---

## 🎭 Role Roster (11 Built-In Roles)

Mafia Pro includes 11 roles with custom rules, night actions, and behaviors:

| Role | Team | Night Action | Priority / Resolution Order | Description & Strategic Rules |
| :--- | :---: | :---: | :---: | :--- |
| **Don** | **Mafia** | Lead Kill Vote | 2 | Godfather of the syndicate. Selects the target for the Mafia kill. Appears **"Innocent"** to the Commissioner's investigation! |
| **Mafia** | **Mafia** | Group Kill Vote | 2 | Syndicate member. Votes on the night kill with the Don and knows the identity of all other Mafia members. |
| **Doctor** | **Town** | Night Heal | 3 | Protects one player from elimination each night. Configurable consecutive-save rule prevents healing the same person two nights in a row. |
| **Commissioner** | **Town** | Investigate | 4 | Inspects one player per night to reveal if they belong to the Mafia (except the Don, who inspects clean). |
| **Civilian** | **Town** | None | — | Ordinary citizen. Uses deduction, behavioral analysis, and voting power during the day phase to hang the Mafia. |
| **Vigilante** | **Town** | One-Shot Kill | 5 | Lone gunslinger with a single bullet. Can choose to eliminate one player during any night phase (use-it-or-lose-it). |
| **Bodyguard** | **Town** | Shield Guard | 1 | Designates one player to protect. If that player is attacked, the Bodyguard dies in their place! |
| **Escort** | **Town** | Role Block | 0 (First) | Distracts one player each night, nullifying their night ability for that round. Cannot block the same target consecutively. |
| **Detective Sidekick** | **Town** | Passive | — | Stays undercover. If the Commissioner is eliminated, the Sidekick secretly inherits their investigation mantle. |
| **Jester** | **Neutral** | None | — | Chaos agent. Has a solitary objective: **convince the town to vote them out during the day**. If voted out, the Jester wins alone instantly! |
| **Maniac** | **Neutral** | Solo Serial Kill | 6 | Rogue serial killer acting alone. Eliminates one player every night. Wins if they are the last survivor or 1v1 with any other player. |

### Win Conditions
* **Town Victory:** All Mafia members (including the Don) and rogue killers (Maniac) are eliminated.
* **Mafia Victory:** Mafia members equal or outnumber the surviving non-Mafia players.
* **Jester Victory:** The town votes to eliminate the Jester during any day phase (triggers immediate game over).
* **Maniac Victory:** The Maniac is the final surviving player, or only 1 opponent remains.

---

## 📖 Complete "How to Use It" Guide

### Step 1: Manage Your Player Roster
1. Open the app and tap the **Players** tab at the bottom.
2. Tap the `+` button to add your friends with their **Name**, optional **Nickname**, and an **Avatar Color**.
3. *Tip:* Players are saved permanently in local SQLite. You only need to enter them once!
4. Swipe left or tap a player tile to edit details or remove someone who is absent.

```text
[Players Tab] ➔ Add Player ("Alice", "Bob", "Charlie", "Diana", ...)
```

---

### Step 2: Start a New Match
1. Go to the **Play** tab and tap **Start New Game**.
2. Select tonight's attendees by checking their names (minimum 4 players).
3. Need to include a last-minute guest? Use the **Quick-Add Guest** field at the top to add them on the fly without cluttering your permanent roster.
4. Tap **Configure Roles & Balance**.

---

### Step 3: Configure & Auto-Balance Roles
1. The app displays recommended role counts based on your group size:
   * **4–5 Players:** 1 Mafia (Don), 1 Commissioner, 0–1 Doctor, rest Civilians.
   * **6–7 Players:** 2 Mafia (Don + 1), 1 Commissioner, 1 Doctor, 0–1 Special.
   * **8–10 Players:** 3 Mafia (Don + 2), 1 Commissioner, 1 Doctor, 1–2 Specials.
   * **11+ Players:** Proportional syndicate size with Bodyguard, Escort, Vigilante, or Maniac.
2. Tap **Auto Balance** to have the algorithm populate optimal role slots instantly.
3. Toggle individual special roles (Bodyguard, Escort, Vigilante, Jester, Maniac) on or off according to your group's taste.
4. If Mafia has $\ge 50\%$ or $0\%$ of the room, a warning banner will alert you before starting.
5. Tap **Deal Roles & Start**.

---

### Step 4: Secret Role Reveal ("Pass the Phone")
1. The moderator passes the phone to the first player listed on screen.
2. The player taps their name to open the **Hold-to-Reveal** card.
3. **Press and hold the card** for 0.8 seconds to see your secret role, team allegiance, and ability description. (Mafia members will also see their fellow syndicate partners if enabled in settings).
4. Release the finger to immediately conceal the role.
5. Tap **Pass to Next Player** and hand the device to the next person.
6. Once the final player confirms, the moderator reclaims the device and begins the game.

---

### Step 5: Moderate the Night Phase
1. Announce aloud to the room: *"Night falls over the town. Everyone, close your eyes."*
2. The app presents action prompt cards in strict resolution order:
   * **Escort:** *"Whom does the Escort distract tonight?"* ➔ Tap target.
   * **Bodyguard:** *"Whom is the Bodyguard protecting?"* ➔ Tap target.
   * **Mafia Syndicate:** *"Mafia, wake up and select your target."* ➔ Tap victim.
   * **Doctor:** *"Doctor, wake up. Whom do you wish to heal?"* ➔ Tap target.
   * **Commissioner:** *"Commissioner, wake up. Choose someone to investigate."* ➔ Tap target. (The app reveals a private "MAFIA" or "NOT MAFIA" badge to the screen).
   * **Vigilante / Maniac:** Call actions if alive and enabled.
3. *Ghost Protection:* If a role's holder is already dead, the app skips that prompt without giving away who is alive or dead.
4. Tap **Resolve Night**.

---

### Step 6: Morning Announcement & Dawn
1. The app computes all nocturnal actions behind the scenes:
   * If Mafia attacked `Alice`, but Doctor healed `Alice` ➔ **Alice survived!**
   * If Bodyguard guarded `Bob` and Mafia shot `Bob` ➔ **Bodyguard sacrificed their life for Bob!**
2. Announce the morning news displayed on the summary card:
   > *"The sun rises. Last night, Bob was found dead in the town square."* (or *"Miraculously, nobody died last night!"*)
3. The eliminated player's role is revealed on death (or kept hidden, depending on your settings).

---

### Step 7: Day Discussion & Town Vote
1. Announce: *"Town, discuss and deliberate!"*
2. Start the built-in **Discussion Timer** (default: 90 seconds, pause/reset anytime).
3. Once accusations and defenses conclude, call for the vote.
4. In the app:
   * Tap the nominated player to eliminate them by vote.
   * Or tap **"No Elimination"** if the town deadlocked or voted to skip.
5. The app records the vote into the event log and checks win conditions.

---

### Step 8: Game Over & Match Archive
1. When a team fulfills its win condition, the app transitions to the **Victory Screen**:
   * Animated victory trophy & theme-colored banners (Town Blue, Mafia Red, or Jester Gold).
   * Complete player reveal table showing who was what.
   * Full round-by-round event timeline log.
2. Tap **Share Summary** to export the match results via the system share sheet.
3. Tap **Save & Return Home** to archive the match in SQLite.

---

## ⚙️ Game Settings & House Rules

Access customizable rules by tapping the **Settings** icon on the top right:

| Rule Toggle | Default | Description |
| :--- | :---: | :--- |
| **Reveal Role on Death** | `Enabled` | When a player is killed or lynched, announce their role aloud. Disable for hardcore "graveyard mystery" mode. |
| **Doctor Self-Save** | `Enabled` | Allows the Doctor to target themselves for protection. |
| **Consecutive Save Rule** | `Enabled` | Prevents the Doctor and Escort from targeting the exact same player on consecutive nights. |
| **Mafia Teammate Visibility** | `Enabled` | Shows syndicate members each other's identities during the role reveal phase. |
| **Discussion Timer** | `90 sec` | Duration of the day debate countdown timer (customizable from 30s to 300s). |

---

## 🏗️ Architecture & Tech Stack

```text
lib/
├── app.dart                    # App root, MultiBlocProvider & dark theme
├── main.dart                   # Entry point, Wakelock initialization & DI setup
├── core/
│   ├── constants/              # AppColors, GameConstants, role suggested ratios
│   ├── di/                     # GetIt dependency injection registry
│   ├── theme/                  # Cyber-noir dark ThemeData (Outfit & Inter fonts)
│   └── widgets/                # GlowCard, HoldToReveal, AppLottie, ConfirmDialog
├── data/
│   ├── datasources/            # Local SQLite database helper & schema migrations
│   └── repositories/           # Concrete implementations of repositories
├── domain/
│   ├── engine/                 # Pure Dart game engine: NightResolver, WinChecker
│   ├── entities/               # Player, Game, Role, GamePlayer, GameEvent
│   ├── repositories/           # Abstract repository contracts
│   └── roles/                  # Role registry & individual role behavior classes
└── features/
    ├── home/                   # Dashboard, active game resume banner & quick stats
    ├── roster/                 # Player database management (CRUD)
    ├── game_setup/             # Player selection, role picker & auto-balance
    ├── role_reveal/            # Hold-to-reveal phone handoff flow
    ├── game_play/              # Night orchestrator, morning dawn & day voting
    ├── game_over/              # Victory celebration, all-player reveal & logs
    ├── history/                # Historical match archive & log viewer
    └── settings/               # Rule toggles & preference persistence
```

* **Framework:** [Flutter](https://flutter.dev) (v3.47+ / Dart 3.13+)
* **State Management:** [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) (BLoC for game engine orchestration, Cubit for UI screens)
* **Dependency Injection:** [`get_it`](https://pub.dev/packages/get_it)
* **Local Persistence:** [`sqflite`](https://pub.dev/packages/sqflite) with event-sourced game state recovery
* **Haptics & Screen:** [`wakelock_plus`](https://pub.dev/packages/wakelock_plus) for continuous display illumination
* **Animations:** [`lottie`](https://pub.dev/packages/lottie) with bundled offline JSON animations
* **Sharing:** [`share_plus`](https://pub.dev/packages/share_plus) for match logs export

---

## 🛠️ Developer Setup & Build Instructions

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.13.5`)
* Dart SDK (`>= 3.13.5`)
* **Android:** Android Studio / Android SDK (API 34+)
* **iOS:** macOS with Xcode 15+ installed

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/itsgaurav355/mafia-pro.git
cd mafia-pro

# Fetch Flutter dependencies
flutter pub get
```

### 2. Run the App Locally
```bash
# Launch on connected phone, simulator, or desktop
flutter run
```

### 3. Run Automated Tests
The test suite validates role distribution, cryptographic shuffling, night action resolutions, and win condition logic:
```bash
flutter test
```

### 4. Build Android Release APK
To compile an installable release APK:
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 5. Build iOS App & Package IPA
To build for iOS and generate an IPA:
```bash
# 1. Build the iOS application bundle (unsigned)
flutter build ios --no-codesign

# 2. Package Runner.app into an IPA
mkdir -p Payload
cp -R build/ios/iphoneos/Runner.app Payload/
zip -r -9 releases/MafiaPro-v1.0.0.ipa Payload
rm -rf Payload
```

---

## 👨‍💻 Creator & Socials

**Mafia Pro** is built and engineered by **Gaurav Prajapati**.

* 🌐 **GitHub:** [@itsgaurav355](https://github.com/itsgaurav355)
* 📸 **Instagram:** [@gaurav.build](https://instagram.com/gaurav.build)
* 🎥 **YouTube:** [@gaurav.build1](https://youtube.com/@gaurav.build1)

Feel free to connect, report issues, or suggest new roles and feature ideas!

---

## ⚖️ Rights & License

Copyright © 2026 **Gaurav Prajapati** ([@itsgaurav355](https://github.com/itsgaurav355)). All rights reserved.

This project is licensed under the [MIT License](LICENSE) — you are free to use, modify, and distribute this software for personal and commercial gaming sessions with appropriate attribution.
