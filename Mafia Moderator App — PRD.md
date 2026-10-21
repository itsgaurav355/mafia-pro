# Mafia Moderator App — PRD

Oct 18, 2026 · @Gaurav

A fully offline Flutter app that lets a moderator pick any number of players from a saved roster, randomly assign Mafia-game roles, and run the night and day phases on one phone.

## 1. Overview and goals

The app replaces the paper slips and the human narrator's notes in a physical Mafia/Werewolf-style party game. One device (the moderator's phone) handles player roster, role assignment, secret role reveal, and night/day tracking. Everything is stored in local SQLite; there is no account, server or internet requirement.

**Goals**

- Set up a game of any size (minimum 4 players) in under 60 seconds using saved player names.
- Assign roles randomly and reveal each one privately without the moderator seeing anything they shouldn't leak.
- Track who is alive, who was saved, who was killed, and detect the win condition automatically.
- Keep a reusable roster and a history of past games, all offline.

**Non-goals for v1**

- Online or multiplayer play across several phones.
- Voice chat, accounts, cloud sync, or in-app purchases.
- Automated narration or audio (listed as a v2 idea).

**Engineering goals**

- One dark theme only; there is no light mode and no theme switch.
- Structured, layered code (data, domain, features) where game rules live in pure Dart and can be tested without Flutter.
- Reusable pieces: shared widgets, repository interfaces, and one class per role so adding a role touches one file and one registry line.

## 2. Users and core scenarios

The primary user is the **moderator**: the friend who runs the game at a party, hostel or classroom. Players do not need the app; they only look at the screen briefly to see their own role.

1. **Prepare the group.** The moderator adds friends once and reuses them for every future game.
2. **Start a game.** They tick who is playing tonight, choose a role setup, and let the app deal roles.
3. **Pass the phone.** Each player taps their name, sees their role, and hides it again.
4. **Run the rounds.** The moderator calls the night actions in order, records them, and announces the morning result.
5. **Finish and review.** The app declares the winning team and saves the game so it can be viewed later.

## 3. Roles

v1 ships eleven built-in roles, and the moderator can switch each one on or off for every game. Each is a row in a `roles` table, so adding more later needs no code change to the data layer. The moderator can set the count of each role before dealing, and the app warns when the Mafia team would be too strong or too weak.

| Role | Team | Night action | Notes |
| --- | --- | --- | --- |
| Don | Mafia | Leads the Mafia vote on who to kill | Appears as "innocent" to the Commissioner's check |
| Mafia | Mafia | Votes on the kill with the Don | Knows the other Mafia members |
| Commissioner | Town | Checks one player: Mafia or not | Sees the result privately |
| Doctor | Town | Saves one player from the kill | Cannot save the same player two nights in a row (configurable) |
| Detective Sidekick (optional) | Town | Learns the Commissioner's identity if the Commissioner dies | Off by default |
| Vigilante | Town | One-time kill of any player | Single use |
| Civilian | Town | None | Votes during the day |
| Jester | Neutral | None | Wins alone if voted out by the town |

**Extra roles you can toggle on**

| Role | Team | Night action | Notes |
| --- | --- | --- | --- |
| Bodyguard | Town | Protects one player and dies in their place if that player is attacked | Suggested only from 10 players |
| Escort | Town | Blocks one player's night action | Cannot block the same player two nights in a row |
| Maniac | Neutral | Kills one player each night alone | Wins as the last survivor, or with one other player left |

**Suggested role counts** (shown when the moderator picks players; every number stays editable and any role can be toggled off). Mafia is roughly one player per 3 to 4 players, and never half or more of the group.

| Players | Mafia (Don + others) | Commissioner | Doctor | Optional special roles | Civilians |
| --- | --- | --- | --- | --- | --- |
| 4–5 | 1 (Don only) | 1 | 0–1 | 0 | the rest |
| 6–7 | 2 (Don + 1) | 1 | 1 | 0–1 | the rest |
| 8–10 | 3 (Don + 2) | 1 | 1 | 1–2 | the rest |
| 11–14 | 4 (Don + 3) | 1 | 1 | 2–3 | the rest |
| 15–20 | 5 (Don + 4) | 1 | 1 | 3–4 | the rest |
| 21–30 | 7 (Don + 6) | 1 | 1 | 4–5 | the rest |

When special roles are enabled, the app fills the optional slots in this order: Vigilante, Bodyguard, Escort, Detective Sidekick, Jester, Maniac. The ratios live in one config file, so they are easy to tune.

