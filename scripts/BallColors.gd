extends RefCounted

# Ball color palette — 10 distinct colors for tube sorting

const COLORS = {
	"red": Color("#E63946"),
	"blue": Color("#2E86DE"),
	"green": Color("#2EC04A"),
	"yellow": Color("#F4C430"),
	"purple": Color("#9B59E0"),
	"orange": Color("#FF8C26"),
	"cyan": Color("#1ABCC9"),
	"pink": Color("#FF5C8A"),
	"lime": Color("#A6D820"),
	"teal": Color("#1FA59E"),
	"indigo": Color("#5B6BE0"),
	"brown": Color("#8D5A40"),
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
