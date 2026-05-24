#!/usr/bin/env bash
# Build the signed release AAB.
#
# Keystore path + password live in .keystore.env (gitignored) and are
# spliced into export_presets.cfg just for the export, then reverted —
# so the password never lands in the committed config file.
#
# Usage:   ./build_release.sh
# Output:  build/android/huehaven-v<version>.aab

set -euo pipefail
cd "$(dirname "$0")"

# --- inputs ---
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

# Pull version from project.godot so output filename always matches
VERSION="$(sed -n 's/^config\/version="\([^"]*\)"/\1/p' project.godot)"
VERSION="${VERSION:-dev}"
OUT="build/android/huehaven-v${VERSION}.aab"
mkdir -p build/android

echo "▸ Building HueHaven v${VERSION} release AAB"
echo "  Keystore: $KEYSTORE_PATH"

# Always restore the preset on ANY exit (success, error, signal). Set
# trap BEFORE the splice so if cp itself fails we still have the original.
cleanup() {
    if [ -f "$PRESET_BAK" ]; then
        cp "$PRESET_BAK" "$PRESET"  # cp not mv — keeps .bak around as safety
    fi
}
trap cleanup EXIT INT TERM HUP

# --- splice secret into preset ---
cp "$PRESET" "$PRESET_BAK"
# Use Python rather than sed -i because the password may contain
# special chars (/, &, etc) that would need escaping in sed.
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

# --- export ---
"$GODOT" --headless --path . --export-release "Android (Closed Beta)" "$OUT"

# --- verify ---
if [ ! -f "$OUT" ]; then
    echo "ERROR: export did not produce $OUT" >&2
    exit 1
fi

SIZE=$(stat -c %s "$OUT")
echo ""
echo "✓ Built $OUT  ($(numfmt --to=iec --suffix=B "$SIZE" 2>/dev/null || echo "${SIZE} bytes"))"

# Quick sig verification
JARSIGNER="/c/Program Files/Eclipse Adoptium/jdk-17.0.19.10-hotspot/bin/jarsigner"
if [ -x "$JARSIGNER" ]; then
    if "$JARSIGNER" -verify "$OUT" 2>&1 | grep -q "jar verified"; then
        echo "✓ Signature verified"
    else
        echo "✗ Signature verification failed" >&2
        exit 1
    fi
fi
echo ""
echo "Ready to upload to Play Console Closed Testing track."