**Win conditions**

- Town wins when every Mafia member, including the Don, is eliminated.
- Mafia wins when Mafia players equal or outnumber the remaining non-Mafia players.
- Jester wins immediately if voted out in the day phase, and the game ends.

If the Maniac is enabled, they win when they are the last player alive or when only one other player remains.

## 4. Game flow

A game moves through one setup, one reveal, then repeating night and day rounds until a win condition fires.

1. **Setup.** Select players, set role counts, confirm.
2. **Deal.** The app shuffles roles with a cryptographically seeded random shuffle and stores the assignment.
3. **Reveal.** Pass-the-phone screen: tap your name, hold to see your role, release to hide, tap Next. Mafia members optionally see their teammates.
4. **Night.** The moderator is prompted role by role (Mafia, Doctor, Commissioner, Vigilante) and picks a target for each from the list of living players. Roles with no living holder are skipped silently so the moderator's script doesn't reveal who is dead.
5. **Morning.** The app resolves the night (kill, save, check result) and shows an announcement card: who died, or that nobody did.
6. **Day.** Discussion, then a vote. The moderator taps the player voted out; their role is shown if the "reveal on death" setting is on.
7. **Win check.** After every elimination the app checks the win conditions. If none apply, go back to step 4.
8. **End.** Show the winning team, every player's role, and a round-by-round log; save to history.

The moderator can **undo the last action** at any point in a round, and the game state is saved after every step so closing the app never loses a game.

The host narrates the game aloud and is a non-player. The app shows no script; it only tells the host whose role to call next and records what they choose.

## 5. Functional requirements

Priority: **P0** = required for v1, **P1** = should have in v1, **P2** = later.

| ID | Area | Requirement | Priority |
| --- | --- | --- | --- |
| F1 | Roster | Add, edit, delete a saved player (name, optional nickname and avatar colour). Names must be unique, case-insensitive. | P0 |
| F2 | Roster | Search the roster and sort it by name or most recently played. | P1 |
| F3 | Roster | Soft delete: a removed player disappears from the picker but stays in old game history. | P0 |
| F4 | Roster | Quick-add a one-time guest during setup, with an option to save them to the roster. | P1 |
| F5 | Setup | Select any number of players (minimum 4, no hard maximum, practical target 30) with select-all and clear-all. | P0 |
| F6 | Setup | Show live role counts and a warning if Mafia count is zero or at least half the players. | P0 |
| F7 | Setup | Role list with an on/off toggle and a count stepper per role, recommended counts for the chosen player count, and an "Auto balance" button. | P0 |
| F8 | Setup | Save a role setup as a named preset and reuse it. | P2 |
| F9 | Deal | Randomly assign roles; the moderator is a non-player and sees every role in a Moderator panel. | P0 |
| F10 | Reveal | Private hold-to-reveal screen per player, with a confirmation before the next player. | P0 |
| F11 | Game | Alive/dead list, round counter, phase indicator (night or day). | P0 |
| F12 | Game | Night action prompts, resolution of kill versus save, Commissioner check result. | P0 |
| F13 | Game | Day vote: tap a player to eliminate; support no-elimination days. | P0 |
| F14 | Game | Automatic win detection after each elimination. | P0 |
| F15 | Game | Undo last action, and resume an unfinished game after app restart. | P0 |
| F16 | Game | Optional in-app countdown timer for discussion. | P2 |
| F17 | History | List past games with date, player count, winner; open one to see roles and the round log. | P1 |
| F18 | History | Per-player stats: games played, wins by team, times in each role. | P2 |
| F19 | Settings | Toggles: reveal role on death, Doctor self-save, consecutive-save rule, Mafia see each other. | P1 |
| F20 | Data | Export and import the database as a file for backup. | P2 |

**Added after your answers**

| ID | Area | Requirement | Priority |
| --- | --- | --- | --- |
| F21 | Roles | Every role, including Bodyguard, Escort and Maniac, can be toggled on or off; disabled roles never appear in the deal or the night prompts. | P0 |
| F22 | Roles | Suggested counts follow the table in section 3 and update live as players are selected or roles toggled. | P0 |
| F23 | History | At the game's end, share or export the game log as text or as an image through the system share sheet. | P1 |
| F24 | Theme | A single dark theme; no light theme and no theme setting. | P0 |
| F25 | Code | Feature-based Bloc structure and a role registry as described in section 8. | P0 |

## 6. Screens and navigation

