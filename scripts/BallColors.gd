extends RefCounted

# Ball color palette — 10 distinct colors for tube sorting

const COLORS = {
	"red": Color("#EF5350"),
	"blue": Color("#42A5F5"),
	"green": Color("#66BB6A"),
	"yellow": Color("#FFEE58"),
	"purple": Color("#AB47BC"),
	"orange": Color("#FFA726"),
	"cyan": Color("#26C6DA"),
	"pink": Color("#EC407A"),
	"lime": Color("#9CCC65"),
	"teal": Color("#26A69A"),
	"indigo": Color("#5C6BC0"),
	"brown": Color("#8D6E63"),
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
