extends Control

# Level Select — pack tabs + chunky tile grid with scroll.

const StyleScript = preload("res://scripts/Style.gd")
const IconScript = preload("res://scripts/Icon.gd")
var LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
var ProgressionScript = preload("res://scripts/Progression.gd")

var progression = null
var main_ref = null

# Layout
const COLS: int = 4
const CELL_SIZE: float = 88.0
const CELL_GAP: float = 14.0
const GRID_TOP: float = 224.0
const GRID_BOTTOM_PAD: float = 24.0

var current_pack_index: int = 0
var level_buttons: Array = []
var scroll_container: ScrollContainer = null
var grid_holder: Control = null

# Pack carousel widgets (rebuilt on pack change)
var pack_name_label: Label = null
var pack_count_label: Label = null
var pack_progress_bar: Control = null
var prev_pack_btn: Button = null
var next_pack_btn: Button = null

func _ready():
	progression = ProgressionScript.new()
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	size = viewport
	mouse_filter = Control.MOUSE_FILTER_PASS

	# Back to main menu (icon button)
	add_child(_icon_btn("back", Vector2(16, 16), 44, _on_back_to_menu))

	# Title
	add_child(StyleScript.make_label("Levels", 17, StyleScript.TEXT_MUTED,
		Vector2(0, 26), Vector2(viewport.x, 22)))

	# Pack carousel — prev arrow, big pack name, next arrow
	_build_pack_carousel(viewport)

	# Scroll container for the level grid
	scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(0, GRID_TOP)
	scroll_container.size = Vector2(viewport.x, viewport.y - GRID_TOP - GRID_BOTTOM_PAD)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll_container)

	grid_holder = Control.new()
	grid_holder.custom_minimum_size = Vector2(viewport.x, 0)  # height set dynamically
	scroll_container.add_child(grid_holder)

	# Default to pack containing highest unlocked
	current_pack_index = _pack_index_for_level(progression.get_highest_unlocked())
	_show_pack(current_pack_index)

func _process(_delta):
	queue_redraw()

func _build_pack_carousel(viewport: Vector2):
	var row_y: float = 72.0
	var row_h: float = 56.0
	var pad: float = 16.0

	# Prev arrow (left)
	prev_pack_btn = _arrow_btn("prev", Vector2(pad, row_y), 44, func(): _on_pack_step(-1))
	add_child(prev_pack_btn)

	# Next arrow (right)
	next_pack_btn = _arrow_btn("next", Vector2(viewport.x - pad - 44, row_y), 44, func(): _on_pack_step(1))
	add_child(next_pack_btn)

	# Pack name (large, centered between arrows)
	pack_name_label = Label.new()
	pack_name_label.add_theme_font_size_override("font_size", 24)
	pack_name_label.add_theme_color_override("font_color", StyleScript.TEXT)
	pack_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pack_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pack_name_label.position = Vector2(pad + 44, row_y)
	pack_name_label.size = Vector2(viewport.x - (pad + 44) * 2, 30)
	pack_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pack_name_label)

	# Pack count + progress (smaller, just under name)
	pack_count_label = Label.new()
	pack_count_label.add_theme_font_size_override("font_size", 12)
	pack_count_label.add_theme_color_override("font_color", StyleScript.TEXT_MUTED)
	pack_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pack_count_label.position = Vector2(0, row_y + 32)
	pack_count_label.size = Vector2(viewport.x, 18)
	pack_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pack_count_label)

	# Slim progress bar (custom-drawn) sitting below the row
	pack_progress_bar = Control.new()
	pack_progress_bar.position = Vector2(pad + 28, row_y + 56)
	pack_progress_bar.size = Vector2(viewport.x - (pad + 28) * 2, 4)
	pack_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pack_progress_bar.set_meta("ratio", 0.0)
	pack_progress_bar.draw.connect(func():
		var ratio: float = pack_progress_bar.get_meta("ratio", 0.0)
		var w: float = pack_progress_bar.size.x
		var h: float = pack_progress_bar.size.y
		# Track
		StyleScript.draw_rounded_rect(pack_progress_bar, Rect2(0, 0, w, h),
			Color(StyleScript.PANEL.r, StyleScript.PANEL.g, StyleScript.PANEL.b, 0.7), h * 0.5, true)
		# Fill
		var fill_w: float = w * clamp(ratio, 0.0, 1.0)
		if fill_w > 1:
			StyleScript.draw_rounded_rect(pack_progress_bar, Rect2(0, 0, fill_w, h),
				StyleScript.ACCENT, h * 0.5, true)
	)
	add_child(pack_progress_bar)