A bottom navigation bar with three tabs (Play, Players, History) plus a Settings icon in the app bar. Starting a game opens a full-screen flow with no bottom bar so nobody taps away by accident.

| Screen | Purpose | Key elements |
| --- | --- | --- |
| Home / Play | Start a new game or resume the unfinished one | New Game button, Resume card, last game summary |
| Players | Manage the saved roster | Searchable list, add button, swipe to edit or delete |
| Player form | Add or edit a player | Name, nickname, colour; unique-name validation |
| Select players | Choose tonight's group | Checkbox list, counter, select-all, add guest |
| Role setup | Choose role counts | On/off toggle and stepper per role, recommended counts, Auto balance, balance warning, Start |
| Role reveal | Private role display | Name grid, hold-to-reveal card, Next, progress dots |
| Night | Collect night actions | Prompt per role, living-player picker, skip, undo |
| Morning | Announce results | Result card, alive count |
| Day / vote | Eliminate a player | Alive list, vote tap, no-elimination option, optional timer |
| Game over | Show the winner | Winning team banner, all roles, round log, Share or export log, Save and Home |
| History | Browse past games | List, detail view with log |
| Settings | Rules and theme | Rule toggles, database export and import |

Design principles: large tap targets, high contrast for dim rooms, one dark theme only, and no information on screen that would reveal roles to people looking over a shoulder, except on the reveal and Moderator panel.

## 7. SQLite data model

Seven tables. Primary keys are integer autoincrement; timestamps are ISO-8601 text; booleans are 0 or 1. Foreign keys are enabled (`PRAGMA foreign_keys = ON`).

| Table | Columns | Notes |
| --- | --- | --- |
| players | id, name (unique, nocase), nickname, color, is\_deleted, created\_at, last\_played\_at | Roster; soft delete via is\_deleted |
| roles | id, key (unique), name, team (mafia, town, neutral), night\_order, has\_night\_action, is\_builtin, default\_enabled, default\_count | Seeded on first launch |
| games | id, started\_at, ended\_at, status (setup, reveal, in\_progress, finished), current\_round, current\_phase (night, day), winner\_team, settings\_json | settings\_json snapshots rule toggles and enabled roles for that game |
| game\_players | id, game\_id, player\_id, role\_id, display\_name\_snapshot, is\_alive, eliminated\_round, eliminated\_by (night\_kill, vote, vigilante) | One row per participant; the name snapshot keeps history readable after edits |
| game\_events | id, game\_id, round, phase, event\_type, actor\_game\_player\_id, target\_game\_player\_id, result, created\_at | Event log; powers undo, resume and the history log |
| role\_presets | id, name, config\_json, created\_at | P2 |
| app\_settings | key (primary), value | Default rule toggles and theme |

**Relations:** games 1—n game\_players; players 1—n game\_players; roles 1—n game\_players; games 1—n game\_events. Indexes on `game_players(game_id)`, `game_events(game_id, round)` and `players(name)`.

**Undo and resume** work by replaying or removing the latest `game_events` row and recomputing `is_alive` and the phase from the log, so there is one source of truth.

**Migrations:** use `PRAGMA user_version` with ordered migration scripts from the first release, so later role or setting additions never wipe user data.

## 8. Technical approach and non-functional requirements

**Stack**

- Flutter (stable channel), one codebase for Android and iOS.
- State management: `flutter_bloc` (Cubits for simple screens, Blocs for the game engine) with `equatable`; `get_it` for dependency injection.
- SQLite through `drift` (typed queries, generated migrations); I chose it over `sqflite` because the event log and relations are easier to keep correct. Switching to `sqflite` only changes the data layer.
- `go_router` for navigation, `wakelock_plus` to keep the screen on, `share_plus` and `path_provider` for backup and log export, and a `RepaintBoundary` capture for the log-as-image export.
- Dark theme only: one `ThemeData` in `core/theme`, `themeMode` fixed to dark, no light theme code and no setting.
- Secure shuffle: `Random.secure()` for role assignment.

**Code structure** (feature-first, layered, dependencies point inward only: features → domain ← data)

```text
lib/
  core/              theme (dark only), constants, utils, errors, di (get_it)
    widgets/         reusable UI: PlayerTile, RoleChip, ConfirmDialog, EmptyState, HoldToReveal
  domain/            no Flutter imports; fully unit-testable
    entities/        Player, Role, Game, GamePlayer, GameEvent
    repositories/    abstract interfaces (PlayerRepository, GameRepository, RoleRepository)
    roles/           one class per role implementing RoleBehavior + RoleRegistry
    engine/          GameEngine, NightResolver, WinConditionChecker, RoleDistributor
    usecases/        StartGame, AssignRoles, RecordNightAction, EliminatePlayer, UndoLastEvent
  data/
    database/        drift tables, DAOs, migrations
    repositories/    implementations of the domain interfaces, mappers
  features/          each feature has bloc/, view/ and widgets/
    roster/  game_setup/  role_reveal/  game_play/  game_over/  history/  settings/
  app.dart  main.dart
```

