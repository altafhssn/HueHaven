extends RefCounted

# Ball color palette — 10 distinct colors for tube sorting

const COLORS = {
	"red": Color("#C84A50"),
	"blue": Color("#4080B5"),
	"green": Color("#4FA868"),
	"yellow": Color("#D8B440"),
	"purple": Color("#8A66B0"),
	"orange": Color("#D88A40"),
	"cyan": Color("#3E9AA8"),
	"pink": Color("#C4688E"),
	"lime": Color("#90B055"),
	"teal": Color("#3F8E88"),
	"indigo": Color("#5868A8"),
	"brown": Color("#856047"),
}

const COLOR_LIST = [
	COLORS["red"],
	COLORS["blue"],
	COLORS["green"],
	COLORS["yellow"],
	COLORS["purple"],
	COLORS["orange"],
	COLORS["cyan"],
	COLORS["pink"],
	COLORS["lime"],
	COLORS["teal"],
	COLORS["indigo"],
	COLORS["brown"],
]

static func get_color(idx: int) -> Color:
	if idx >= 0 and idx < COLOR_LIST.size():
		return COLOR_LIST[idx]
	return Color.TRANSPARENT

static func get_color_count() -> int:
	return COLOR_LIST.size()

static func get_color_name(idx: int) -> String:
	var names = ["Red", "Blue", "Green", "Yellow", "Purple", "Orange", "Cyan", "Pink", "Lime", "Teal", "Indigo", "Brown"]
	if idx >= 0 and idx < names.size():
		return names[idx]
	return "Unknown"
