# HueHaven — Unity 6 project

A Unity 6 port of the Godot 4 game in the repository root. Same rules, same 500 generated levels,
same cafe-boba look, same screens. The Godot project is untouched and lives next to this folder.

## Open it

1. Unity Hub → **Add → Add project from disk** → select this `Unity/` folder.
2. Use any **Unity 6** editor (6000.0 or newer). `ProjectSettings/ProjectVersion.txt` names 6000.0.23f1;
   Hub will offer to open it with whichever Unity 6 you have installed.
3. On first open, `Assets/Editor/ProjectSetup.cs` applies the project settings (portrait, package id
   `com.altafhssn.huehaven`, IL2CPP + ARMv7/ARM64, min SDK 23, Gamma colour space) and creates
   `Assets/Scenes/Main.unity`. Re-run it any time from **HueHaven ▸ Apply Project Settings**.
4. Press **Play**. The game builds its whole UI from code at startup (`Bootstrap` in
   `Scripts/GameController.cs`), so it runs from any scene — there is no scene wiring to maintain.
5. Commit the `.meta` files Unity generates on first import.

Input: keep **Project Settings ▸ Player ▸ Active Input Handling** on *Input Manager (Old)* or *Both*
(the Android back button handling and the UI input module use the legacy manager).

## Layout

| Path | What |
| --- | --- |
| `Assets/Scripts/Core/` | Pure C# game logic, no Unity dependency: `GameState`, `LevelGenerator`, `Pcg32`, `Ball`, `Level` |
| `Assets/Scripts/UI/` | Rendering toolkit: `VectorGraphic` (mesh shapes), `Sprites` (procedural AA sprites), `UIKit` (buttons, panels, text), `Icons`, `Palette`, `CafeBackground` |
| `Assets/Scripts/Screens/` | `MainMenuScreen`, `PackSelectScreen`, `LevelSelectScreen`, `SettingsScreen`, `HudView`, `BoardView` |
| `Assets/Scripts/*.cs` | `GameController` (navigation, win/stuck), `Progression` (save), `AudioManager` (+ haptics), `GameAssets` |
| `Assets/Resources/Art`, `Audio` | Pearls, straws, cafe backdrop, logo, SFX — loaded by name |
| `Assets/Editor/` | First-open setup, signed Android build script, texture import rules |
| `Assets/Tests/Editor/` | NUnit tests for the rules and level generator (Window ▸ General ▸ Test Runner) |

## Godot → Unity map

| Godot | Unity |
| --- | --- |
| `GameState.gd`, `LevelGenerator.gd` | `Core/GameState.cs`, `Core/LevelGenerator.cs` |
| `Main.gd` (gameplay) / `Main.gd` (navigation) | `Screens/BoardView.cs` / `GameController.cs` |
| `HUD.gd`, `MainMenu.gd`, `PackSelect.gd`, `LevelSelect.gd`, `SettingsScreen.gd` | `Screens/*.cs` |
| `Style.gd`, `Icon.gd` | `UI/Palette.cs`, `UI/CafeBackground.cs`, `UI/Icons.cs`, `UI/UIKit.cs` |
| `Assets.gd`, `Audio.gd`, `Progression.gd` | `GameAssets.cs`, `AudioManager.cs`, `Progression.cs` |
| `build_apk.sh`, `build_release.sh` | **HueHaven ▸ Build** menu / `BuildScript.cs` (same `.keystore.env`) |

UI coordinates are kept Godot-style (origin top-left, Y down) so layout maths from the `.gd` files
ports across unchanged. The canvas is 854 units tall (Godot's `keep_height`); width follows the screen.

## Behaviour notes

* **Levels and rules match the Godot build exactly.** `Pcg32` reproduces Godot's `RandomNumberGenerator`,
  so level *N* has the same layout, par, specials and bomb timers in both (see *Verification*).
* **Saves do not carry over** — Unity stores progress as JSON in `persistentDataPath`, not Godot's `user://` ConfigFile.
* Deliberate changes: bomb pearls now show their remaining-moves counter (the Godot texture path
  never drew it); Android back button navigates up a screen; the level grid scrolls to your current
  level; sparkle rings clear when an undo breaks a completed tube; settings rows show ON/OFF at the right edge.

## Build

`HueHaven ▸ Build ▸ Android APK` / `AAB` reads `KEYSTORE_PATH`, `KEYSTORE_USER`, `KEYSTORE_PASS` from the
environment or the repo-root `.keystore.env`, and writes `build/android/huehaven-v<version>.apk|aab`.
Batch mode: `Unity -batchmode -quit -projectPath Unity -executeMethod HueHaven.Editor.BuildScript.BuildApk`.

Launcher icon: assign `Assets/Icons/icon*.png` under Project Settings ▸ Player ▸ Icon (adaptive
foreground/background are provided) — not automated because the icon API differs between Unity versions.

## Verification

Done outside the Unity editor:

* **Parity with the original game.** The original GDScript (`LevelGenerator.gd`, `GameState.gd`) was run in
  Godot 4.6.2 headless and diffed against the C# port: all **500 generated levels are identical** (layout, par,
  colour count, specials, stone placement, bomb timers), and ~**240,000 simulated steps** of random play
  (moves, undo, hints, win/stuck detection, star rating, tube completion, bomb explosions, magnet pulls,
  hourglass refills, stones, rainbows) produced **identical state after every step**.
* **Compiles warning-free** against Unity engine assemblies + uGUI 2.0 (desktop, Android and new-input-only
  define sets). `Handheld.Vibrate()` couldn't be checked that way (absent from the stripped reference assemblies
  used) but is standard Unity API.
* **15 NUnit tests** over the rules and all 500 levels pass (`Assets/Tests/Editor/CoreTests.cs`; also run with `dotnet test`).

**Not done:** the project has not been opened in the Unity editor or run on a device. The game logic is proven
equivalent, but everything visual — layout, fonts, touch feel, animation timing, the `Editor/` scripts (they need
`UnityEditor`) — is unverified until you press Play. Expect to tweak spacing / text metrics on first run.
