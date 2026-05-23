# HueHaven — Play Store Release Checklist

End-to-end guide from "I've never opened Play Console" → AAB live on the
**Closed Beta** track. Each section can be done sequentially.

Estimated time: **3-4 hours** the first time (a lot of it is Play Console
form-filling and waiting for Google reviews).

---

## 1. One-time developer setup

### 1.1. Google Play Console account
- Go to [https://play.google.com/console/signup](https://play.google.com/console/signup)
- Pay the **one-time $25 USD** registration fee
- Verify your identity (Google now requires government ID for personal accounts)
- Wait for account activation (usually under 48 hours)

### 1.2. Install Java (JDK 17)
Godot's Android export uses Gradle which needs JDK 17.
- Download from [https://adoptium.net/temurin/releases/?version=17](https://adoptium.net/temurin/releases/?version=17)
- Install with default options
- Verify in a terminal: `java -version` should show 17.x.x

### 1.3. Install Android command-line tools + SDK
Easiest way is via Android Studio (it bundles everything):
- Install [Android Studio](https://developer.android.com/studio)
- Open it once, accept SDK license, let it download default components
- In **SDK Manager** (Settings → Languages & Frameworks → Android SDK):
  - Install **SDK Platform API 34** (target SDK)
  - Install **SDK Build-Tools** (latest)
  - Install **Android SDK Command-line Tools (latest)**
  - Install **Android SDK Platform-Tools**
- Note the SDK install path (default on Windows: `C:\Users\<you>\AppData\Local\Android\Sdk`)

### 1.4. Install Godot Android export templates
- Open Godot
- **Editor → Manage Export Templates** → click **Download and Install**
- Wait for it to finish (~500 MB)

### 1.5. Point Godot at the SDK
- **Editor → Editor Settings → Export → Android**
- Set **Java SDK Path** → the JDK 17 install root (not the `bin/` folder)
- Set **Android SDK Path** → the SDK path from step 1.3
- Click **Install Build Template** at the bottom of the Android export preset
  (this copies a Gradle project into `android/` inside HueHaven)

---

## 2. Generate your release keystore

This file signs the AAB. **Treat it like a password** — losing it means you
can never update the app, only republish under a new package name.

### 2.1. Generate
```bash
keytool -genkey -v -keystore huehaven-release.keystore \
  -alias huehaven -keyalg RSA -keysize 2048 -validity 25000
```
- Choose a strong password (min 6 chars; longer is better)
- Fill in the name / org / city prompts (these can be anything; they appear
  in the cert but Play Store doesn't surface them)

### 2.2. Store it safely
- Move `huehaven-release.keystore` somewhere **outside the repo** (e.g.
  `C:\Users\<you>\keystores\huehaven-release.keystore`)
- Back it up to encrypted cloud storage and a USB drive
- Record the password in a password manager

### 2.3. Wire it into Godot
Open `export_presets.cfg` (in the project root) and set:
```ini
keystore/release="C:\\Users\\<you>\\keystores\\huehaven-release.keystore"
keystore/release_user="huehaven"
keystore/release_password="<your password>"
```
**Don't commit this file with passwords filled in** — either add it to
`.gitignore` after the first commit or use environment-variable substitution.

---

## 3. Build the AAB

### 3.1. From Godot editor
- **Project → Export...**
- Select **Android (Closed Beta)** preset
- Click **Export Project** at the bottom
- Choose output path: `build/huehaven-v1.0.0.aab`
- Wait for Gradle to compile (~2-5 minutes first time)

### 3.2. Verify the AAB
The output should be at the path you chose. Quick sanity checks:
- File size should be roughly 15-30 MB (HueHaven is small)
- Filename ends in `.aab`, not `.apk` (AAB is required by Play Store since 2021)

---

## 4. Set up the Play Console listing

### 4.1. Create the app
- [Play Console](https://play.google.com/console) → **Create app**
- App name: **HueHaven**
- Default language: English (US)
- App or game: **Game**
- Free or paid: **Free**
- Accept the declarations

### 4.2. Required forms (left sidebar — work top-down)

**App content** — answer everything:
| Form | HueHaven's answer |
|---|---|
| Privacy policy | Host `PRIVACY_POLICY.md` somewhere public (e.g. push to a GitHub Pages site or use the raw GitHub URL: `https://raw.githubusercontent.com/altafhssn/HueHaven/main/PRIVACY_POLICY.md`) and paste the URL |
| App access | All functionality available without restrictions |
| Ads | **No ads** |
| Content rating | Take the IARC questionnaire — HueHaven gets **Everyone / PEGI 3** |
| Target audience | Ages 13+ (or 5+ if you want children rating) |
| News app | No |
| COVID-19 contact tracing | No |
| Data safety | **No data collected** — fill the form accordingly |
| Government apps | No |
| Financial features | No |
| Health | No |

**Store listing**:
- **App name**: HueHaven
- **Short description** (80 chars):
  > A serene sorting puzzle. Calm the chaos one ball at a time.
- **Full description** (4000 chars):
  > HueHaven is a meditative sorting puzzle. Pour colored balls between
  > glass vials until each tube holds a single color. Six chapters, 500
  > hand-tuned levels, no ads, no timer, no internet.
  >
  > **Features:**
  > • Six themed chapters — Tide, Spark, Grove, Orbit, Ember, Canopy
  > • 500 procedurally generated levels, every one solvable
  > • Special balls in later chapters: rainbow wildcards, magnetic
  >   attractors, stone blockers, hourglass time-givers, fuse bombs
  > • Color-blind shape markers
  > • Hint button and undo for when you need them
  > • Stuck-state detection so you never waste time on dead ends
  > • Calm haptic feedback that respects silent mode
  > • Plays offline. No ads, no IAP, no analytics.
- **App icon**: upload `assets/icon.png` (512×512)
- **Feature graphic**: 1024×500 — needs a custom image; either create one in Figma using the icon and accent color, or temporarily use a colored rectangle with the logo + name as placeholder
- **Phone screenshots**: at least 2 (16:9 portrait). Capture from running game:
  - Main menu showing the logo
  - In-game showing a partially-sorted puzzle with the glass tubes
  - The pack-select screen
  - Bonus: a level mid-solve with a special ball visible
- **Category**: Games → Puzzle
- **Tags**: Sorting, Casual, Brain Teaser

### 4.3. Production access (one-time)
First-time apps now require Google's "production access" review which
asks about your testing plans. For closed beta this isn't blocking, but
fill the form to unblock later production rollout.

---

## 5. Closed beta release

### 5.1. Create the closed beta track
- Play Console → **Testing → Closed testing → Create track**
- Name it "Beta"
- Add testers either by:
  - Email list (up to 100 emails — paste them as a CSV)
  - Or a Google Group (preferred for larger groups)

### 5.2. Upload the AAB
- In the new closed-beta track → **Create new release**
- Click **Upload** and select `build/huehaven-v1.0.0.aab`
- Wait for Play Console to process it (~5 minutes)
- **Release name**: "1.0.0" (auto-filled from manifest)
- **Release notes**:
  > First closed beta. Six chapters, 500 levels, all polish features
  > in place. Please report any unsolvable level or crash via the
  > GitHub issues link in About.

### 5.3. Send to review
- Click **Review release** → fix any warnings → **Start rollout to Closed testing**
- Google review typically takes **1-7 days** for a first submission
- Once approved, testers get an email with a link to opt in via the
  Play Store app

---

## 6. Post-release

- **Crash & ANR reports** appear in Play Console → Quality → Crashes
- **Vitals** dashboard tracks battery / memory / load time
- For the next release (1.0.1, 1.1.0, etc.):
  - Bump `version/code` in `export_presets.cfg` (integer — always increment)
  - Bump `version/name` in `export_presets.cfg` (semver string)
  - Update `config/version` in `project.godot` to match
  - Re-export → upload to the same closed-beta track → release

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Godot "Java SDK Path not configured" | Editor Settings → Export → Android → set JDK 17 path |
| Gradle "Unable to find Android SDK" | Editor Settings → Export → Android → set SDK path |
| "Build template not installed" | Open Android export preset → click Install Build Template |
| AAB upload rejected for missing 64-bit | Confirm `arm64-v8a=true` in `export_presets.cfg` (we have it) |
| AAB rejected for debug signing | Make sure `keystore/release` is set, not `keystore/debug` |
| "Permissions need declaration" | Fill the Data Safety form — say no data collected |
| Icon shows as default robot | Make sure `assets/icon.png` exists and `config/icon` in `project.godot` points to it |

---

Good luck with the launch.
