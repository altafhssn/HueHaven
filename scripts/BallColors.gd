extends RefCounted

# Ball color palette — 10 distinct colors for tube sorting

const COLORS = {
	"red": Color("#D85A4E"),
	"blue": Color("#5C8EBF"),
	"green": Color("#74A65E"),
	"yellow": Color("#E5C054"),
	"purple": Color("#9B6FAD"),
	"orange": Color("#DD8F50"),
	"cyan": Color("#5DA8B2"),
	"pink": Color("#D8729E"),
	"lime": Color("#95B561"),
	"teal": Color("#5A9B92"),
	"indigo": Color("#6878B5"),
	"brown": Color("#8D6E5C"),
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
