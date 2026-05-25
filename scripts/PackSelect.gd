extends Control

# Pack select — 2x3 tile grid of themed packs, locked behind star thresholds.

const StyleScript = preload("res://scripts/Style.gd")
const IconScript = preload("res://scripts/Icon.gd")
var LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
var ProgressionScript = preload("res://scripts/Progression.gd")

var main_ref = null
var progression = null

# Layout
const COLS: int = 2
const CELL_W: float = 210.0
const CELL_H: float = 180.0
const CELL_GAP: float = 16.0
const GRID_TOP: float = 150.0

var tiles: Array = []

func _ready():
	progression = ProgressionScript.new()
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	size = viewport
	mouse_filter = Control.MOUSE_FILTER_PASS

	# Back to main menu
	add_child(_icon_btn("back", Vector2(16, 16), 44, _on_back))

	# Title
	add_child(StyleScript.make_label("CHAPTERS", 12, StyleScript.TEXT_DIM,
		Vector2(0, 28), Vector2(viewport.x, 16)))
	add_child(StyleScript.make_label("Choose Your Path", 22, StyleScript.TEXT,
		Vector2(0, 48), Vector2(viewport.x, 30)))

	# Total stars indicator — custom-drawn so the star is geometric, not unicode
	var stars_holder := Control.new()
	stars_holder.name = "TotalStarsHolder"
	stars_holder.position = Vector2(0, 86)
	stars_holder.size = Vector2(viewport.x, 26)
	stars_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stars_holder.draw.connect(func():
		var stars: int = progression.total_stars() if progression else 0
		var text: String = str(stars) + " stars earned"
		var font := ThemeDB.fallback_font
		var fs: int = 14
		var text_w: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var total_w: float = 22 + 6 + text_w.x  # star + gap + text
		var x0: float = (stars_holder.size.x - total_w) * 0.5
		IconScript.draw(stars_holder, "star", Vector2(x0 + 11, stars_holder.size.y * 0.5), 22, StyleScript.STAR)
		font.draw_string(stars_holder.get_canvas_item(),
			Vector2(x0 + 28, stars_holder.size.y * 0.5 + 5),
			text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, StyleScript.TEXT)
	)
	add_child(stars_holder)

	_build_tiles(viewport)

	set_process(true)

func _process(_delta):
	queue_redraw()

func _build_tiles(viewport: Vector2):
	var packs: Array = LevelGeneratorScript.get_packs()
	var grid_w: float = float(COLS) * CELL_W + float(COLS - 1) * CELL_GAP
	var grid_offset_x: float = (viewport.x - grid_w) / 2.0
	var start_level: int = 0
	for i in range(packs.size()):
		var pack = packs[i]
		var col: int = i % COLS
		var row: int = int(i / COLS)
		var x: float = grid_offset_x + float(col) * (CELL_W + CELL_GAP)
		var y: float = GRID_TOP + float(row) * (CELL_H + CELL_GAP)
		var tile := _make_pack_tile(i, pack, start_level, Vector2(x, y))
		add_child(tile)
		tiles.append(tile)
		start_level += pack.levels

func _make_pack_tile(pack_idx: int, pack: Dictionary, start_level: int, pos: Vector2) -> Control:
	var unlock_req: int = int(pack.get("unlock_stars", 0))
	var unlocked: bool = progression.total_stars() >= unlock_req
	var pack_stars: int = progression.pack_stars(start_level, pack.levels)
	var max_stars: int = pack.levels * 3
	var theme_idx: int = StyleScript.theme_for_pack(pack_idx)

	# Per-theme accent + background tint for this tile
	var palette := _palette_for_theme(theme_idx)
	var accent: Color = palette[2]

	# Container is a Button so the whole tile is clickable
	var btn := Button.new()
	btn.position = pos
	btn.size = Vector2(CELL_W, CELL_H)
	btn.disabled = not unlocked
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = ""

	# Card background — themed gradient inside a rounded panel
	var sb := StyleBoxFlat.new()
	if unlocked:
		sb.bg_color = palette[0]
		sb.border_color = accent
	else:
		# Locked: muted grayish cream (slightly darker than panel) + soft tan border
		sb.bg_color = Color("#E0D4C0")
		sb.border_color = Color("#B59B82")
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_left = 18
	sb.corner_radius_bottom_right = 18
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", _hover_style(sb, accent))
	btn.add_theme_stylebox_override("pressed", _pressed_style(sb))
	btn.add_theme_stylebox_override("disabled", sb)

	# Glyph layer — custom drawing for accent glow + content
	var glyph := Control.new()
	glyph.size = btn.size
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.set_meta("pack_idx", pack_idx)
	glyph.set_meta("unlocked", unlocked)
	glyph.set_meta("pack_stars", pack_stars)
	glyph.set_meta("max_stars", max_stars)
	glyph.set_meta("unlock_req", unlock_req)
	glyph.set_meta("accent", accent)
	glyph.set_meta("name", pack.name)
	glyph.set_meta("tagline", pack.get("tagline", ""))
	glyph.draw.connect(_draw_pack_tile_content.bind(glyph))
	btn.add_child(glyph)

	if unlocked:
		btn.pressed.connect(func(): _on_pack_chosen(pack_idx))

	return btn

