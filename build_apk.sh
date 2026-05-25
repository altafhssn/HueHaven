#!/usr/bin/env bash
# Build the signed sideload APK (for direct phone install via adb / file transfer).
# Same keystore + secret-handling pattern as build_release.sh.
#
# Usage:   ./build_apk.sh
# Output:  build/android/huehaven-v<version>.apk

set -euo pipefail
cd "$(dirname "$0")"

ENV_FILE=".keystore.env"
PRESET="export_presets.cfg"
PRESET_BAK="${PRESET}.bak"
GODOT="${GODOT:-C:/Users/altaf/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe}"

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE not found. Create it with KEYSTORE_PATH, KEYSTORE_USER, KEYSTORE_PASS." >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$ENV_FILE"

if [ -z "${KEYSTORE_PATH:-}" ] || [ -z "${KEYSTORE_USER:-}" ] || [ -z "${KEYSTORE_PASS:-}" ]; then
    echo "ERROR: $ENV_FILE must define KEYSTORE_PATH, KEYSTORE_USER, KEYSTORE_PASS." >&2
    exit 1
fi
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "ERROR: keystore not found at $KEYSTORE_PATH" >&2
    exit 1
fi

VERSION="$(sed -n 's/^config\/version="\([^"]*\)"/\1/p' project.godot)"
VERSION="${VERSION:-dev}"
OUT="build/android/huehaven-v${VERSION}.apk"
mkdir -p build/android

echo "▸ Building HueHaven v${VERSION} sideload APK"
echo "  Keystore: $KEYSTORE_PATH"

cleanup() {
    if [ -f "$PRESET_BAK" ]; then
        cp "$PRESET_BAK" "$PRESET"
    fi
}
trap cleanup EXIT INT TERM HUP

cp "$PRESET" "$PRESET_BAK"
# Patch BOTH presets' release-keystore fields. Python via stdin
# pickles the password through sys.argv so it isn't subject to bash
# history-expansion on '!'.
python - "$PRESET" "$KEYSTORE_PATH" "$KEYSTORE_USER" "$KEYSTORE_PASS" <<'PY'
import sys
path, ks, user, pwd = sys.argv[1:5]
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()
text = text.replace('keystore/release=""',          f'keystore/release="{ks}"')
text = text.replace('keystore/release_user=""',     f'keystore/release_user="{user}"')
text = text.replace('keystore/release_password=""', f'keystore/release_password="{pwd}"')
with open(path, 'w', encoding='utf-8', newline='') as f:
    f.write(text)
PY

"$GODOT" --headless --path . --export-release "Android APK (Sideload)" "$OUT"

if [ ! -f "$OUT" ]; then
    echo "ERROR: export did not produce $OUT" >&2
    exit 1
fi

SIZE=$(stat -c %s "$OUT")
echo ""
echo "✓ Built $OUT  ($(numfmt --to=iec --suffix=B "$SIZE" 2>/dev/null || echo "${SIZE} bytes"))"

JARSIGNER="/c/Program Files/Eclipse Adoptium/jdk-17.0.19.10-hotspot/bin/jarsigner"
if [ -x "$JARSIGNER" ]; then
    if ! "$JARSIGNER" -verify "$OUT" 2>&1 | grep -q "jar verified"; then
        echo "▸ APK unsigned by gradle — applying v1 JAR signature manually"
        "$JARSIGNER" -sigalg SHA256withRSA -digestalg SHA-256 \
            -keystore "$KEYSTORE_PATH" \
            -storepass "$KEYSTORE_PASS" -keypass "$KEYSTORE_PASS" \
            "$OUT" "$KEYSTORE_USER" >/dev/null 2>&1
    fi
    if "$JARSIGNER" -verify "$OUT" 2>&1 | grep -q "jar verified"; then
        echo "✓ Signature verified"
    else
        echo "✗ Signature verification failed" >&2
        exit 1
    fi
fi
echo ""
echo "Ready to install on Android device."
echo "  adb install $OUT"
echo "  or transfer the file and tap it on the device."
