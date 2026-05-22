# Ball Sort — Godot 4 Implementation Plan

> For Hermes: Build this plan task-by-task. Each task is 2-5 min of focused work.

**Goal:** Build a playable Ball Sort puzzle game in Godot 4 with tubes, balls, level generation, undo, hint, and progression.

**Approach:** Pure GDScript with `_draw()` CanvasItem rendering — no tilemaps, minimal scenes. Dark glossy theme.

**Tech Stack:** Godot 4.6.2, GDScript, JSON level data, CanvasItem rendering

---

## Task Breakdown

### Task 1: Project Setup & Main Scene

- Create `project.godot` with mobile-first viewport (480×854), gl_compatibility
- Create `Main.gd` as autoload or scene root
- Create `Main.tscn` with Main.gd attached
- Dark background (Color `#0D0D1A`)

### Task 2: Ball Color Palette

- Create `scripts/BallColors.gd` (extends RefCounted)
- Define 10 distinct ball colors as Color constants
- Include color names and a `get_color(name) -> Color` function

### Task 3: Level Data Format

- Create `scripts/LevelData.gd` (extends RefCounted)
- Level format: `{colors: int, tubes: int, capacity: int, contents: [[int]], par_moves: int, bombs: bool, specials: []}`
- Build first 5 test levels manually for dev purposes

### Task 4: GameState — Core Logic

- Create `scripts/GameState.gd` (extends RefCounted)
- State: current level data, tube contents, move count, undo stack
- Methods: `can_move(from, to)`, `move_ball(from, to)`, `undo()`, `is_tube_complete(tube_idx)`, `is_level_won()`, `reset()`
- Track undo stack: `[[from_idx, to_idx]]` pairs

### Task 5: TubeGrid — Visual Renderer + Input

- Create `scripts/TubeGrid.gd` (extends Control)
- `_draw()` renders tubes as rounded rectangles with balls stacked inside
- Tube layout: N tubes in a grid row, each with capacity slots
- Ball rendering: colored circles with glossy highlight (lighter spot)
- Completed tube: sparkle indicator (white glow ring)

### Task 6: Input Handling — Tap to Move

- `_unhandled_input()` for touch/mouse
- Tap tube → select top ball (lift animation via modulate offset)
- Tap second tube → attempt move (valid/invalid feedback)
- Visual feedback: selected tube glows, invalid move shakes, valid move animates

### Task 7: HUD — Undo, Hint, Moves, Win

- Create `scripts/HUD.gd` (extends Control)
- Move counter, undo button, hint button, restart button
- Win overlay: confetti text, stars display, next level button
- Dark theme UI with ACCENT color (`#e8d5a3`)

### Task 8: Ball Animations & Juice

- Lift animation: selected ball rises slightly above tube
- Drop animation: ball slides down into target tube
- Shake: invalid target tube shakes horizontally
- Win: tube completion sparkle, confetti burst on level win
- Haptic feedback markers (platform-dependant)

### Task 9: Level Generator — Solvable Puzzles ✅

- `scripts/LevelGenerator.gd` (extends RefCounted) — DONE
- Algorithm: Start with sorted tubes → random valid moves to scramble (guaranteed solvable)
- Generates by difficulty (6 tiers: Tutorial → Master)
- 7 level packs, 500 total levels, deterministic by index (prime seed)
- Par moves calculated from scramble moves × difficulty multiplier

### Task 10: Progression System ✅

- `scripts/Progression.gd` — save/load progress (ConfigFile), track stars per level, unlock chain
- `scripts/LevelSelect.gd` — grid of level buttons (5 cols), star display, locked icons, pack navigation
- Level packs: Tutorial (10), Easy (40), Medium (60), Hard (100), Expert (150), Master (140) = 500 total
- Star rating: 3 stars (≤ par), 2 stars (≤ par×2), 1 star (> par×2)
- Save stars + unlock next level on win
- `Main.gd` updated: routes through level select first, uses generated levels, back-to-menu support
- `HUD.gd` updated: level name display, win overlay with stars, Next/Level Select buttons

### Task 11: Special Ball Mechanics (Bomb, Rainbow, Magnet, Stone, Hourglass)

- Bomb ball: timer bar overlay, explosion scrambles tube, moves one-at-a-time
- Rainbow ball: wildcard — matches any color
- Magnet ball: pulls all same-color balls on placement
- Stone ball: unmovable block, cleared by filling around it
- Hourglass: adds +15s to bomb timers when sorted

### Task 12: UX Polish & Accessibility

- Color-blind mode toggle: shape markers on balls (○ △ □ ◇ ★)
- Smooth transitions between states
- "No Ads Mid-Puzzle" rule baked into flow
- Sound hooks (placeholder)

---

## Build Order (Priority)

**Phase 1 (Core Prototype):** Tasks 1-7 ✅ → fully playable with test levels
**Phase 2 (Content):** Tasks 9-10 ✅ → level gen + progression
**Phase 3 (Extra):** Tasks 11-12 → special balls + polish
