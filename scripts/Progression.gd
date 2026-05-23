extends RefCounted

# Progression System — save/load stars, level progress, settings

const SAVE_PATH = "user://ball_sort_save.cfg"

var save_data: Dictionary = {}

func _init():
	load_save()

# --- Stars ---

func get_stars(level_idx: int) -> int:
	if save_data.has("stars") and save_data.stars.has(level_idx):
		return save_data.stars[level_idx]
	return 0

func set_stars(level_idx: int, stars: int):
	if not save_data.has("stars"):
		save_data.stars = {}
	if stars > get_stars(level_idx):
		save_data.stars[level_idx] = min(stars, 3)
		save_progress()

# Get highest unlocked level (0-based)
func get_highest_unlocked() -> int:
	if not save_data.has("unlocked"):
		return 0
	return save_data.unlocked

func unlock_level(level_idx: int):
	if not save_data.has("unlocked"):
		save_data.unlocked = 0
	if level_idx > save_data.unlocked:
		save_data.unlocked = level_idx
		save_progress()

# Check if a level is playable
func is_level_unlocked(level_idx: int) -> bool:
	return level_idx <= get_highest_unlocked()

# Sum of all stars earned across every level
func total_stars() -> int:
	var sum: int = 0
	if save_data.has("stars"):
		for v in save_data.stars.values():
			sum += int(v)
	return sum

# Sum of stars earned within a specific pack range
func pack_stars(start_idx: int, count: int) -> int:
	var sum: int = 0
	for i in range(count):
		sum += get_stars(start_idx + i)
	return sum

# --- Settings ---

func get_setting(key: String, default_value):
	if save_data.has("settings") and save_data.settings.has(key):
		return save_data.settings[key]
	return default_value

func set_setting(key: String, value) -> void:
	if not save_data.has("settings"):
		save_data.settings = {}
	save_data.settings[key] = value
	save_progress()

func is_colorblind() -> bool:
	return bool(get_setting("colorblind", false))

func is_muted() -> bool:
	return bool(get_setting("muted", false))

func is_haptics_enabled() -> bool:
	return bool(get_setting("haptics", true))

# --- Save/Load ---

func save_progress():
	var cfg = ConfigFile.new()

	if save_data.has("stars"):
		for idx in save_data.stars:
			cfg.set_value("Progress", "star_" + str(idx), save_data.stars[idx])

	cfg.set_value("Progress", "highest_unlocked", save_data.get("unlocked", 0))

	if save_data.has("settings"):
		for key in save_data.settings.keys():
			cfg.set_value("Settings", key, save_data.settings[key])

	cfg.save(SAVE_PATH)

func load_save():
	save_data = {}
	var cfg = ConfigFile.new()

	var err = cfg.load(SAVE_PATH)
	if err != OK:
		# No save file yet, start fresh
		save_data.unlocked = 0
		save_data.stars = {}
		save_data.settings = {}
		return

	# Load stars
	save_data.stars = {}
	if cfg.has_section("Progress"):
		for key in cfg.get_section_keys("Progress"):
			if key.begins_with("star_"):
				var idx = int(key.substr(5))
				save_data.stars[idx] = cfg.get_value("Progress", key, 0)

	save_data.unlocked = cfg.get_value("Progress", "highest_unlocked", 0)

	# Settings
	save_data.settings = {}
	if cfg.has_section("Settings"):
		for key in cfg.get_section_keys("Settings"):
			save_data.settings[key] = cfg.get_value("Settings", key)

	# Ensure level 0 is always unlocked
	if not save_data.has("unlocked") or save_data.unlocked < 0:
		save_data.unlocked = 0

func reset_all():
	save_data = {
		"unlocked": 0,
		"stars": {},
		"settings": save_data.get("settings", {}),
	}
	save_progress()