func _on_pack_step(delta: int):
	var packs: Array = LevelGeneratorScript.get_packs()
	current_pack_index = clamp(current_pack_index + delta, 0, packs.size() - 1)
	_show_pack(current_pack_index)
	if scroll_container:
		scroll_container.scroll_vertical = 0

func _refresh_carousel():
	var packs: Array = LevelGeneratorScript.get_packs()
	var pack = packs[current_pack_index]
	var start_level: int = 0
	for i in range(current_pack_index):
		start_level += packs[i].levels
	pack_name_label.text = pack.name
	# Count completed (≥1 star) within pack
	var completed: int = 0
	for i in range(pack.levels):
		if progression.get_stars(start_level + i) > 0:
			completed += 1
	pack_count_label.text = str(completed) + " / " + str(pack.levels) + " complete   ·   Levels " + str(start_level + 1) + "–" + str(start_level + pack.levels)
	pack_progress_bar.set_meta("ratio", float(completed) / float(pack.levels))
	pack_progress_bar.queue_redraw()
	# Disable arrows at ends
	if prev_pack_btn:
		prev_pack_btn.disabled = current_pack_index == 0
	if next_pack_btn:
		next_pack_btn.disabled = current_pack_index == packs.size() - 1

func _pack_index_for_level(level_idx: int) -> int:
	var packs: Array = LevelGeneratorScript.get_packs()
	var cum: int = 0
	for i in range(packs.size()):
		cum += packs[i].levels
		if level_idx < cum:
			return i
	return 0

func _show_pack(pack_idx: int):
	# Clear previous tiles
	for btn in level_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	level_buttons.clear()

	var packs: Array = LevelGeneratorScript.get_packs()
	if pack_idx < 0 or pack_idx >= packs.size():
		return

	var pack = packs[pack_idx]
	var start_level: int = 0
	for i in range(pack_idx):
		start_level += packs[i].levels

	# Refresh the carousel header
	_refresh_carousel()

	# Layout the grid inside grid_holder
	var grid_w: float = float(COLS) * CELL_SIZE + float(COLS - 1) * CELL_GAP
	var grid_offset_x: float = (size.x - grid_w) / 2.0
	var highest_unlocked: int = progression.get_highest_unlocked()

	for i in range(pack.levels):
		var level_idx: int = start_level + i
		var col: int = i % COLS
		var row: int = i / COLS
		var x: float = grid_offset_x + float(col) * (CELL_SIZE + CELL_GAP)
		var y: float = 8.0 + float(row) * (CELL_SIZE + CELL_GAP)
		var is_unlocked: bool = level_idx <= highest_unlocked
		var is_current: bool = level_idx == highest_unlocked
		var stars: int = progression.get_stars(level_idx)
		var btn := _make_level_tile(level_idx, Vector2(x, y), is_unlocked, is_current, stars)
		grid_holder.add_child(btn)
		level_buttons.append(btn)

	var rows: int = int(ceil(float(pack.levels) / float(COLS)))
	var content_h: float = 16.0 + float(rows) * CELL_SIZE + float(rows - 1) * CELL_GAP
	grid_holder.custom_minimum_size = Vector2(size.x, content_h)