func _draw_pack_tile_content(glyph: Control) -> void:
	var unlocked: bool = glyph.get_meta("unlocked", false)
	var pack_stars: int = glyph.get_meta("pack_stars", 0)
	var max_stars: int = glyph.get_meta("max_stars", 1)
	var unlock_req: int = glyph.get_meta("unlock_req", 0)
	var accent: Color = glyph.get_meta("accent", StyleScript.ACCENT)
	var pack_name: String = glyph.get_meta("name", "")
	var tagline: String = glyph.get_meta("tagline", "")
	var w: float = glyph.size.x
	var h: float = glyph.size.y

	if unlocked:
		# Soft accent glow at top — gives each tile a unique color identity
		glyph.draw_circle(Vector2(w * 0.5, h * 0.25), w * 0.55,
			Color(accent.r, accent.g, accent.b, 0.12))
		# Big number — pack ordinal, semi-transparent
		var font := ThemeDB.fallback_font
		var num_str: String = str(glyph.get_meta("pack_idx", 0) + 1)
		var num_size: int = 64
		var num_w: Vector2 = font.get_string_size(num_str, HORIZONTAL_ALIGNMENT_LEFT, -1, num_size)
		glyph.draw_string(font, Vector2(w * 0.5 - num_w.x * 0.5, h * 0.45),
			num_str, HORIZONTAL_ALIGNMENT_LEFT, -1, num_size,
			Color(accent.r, accent.g, accent.b, 0.40))

		# Pack name
		var name_size: int = 22
		var name_w: Vector2 = font.get_string_size(pack_name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size)
		glyph.draw_string(font, Vector2(w * 0.5 - name_w.x * 0.5, h * 0.62),
			pack_name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size, StyleScript.TEXT)

		# Tagline
		var tag_size: int = 11
		var tag_w: Vector2 = font.get_string_size(tagline, HORIZONTAL_ALIGNMENT_LEFT, -1, tag_size)
		glyph.draw_string(font, Vector2(w * 0.5 - tag_w.x * 0.5, h * 0.62 + 18),
			tagline, HORIZONTAL_ALIGNMENT_LEFT, -1, tag_size, StyleScript.TEXT_MUTED)

		# Star badge bottom-right — bigger star + clearer count
		var badge_w: float = 80.0
		var badge_h: float = 30.0
		var badge_x: float = w - badge_w - 10
		var badge_y: float = h - badge_h - 10
		StyleScript.draw_rounded_rect(glyph, Rect2(badge_x, badge_y, badge_w, badge_h),
			Color(0, 0, 0, 0.45), badge_h * 0.5, true)
		IconScript.draw(glyph, "star", Vector2(badge_x + 17, badge_y + badge_h * 0.5), 24, StyleScript.STAR)
		glyph.draw_string(ThemeDB.fallback_font, Vector2(badge_x + 32, badge_y + badge_h * 0.5 + 5),
			str(pack_stars) + "/" + str(max_stars), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, StyleScript.TEXT)
	else:
		# Locked — show lock icon + threshold
		IconScript.draw(glyph, "lock", Vector2(w * 0.5, h * 0.42), 48, StyleScript.TEXT_MUTED)
		var font := ThemeDB.fallback_font
		var msg: String = "Earn " + str(unlock_req) + " stars"
		var msg_size: int = 12
		var msg_w: Vector2 = font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, msg_size)
		glyph.draw_string(font, Vector2(w * 0.5 - msg_w.x * 0.5, h * 0.70),
			msg, HORIZONTAL_ALIGNMENT_LEFT, -1, msg_size, StyleScript.TEXT_MUTED)
		# Faded pack name
		var name_size: int = 16
		var name_w: Vector2 = font.get_string_size(pack_name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size)
		glyph.draw_string(font, Vector2(w * 0.5 - name_w.x * 0.5, h * 0.85),
			pack_name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size, StyleScript.TEXT_DIM)

func _palette_for_theme(theme: int) -> Array:
	# Returns [bg, _unused, accent] — cafe boba flavors, light cream tints
	# so they sit naturally on the cream cafe background.
	match theme:
		StyleScript.THEME_ALCHEMY:
			return [Color("#F4E0C0"), Color(), Color("#C68845")]  # brown sugar
		StyleScript.THEME_SCIFI:
			return [Color("#E8DCEA"), Color(), Color("#9E7CB8")]  # taro
		StyleScript.THEME_FOREST:
			return [Color("#DCEAD0"), Color(), Color("#7DA66A")]  # matcha
		_:
			return [Color("#F5E4D2"), Color(), Color("#E89B7A")]  # milk tea (default)

func _hover_style(base: StyleBoxFlat, accent: Color) -> StyleBoxFlat:
	var sb := base.duplicate()
	sb.bg_color = base.bg_color.lightened(0.06)
	sb.border_color = accent.lightened(0.10)
	return sb

func _pressed_style(base: StyleBoxFlat) -> StyleBoxFlat:
	var sb := base.duplicate()
	sb.bg_color = base.bg_color.darkened(0.08)
	return sb

func _on_pack_chosen(pack_idx: int):
	if main_ref:
		main_ref.show_level_select_for_pack(pack_idx)

func _on_back():
	if main_ref:
		main_ref.show_main_menu()

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
		StyleScript.THEME_UNDERWATER)
