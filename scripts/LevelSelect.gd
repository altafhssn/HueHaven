extends Control

# Level Select — pack tabs + polished tile grid.

const StyleScript = preload("res://scripts/Style.gd")
var LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
var ProgressionScript = preload("res://scripts/Progression.gd")

var progression = null
var main_ref = null

var cols: int = 5
var cell_size: float = 64.0
var cell_gap: float = 10.0
var grid_start_x: float = 0.0
var grid_start_y: float = 200.0

var current_pack_index: int = 0
var pack_tab_buttons: Array = []
var level_buttons: Array = []
var pack_label: Label = null

func _ready():
	progression = ProgressionScript.new()
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	size = viewport
	mouse_filter = Control.MOUSE_FILTER_PASS

	# Back to main menu
	var back := Button.new()
	back.text = "←"
	back.add_theme_font_size_override("font_size", 22)
	StyleScript.style_button(back, false)
	back.size = Vector2(48, 48)
	back.position = Vector2(16, 16)
	back.pressed.connect(_on_back_to_menu)
	back.focus_mode = Control.FOCUS_NONE
	add_child(back)

	# Title
	add_child(StyleScript.make_label("Choose Level", 22, StyleScript.ACCENT,
		Vector2(0, 24), Vector2(viewport.x, 32)))

	# Pack tabs row
	_build_pack_tabs(viewport)

	# Current pack label
	pack_label = StyleScript.make_label("", 12, StyleScript.TEXT_MUTED,
		Vector2(0, 162), Vector2(viewport.x, 20))
	add_child(pack_label)

	# Default to highest unlocked pack
	current_pack_index = _pack_index_for_level(progression.get_highest_unlocked())
	_show_pack(current_pack_index)
	_refresh_tab_styles()

func _build_pack_tabs(viewport: Vector2):
	var packs: Array = LevelGeneratorScript.get_packs()
	var n: int = packs.size()
	var pad: float = 16.0
	var available: float = viewport.x - pad * 2.0
	var gap: float = 6.0
	var tab_w: float = (available - gap * float(n - 1)) / float(n)
	var y: float = 80.0
	for i in range(n):
		var tab := Button.new()
		tab.text = packs[i].name
		tab.add_theme_font_size_override("font_size", 12)
		StyleScript.style_button(tab, false)
		tab.size = Vector2(tab_w, 36)
		tab.position = Vector2(pad + i * (tab_w + gap), y)
		tab.focus_mode = Control.FOCUS_NONE
		var idx := i
		tab.pressed.connect(func(): _on_pack_tab(idx))
		add_child(tab)
		pack_tab_buttons.append(tab)

func _on_pack_tab(idx: int):
	current_pack_index = idx
	_show_pack(idx)
	_refresh_tab_styles()

func _refresh_tab_styles():
	for i in range(pack_tab_buttons.size()):
		var btn: Button = pack_tab_buttons[i]
		if i == current_pack_index:
			# Active tab — terracotta fill, cream text
			btn.add_theme_color_override("font_color", Color("#FFF8EB"))
			btn.add_theme_stylebox_override("normal", StyleScript.make_button_style(StyleScript.ACCENT, StyleScript.ACCENT_DIM))
		else:
			btn.add_theme_color_override("font_color", StyleScript.TEXT_MUTED)
			btn.add_theme_stylebox_override("normal", StyleScript.make_button_style(StyleScript.PANEL, StyleScript.PANEL_BORDER))

func _pack_index_for_level(level_idx: int) -> int:
	var packs = LevelGeneratorScript.get_packs()
	var cum := 0
	for i in range(packs.size()):
		cum += packs[i].levels
		if level_idx < cum:
			return i
	return 0

func _show_pack(pack_idx: int):
	for btn in level_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	level_buttons.clear()

	var packs = LevelGeneratorScript.get_packs()
	if pack_idx < 0 or pack_idx >= packs.size():
		return

	var pack = packs[pack_idx]
	var start_level = 0
	for i in range(pack_idx):
		start_level += packs[i].levels

	pack_label.text = pack.name + "  ·  " + str(start_level + 1) + "–" + str(start_level + pack.levels)

	var viewport: Vector2 = get_viewport().get_visible_rect().size
	cols = 5
	var total_grid_width = cols * cell_size + (cols - 1) * cell_gap
	grid_start_x = (viewport.x - total_grid_width) / 2

	# Highest unlocked overall
	var highest_unlocked = progression.get_highest_unlocked()

	for i in range(pack.levels):
		var level_idx = start_level + i
		var col = i % cols
		var row = i / cols
		var x = grid_start_x + col * (cell_size + cell_gap)
		var y = grid_start_y + row * (cell_size + cell_gap)
		var is_unlocked = level_idx <= highest_unlocked
		var is_current = level_idx == highest_unlocked
		var stars = progression.get_stars(level_idx)
		var btn = _make_level_button(level_idx, Vector2(x, y), is_unlocked, is_current, stars)
		add_child(btn)
		level_buttons.append(btn)

func _make_level_button(level_idx: int, pos: Vector2, unlocked: bool, current: bool, stars: int) -> Control:
	var btn := Button.new()
	btn.position = pos
	btn.size = Vector2(cell_size, cell_size)
	btn.disabled = not unlocked
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", StyleScript.TEXT)
	btn.add_theme_color_override("font_disabled_color", StyleScript.TEXT_DIM)

	var bg: Color = StyleScript.PANEL
	var border: Color = StyleScript.PANEL_BORDER
	if current:
		# Current level: terracotta fill, cream text
		bg = StyleScript.ACCENT
		border = StyleScript.ACCENT_DIM
		btn.add_theme_color_override("font_color", Color("#FFF8EB"))
	elif not unlocked:
		bg = Color("#E0DAC8")
		border = Color("#CFC6AC")
	btn.add_theme_stylebox_override("normal", StyleScript.make_button_style(bg, border, 12))
	btn.add_theme_stylebox_override("hover", StyleScript.make_button_style(StyleScript.PANEL_HI, StyleScript.ACCENT, 12))
	btn.add_theme_stylebox_override("pressed", StyleScript.make_button_style(StyleScript.PANEL_HI.darkened(0.08), border, 12))
	btn.add_theme_stylebox_override("disabled", StyleScript.make_button_style(bg, border, 12))

	if unlocked:
		btn.text = str(level_idx + 1)
		if stars > 0:
			var star_text := ""
			for s in range(stars):
				star_text += "★"
			for s in range(3 - stars):
				star_text += "·"
			var sl := Label.new()
			sl.text = star_text
			sl.add_theme_font_size_override("font_size", 10)
			sl.add_theme_color_override("font_color", StyleScript.STAR)
			sl.size = Vector2(cell_size, 12)
			sl.position = Vector2(0, cell_size - 14)
			sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(sl)
	else:
		btn.text = "🔒"
		btn.add_theme_font_size_override("font_size", 22)

	btn.pressed.connect(_on_level_selected.bind(level_idx))
	return btn

func _on_level_selected(level_idx: int):
	if main_ref:
		main_ref.start_level(level_idx)

func _on_back_to_menu():
	if main_ref:
		main_ref.show_main_menu()

func _draw():
	var viewport = get_viewport().get_visible_rect().size
	StyleScript.draw_background(self, viewport)
	StyleScript.draw_stars(self, viewport, 5)