func _make_level_tile(level_idx: int, pos: Vector2, unlocked: bool, current: bool, stars: int) -> Control:
	var btn := Button.new()
	btn.position = pos
	btn.size = Vector2(CELL_SIZE, CELL_SIZE)
	btn.disabled = not unlocked
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 22)

	# Visual states
	var bg: Color
	var border: Color
	var text_col: Color
	if current:
		bg = StyleScript.ACCENT
		border = StyleScript.ACCENT_DIM
		text_col = Color("#1a1208")
	elif unlocked:
		# Completed-with-stars or just unlocked
		if stars > 0:
			bg = StyleScript.PANEL_HI
			border = StyleScript.PANEL_BORDER_HI
		else:
			bg = StyleScript.PANEL
			border = StyleScript.PANEL_BORDER
		text_col = StyleScript.TEXT
	else:
		# Locked — darker, dimmed
		bg = Color(StyleScript.PANEL.r * 0.6, StyleScript.PANEL.g * 0.6, StyleScript.PANEL.b * 0.6, 1.0)
		border = Color(StyleScript.PANEL_BORDER.r * 0.6, StyleScript.PANEL_BORDER.g * 0.6, StyleScript.PANEL_BORDER.b * 0.6, 1.0)
		text_col = StyleScript.TEXT_DIM

	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_disabled_color", text_col)
	btn.add_theme_stylebox_override("normal", StyleScript.make_button_style(bg, border, 14))
	btn.add_theme_stylebox_override("hover", StyleScript.make_button_style(bg.lightened(0.08), StyleScript.ACCENT, 14))
	btn.add_theme_stylebox_override("pressed", StyleScript.make_button_style(bg.darkened(0.10), border, 14))
	btn.add_theme_stylebox_override("disabled", StyleScript.make_button_style(bg, border, 14))

	if unlocked:
		btn.text = str(level_idx + 1)
		# Star strip at bottom — geometric stars
		if stars > 0:
			var star_strip := Control.new()
			star_strip.size = Vector2(CELL_SIZE, 14)
			star_strip.position = Vector2(0, CELL_SIZE - 18)
			star_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			star_strip.set_meta("count", stars)
			star_strip.draw.connect(func():
				var n: int = star_strip.get_meta("count", 0)
				var star_size: float = 13.0
				var gap: float = 4.0
				var total: float = float(n) * star_size + float(n - 1) * gap
				var sx0: float = (star_strip.size.x - total) / 2.0 + star_size * 0.5
				for s in range(n):
					var sx: float = sx0 + float(s) * (star_size + gap)
					IconScript.draw(star_strip, "star", Vector2(sx, 7), star_size, StyleScript.STAR)
			)
			btn.add_child(star_strip)
	else:
		btn.text = ""
		var lock_glyph := Control.new()
		lock_glyph.size = btn.size
		lock_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_glyph.draw.connect(func():
			IconScript.draw(lock_glyph, "lock", lock_glyph.size * 0.5, lock_glyph.size.x * 0.55, StyleScript.TEXT_DIM)
		)
		btn.add_child(lock_glyph)

	if unlocked:
		btn.pressed.connect(_on_level_selected.bind(level_idx))
	return btn

func _on_level_selected(level_idx: int):
	if main_ref:
		main_ref.start_level(level_idx)

func _on_back_to_menu():
	if main_ref:
		main_ref.show_main_menu()

func _arrow_btn(icon_name: String, pos: Vector2, sz: float, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = ""
	btn.position = pos
	btn.size = Vector2(sz, sz)
	StyleScript.style_button(btn, false)
	# Round, no border to feel like a chevron control
	var sb := StyleBoxFlat.new()
	sb.bg_color = StyleScript.PANEL
	sb.border_color = StyleScript.PANEL_BORDER
	sb.set_border_width_all(1)
	var rr := int(sz * 0.5)
	sb.corner_radius_top_left = rr
	sb.corner_radius_top_right = rr
	sb.corner_radius_bottom_left = rr
	sb.corner_radius_bottom_right = rr
	btn.add_theme_stylebox_override("normal", sb)
	btn.pressed.connect(callback)
	btn.focus_mode = Control.FOCUS_NONE
	var glyph := Control.new()
	glyph.size = btn.size
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.set_meta("icon", icon_name)
	glyph.draw.connect(func():
		var name: String = glyph.get_meta("icon", "next")
		var icon_n: String = "back" if name == "prev" else "next"
		IconScript.draw(glyph, icon_n, glyph.size * 0.5, glyph.size.x * 0.7, StyleScript.TEXT)
	)
	btn.add_child(glyph)
	return btn

func _icon_btn(icon_name: String, pos: Vector2, sz: float, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = ""
	btn.position = pos
	btn.size = Vector2(sz, sz)
	StyleScript.style_button(btn, false)
	btn.pressed.connect(callback)
	btn.focus_mode = Control.FOCUS_NONE
	var glyph := Control.new()
	glyph.size = btn.size
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.set_meta("icon_name", icon_name)
	glyph.draw.connect(func():
		IconScript.draw(glyph, glyph.get_meta("icon_name", ""), glyph.size * 0.5, glyph.size.x, StyleScript.TEXT)
	)
	btn.add_child(glyph)
	return btn

func _draw():
	var viewport = get_viewport().get_visible_rect().size
	StyleScript.draw_themed_background(self, viewport, Time.get_ticks_msec() / 1000.0,
		StyleScript.theme_for_pack(current_pack_index))