**Reusability and quality rules**

- **Role registry:** each role is one file implementing `RoleBehavior` (team, night order, `onNightAction`, win contribution). Adding a role means one new file, one registry line and one seeded row.
- **Repository interfaces** in `domain` let tests use in-memory fakes and keep the database replaceable.
- **Shared widgets and constants** live in `core`; no screen duplicates a tile, dialog or colour value.
- **Bloc rules:** one Bloc or Cubit per feature, immutable states, no business logic in widgets, no direct database calls from the UI.
- **Balance ratios and default role counts** sit in a single config file, not scattered through code.
- Lint with `flutter_lints`; keep files focused (one public class per file) and run `dart format` and `flutter analyze` in CI.

**Non-functional requirements**

| Area | Target |
| --- | --- |
| Offline | 100% functional with no network permission requested |
| Performance | Cold start under 2 seconds; any screen interaction under 100 ms with 30 players |
| Reliability | Game state persisted after every action; no data loss on app kill or battery death |
| Privacy | No analytics, no accounts, all data stays on device |
| Accessibility | Text scales to 200%, 48 dp minimum tap targets, colour is never the only signal |
| Compatibility | Android 8.0 (API 26) and above; phones first, tablets usable |
| Testing | Unit tests for role assignment, night resolution and every win condition; widget tests for setup and reveal; at least one resume-after-kill integration test |

## 9. Release plan and acceptance criteria

| Milestone | Scope | Done when |
| --- | --- | --- |
| M1 Foundation | Project setup, database, migrations, seed roles, Players CRUD | A saved player survives app restart and duplicate names are rejected |
| M2 Setup and deal | Select players, role toggles and counters, recommended counts, shuffle, reveal flow | A 10-player game is dealt and every role is revealed privately |
| M3 Game engine | Night actions, resolution, day vote, win detection, undo, resume | All win-condition unit tests pass; killing the app mid-night resumes correctly |
| M4 History and settings | Game history, rule toggles, themes, guests | Past games open with a full round log |
| M5 Polish | Backup export and import, game-log share as text and image, accessibility pass, app icon, release build | Signed APK passes a manual run of a full game on two devices |

**v1 acceptance criteria**

- A moderator can create a game from the saved roster, with any number of players from 4 up, in under 60 seconds.
- No role is visible to players except on their own reveal screen; the non-player moderator sees all roles in the Moderator panel.
- Every enabled role behaves as described in the Roles tables, and any role can be toggled off.
- Force-closing the app at any step and reopening it restores the exact game state.
- Deleting a player from the roster does not change or break any past game.

## 10. Assumptions and open questions

**Assumptions I made**

- One moderator device runs the whole game; there is no multi-phone mode.
- "Mafia Pro" is treated as inspiration for the feature set, so the role list and rules here are my own definition of a standard Mafia game, not a copy of any app's assets or branding.
- The Don appears innocent to the Commissioner's check, and the Doctor may save themselves.
- Android and iOS from one Flutter codebase, English only, dark theme only, no ads or accounts.

**Questions for you**

- [x] Which roles must be in v1? Should I drop Vigilante, Jester and Detective Sidekick, or add others such as Bodyguard, Prostitute or Maniac? -> no you can give toggle for all the character which needs to be included or excluded suggest no. of them which would be great
- [x] Does a human narrator speak the script, or should the app also show or read a narration script? -> host will manage it ,
- [x] Should the moderator also be able to play (see their own role), or is the moderator always a non-player? -> non player
- [x] Do you want Flutter on iOS as well, or Android only for now? -> flutter
- [x] Which state management and SQLite package do you prefer (Riverpod or Bloc; sqflite or drift)? -> bloc
- [x] Should a game log be exportable or shareable at the end, for example as an image or text? -> yes

**Decisions applied:** all roles are toggleable with suggested counts (section 3), the host narrates with no in-app script, the moderator is a non-player, Bloc for state, and the game log can be exported. I chose `drift` for SQLite since you did not pick a package; tell me if you prefer `sqflite`.
