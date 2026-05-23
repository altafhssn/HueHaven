extends Control

# Level Select — shows the level tiles within a single chosen pack.
# Pack selection itself lives on PackSelect screen.

const StyleScript = preload("res://scripts/Style.gd")
const IconScript = preload("res://scripts/Icon.gd")
var LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
var ProgressionScript = preload("res://scripts/Progression.gd")

var progression = null
var main_ref = null

# Caller sets this BEFORE add_child(level_select)
var pack_index: int = 0

# Layout
const COLS: int = 4
const CELL_SIZE: float = 88.0
const CELL_GAP: float = 14.0
const GRID_TOP: float = 180.0
const GRID_BOTTOM_PAD: float = 24.0

var level_buttons: Array = []
var scroll_container: ScrollContainer = null
var grid_holder: Control = null
var progress_bar: Control = null

func _ready():
	progression = ProgressionScript.new()
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	size = viewport
	mouse_filter = Control.MOUSE_FILTER_PASS

	# Back to pack select
	add_child(_icon_btn("back", Vector2(16, 16), 44, _on_back_to_packs))

	var packs: Array = LevelGeneratorScript.get_packs()
	if pack_index < 0 or pack_index >= packs.size():
		pack_index = 0
	var pack = packs[pack_index]
	var start_level: int = 0
	for i in range(pack_index):
		start_level += packs[i].levels

	# Pack name (big, centered)
	add_child(StyleScript.make_label(pack.name, 28, StyleScript.TEXT,
		Vector2(0, 22), Vector2(viewport.x, 36)))
	# Tagline
	add_child(StyleScript.make_label(pack.get("tagline", ""), 12, StyleScript.TEXT_MUTED,
		Vector2(0, 62), Vector2(viewport.x, 16)))

	# Progress text + slim bar
	var completed: int = 0
	for i in range(pack.levels):
		if progression.get_stars(start_level + i) > 0:
			completed += 1
	add_child(StyleScript.make_label(
		str(completed) + " / " + str(pack.levels) + " complete",
		12, StyleScript.TEXT_MUTED,
		Vector2(0, 92), Vector2(viewport.x, 16)))

	progress_bar = Control.new()
	progress_bar.position = Vector2(60, 116)
	progress_bar.size = Vector2(viewport.x - 120, 4)
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.set_meta("ratio", float(completed) / float(pack.levels))
	progress_bar.draw.connect(func():
		var ratio: float = progress_bar.get_meta("ratio", 0.0)
		var w: float = progress_bar.size.x
		var h: float = progress_bar.size.y
		StyleScript.draw_rounded_rect(progress_bar, Rect2(0, 0, w, h),
			Color(StyleScript.PANEL.r, StyleScript.PANEL.g, StyleScript.PANEL.b, 0.7), h * 0.5, true)
		var fill_w: float = w * clamp(ratio, 0.0, 1.0)
		if fill_w > 1:
			StyleScript.draw_rounded_rect(progress_bar, Rect2(0, 0, fill_w, h),
				StyleScript.ACCENT, h * 0.5, true)
	)
	add_child(progress_bar)

	# Scroll container for the level grid
	scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(0, GRID_TOP)
	scroll_container.size = Vector2(viewport.x, viewport.y - GRID_TOP - GRID_BOTTOM_PAD)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll_container)

	grid_holder = Control.new()
	grid_holder.custom_minimum_size = Vector2(viewport.x, 0)
	scroll_container.add_child(grid_holder)

	_populate_grid(pack, start_level)
	set_process(true)

func _process(_delta):
	queue_redraw()

func _populate_grid(pack: Dictionary, start_level: int):
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

	var bg: Color
	var border: Color
	var text_col: Color
	if current:
		bg = StyleScript.ACCENT
		border = StyleScript.ACCENT_DIM
		text_col = Color("#1a1208")
	elif unlocked:
		if stars > 0:
			bg = StyleScript.PANEL_HI
			border = StyleScript.PANEL_BORDER_HI
		else:
			bg = StyleScript.PANEL
			border = StyleScript.PANEL_BORDER
		text_col = StyleScript.TEXT
	else:
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
		if stars > 0:
			var star_strip := Control.new()
			star_strip.size = Vector2(CELL_SIZE, 18)
			star_strip.position = Vector2(0, CELL_SIZE - 22)
			star_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			star_strip.set_meta("count", stars)
			star_strip.draw.connect(func():
				var n: int = star_strip.get_meta("count", 0)
				var star_size: float = 18.0
				var gap: float = 4.0
				var total: float = float(n) * star_size + float(n - 1) * gap
				var sx0: float = (star_strip.size.x - total) / 2.0 + star_size * 0.5
				for s in range(n):
					var sx: float = sx0 + float(s) * (star_size + gap)
					IconScript.draw(star_strip, "star", Vector2(sx, 9), star_size, StyleScript.STAR)
			)
			btn.add_child(star_strip)
		btn.pressed.connect(_on_level_selected.bind(level_idx))
	else:
		btn.text = ""
		var lock_glyph := Control.new()
		lock_glyph.size = btn.size
		lock_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_glyph.draw.connect(func():
			IconScript.draw(lock_glyph, "lock", lock_glyph.size * 0.5, lock_glyph.size.x * 0.55, StyleScript.TEXT_DIM)
		)
		btn.add_child(lock_glyph)
	return btn

func _on_level_selected(level_idx: int):
	if main_ref:
		main_ref.start_level(level_idx)

func _on_back_to_packs():
	if main_ref:
		main_ref.show_pack_select()

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
		StyleScript.theme_for_pack(pack_index))
