extends RefCounted

# Asset loader — preloads all boba theme textures once and exposes them
# by index so the renderer can blit instead of drawing procedurally.

# Pearl textures indexed by BallColors enum order (red=0, blue=1, green=2,
# yellow=3, purple=4, orange=5, cyan=6, pink=7, lime=8, teal=9, indigo=10, brown=11).
# We map the existing 12 BallColors slots to the 8 boba flavors by mood —
# the game uses colour indices, not colour values, so any mapping is fine
# as long as it's consistent.
const PEARL_MAP := {
	0: "res://assets/art/pearls/strawberry.png",   # red    -> strawberry pink
	1: "res://assets/art/pearls/blueberry.png",    # blue   -> blueberry
	2: "res://assets/art/pearls/matcha.png",       # green  -> matcha
	3: "res://assets/art/pearls/brownsugar.png",   # yellow -> brown sugar
	4: "res://assets/art/pearls/taro.png",         # purple -> taro
	5: "res://assets/art/pearls/mango.png",        # orange -> mango
	6: "res://assets/art/pearls/peach.png",        # cyan   -> peach
	7: "res://assets/art/pearls/strawberry.png",   # pink   -> strawberry (reuse)
	8: "res://assets/art/pearls/matcha.png",       # lime   -> matcha (reuse)
	9: "res://assets/art/pearls/peach.png",        # teal   -> peach (reuse)
	10: "res://assets/art/pearls/blueberry.png",   # indigo -> blueberry (reuse)
	11: "res://assets/art/pearls/milktea.png",     # brown  -> milktea
}

const SPECIAL_MAP := {
	"bomb":      "res://assets/art/pearls_special/popping.png",
	"rainbow":   "res://assets/art/pearls_special/rainbow.png",
	"magnet":    "res://assets/art/pearls_special/sticky.png",
	"stone":     "res://assets/art/pearls_special/frozen.png",
	"hourglass": "res://assets/art/pearls_special/sand.png",
}

const GLASS_PATH := "res://assets/art/glass_empty.png"
const CAFE_BG_PATH := "res://assets/art/bg/cafe.png"

# Straws keyed by pack index (cycles for >6 packs).
const STRAW_PATHS := [
	"res://assets/art/straws/mint.png",
	"res://assets/art/straws/peach.png",
	"res://assets/art/straws/lavender.png",
	"res://assets/art/straws/blue.png",
	"res://assets/art/straws/yellow.png",
	"res://assets/art/straws/pink.png",
]

# Caches
static var _pearl_cache: Dictionary = {}
static var _special_cache: Dictionary = {}
static var _glass: Texture2D = null
static var _cafe_bg: Texture2D = null
static var _straw_cache: Array = []
static var _loaded: bool = false

static func preload_all() -> void:
	if _loaded:
		return
	for idx in PEARL_MAP.keys():
		_pearl_cache[idx] = load(PEARL_MAP[idx])
	for st in SPECIAL_MAP.keys():
		_special_cache[st] = load(SPECIAL_MAP[st])
	_glass = load(GLASS_PATH)
	_cafe_bg = load(CAFE_BG_PATH)
	for p in STRAW_PATHS:
		_straw_cache.append(load(p))
	_loaded = true

static func pearl(color_idx: int) -> Texture2D:
	if not _loaded:
		preload_all()
	if _pearl_cache.has(color_idx):
		return _pearl_cache[color_idx]
	return _pearl_cache[0]

static func special(stype: String) -> Texture2D:
	if not _loaded:
		preload_all()
	if _special_cache.has(stype):
		return _special_cache[stype]
	return null

static func glass() -> Texture2D:
	if not _loaded:
		preload_all()
	return _glass

static func cafe_bg() -> Texture2D:
	if not _loaded:
		preload_all()
	return _cafe_bg

static func straw_for_pack(pack_idx: int) -> Texture2D:
	if not _loaded:
		preload_all()
	if _straw_cache.is_empty():
		return null
	return _straw_cache[pack_idx % _straw_cache.size()]
