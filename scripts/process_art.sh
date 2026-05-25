#!/usr/bin/env bash
# Slice the 5 Gemini-rendered sheets into 21 transparent PNGs, ready for
# Godot integration. Run from the project root.
#
# Requires ImageMagick 7+ on PATH.

set -euo pipefail

# Find ImageMagick (winget puts it in Program Files)
if ! command -v magick >/dev/null 2>&1; then
    export PATH="/c/Program Files/ImageMagick-7.1.2-Q16-HDRI:$PATH"
fi
command -v magick >/dev/null || { echo "magick not found"; exit 1; }

# Project root resolution — script lives at scripts/, raw assets at assets/art/raw/
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RAW="$ROOT/assets/art/raw"
OUT="$ROOT/assets/art"

# Out dirs
mkdir -p "$OUT/pearls" "$OUT/pearls_special" "$OUT/straws" "$OUT/bg"

# Chroma-key tolerance — gentle enough not to eat antialiased pearl edges
FUZZ=12

echo "=== 1. Regular pearls (4x2 grid → 8 files) ==="
PEARL_NAMES=(taro matcha milktea strawberry brownsugar blueberry mango peach)
magick "$RAW/pearls_sheet.png" -crop 4x2@ +repage +adjoin "$OUT/pearls/_tmp_%d.png"
for i in 0 1 2 3 4 5 6 7; do
    magick "$OUT/pearls/_tmp_$i.png" \
        -fuzz ${FUZZ}% -transparent "#FF00FF" \
        -trim +repage \
        "$OUT/pearls/${PEARL_NAMES[$i]}.png"
    rm "$OUT/pearls/_tmp_$i.png"
    printf "  %-12s → %s\n" "${PEARL_NAMES[$i]}.png" "$(magick identify -format '%w x %h' "$OUT/pearls/${PEARL_NAMES[$i]}.png")"
done

echo ""
echo "=== 2. Special pearls (5x1 row → 5 files) ==="
SPECIAL_NAMES=(rainbow frozen popping sticky sand)
magick "$RAW/specials_sheet.png" -crop 5x1@ +repage +adjoin "$OUT/pearls_special/_tmp_%d.png"
for i in 0 1 2 3 4; do
    magick "$OUT/pearls_special/_tmp_$i.png" \
        -fuzz ${FUZZ}% -transparent "#FF00FF" \
        -trim +repage \
        "$OUT/pearls_special/${SPECIAL_NAMES[$i]}.png"
    rm "$OUT/pearls_special/_tmp_$i.png"
    printf "  %-12s → %s\n" "${SPECIAL_NAMES[$i]}.png" "$(magick identify -format '%w x %h' "$OUT/pearls_special/${SPECIAL_NAMES[$i]}.png")"
done

echo ""
echo "=== 3. Paper straws (6x1 row → 6 files) ==="
STRAW_NAMES=(mint peach pink lavender yellow blue)
magick "$RAW/straws_sheet.png" -crop 6x1@ +repage +adjoin "$OUT/straws/_tmp_%d.png"
for i in 0 1 2 3 4 5; do
    magick "$OUT/straws/_tmp_$i.png" \
        -fuzz ${FUZZ}% -transparent "#FF00FF" \
        -trim +repage \
        "$OUT/straws/${STRAW_NAMES[$i]}.png"
    rm "$OUT/straws/_tmp_$i.png"
    printf "  %-12s → %s\n" "${STRAW_NAMES[$i]}.png" "$(magick identify -format '%w x %h' "$OUT/straws/${STRAW_NAMES[$i]}.png")"
done

echo ""
echo "=== 4. Empty glass (single, chroma-key + trim) ==="
magick "$RAW/glass_empty.png" \
    -fuzz ${FUZZ}% -transparent "#FF00FF" \
    -trim +repage \
    "$OUT/glass_empty.png"
printf "  %-12s → %s\n" "glass_empty.png" "$(magick identify -format '%w x %h' "$OUT/glass_empty.png")"

echo ""
echo "=== 5. Cafe background (trim watermark in bottom-right) ==="
# Watermark is the small Gemini sparkle ~60px from bottom-right. Chop it cleanly.
magick "$RAW/cafe_bg.png" \
    -gravity southeast -region 80x80 -fill "#F4E8D8" -colorize 100 +region \
    +repage \
    "$OUT/bg/cafe.png"
printf "  %-12s → %s\n" "bg/cafe.png" "$(magick identify -format '%w x %h' "$OUT/bg/cafe.png")"

echo ""
echo "=== DONE — wrote 21 files ==="
echo "Output root: $OUT"
ls -lhR "$OUT" | grep -E "\.png$" | wc -l | xargs printf "Total PNGs: %s\n"
