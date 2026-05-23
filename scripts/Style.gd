extends RefCounted

# Visual style — Claude-inspired warm/cream palette.
# Centralized so every screen stays consistent.

# --- Background tones (warm cream paper) ---
const BG_TOP := Color("#F7F3E8")
const BG_BOTTOM := Color("#EBE4D0")
const BG_SOLID := Color("#F5F1E8")

# --- Panels & cards ---
const PANEL := Color("#EFE9D6")
const PANEL_HI := Color("#E5DDC4")
const PANEL_BORDER := Color("#D8CFB3")
const PANEL_BORDER_HI := Color("#C2B58F")

# --- Accent (Claude terracotta) ---
const ACCENT := Color("#CC785C")
const ACCENT_HI := Color("#D98B6F")
const ACCENT_DIM := Color("#A6604A")
const ACCENT_GLOW := Color("#CC785C", 0.18)

# --- Text ---
const TEXT := Color("#2D2A24")
const TEXT_MUTED := Color("#8A8170")
const TEXT_DIM := Color("#B5AC97")

# --- Semantic ---
const STAR := Color("#D9A949")        # warm gold, not neon yellow
const DANGER := Color("#C5604D")
const SUCCESS := Color("#7E9D62")

# --- Tubes (lighter, glass-on-paper) ---
const TUBE_BG := Color("#E8DFC6")
const TUBE_BG_HI := Color("#F1E9D3")
const TUBE_BORDER := Color("#C2B58F")
const TUBE_INNER_SHADOW := Color("#3B3528", 0.08)

# --- Buttons ---
const BTN_BG := Color("#EFE9D6")
const BTN_BG_HOVER := Color("#E0D6B8")
const BTN_BG_PRESSED := Color("#D4C9A4")
const BTN_BORDER := Color("#C2B58F")

static func make_button_style(bg: Color, border: Color, radius := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0.18, 0.16, 0.12, 0.08)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(0, 1)
	return sb

static func style_button(btn: Button, primary := false) -> void:
	var bg: Color = BTN_BG
	var hi: Color = BTN_BG_HOVER
	var pressed: Color = BTN_BG_PRESSED
	var border: Color = BTN_BORDER
	var text_col: Color = TEXT
	if primary:
		bg = ACCENT
		hi = ACCENT_HI
		pressed = ACCENT_DIM
		border = ACCENT_DIM
		text_col = Color("#FFF8EB")
	btn.add_theme_stylebox_override("normal", make_button_style(bg, border))
	btn.add_theme_stylebox_override("hover", make_button_style(hi, ACCENT))
	btn.add_theme_stylebox_override("pressed", make_button_style(pressed, ACCENT_DIM))
	btn.add_theme_stylebox_override("disabled", make_button_style(Color("#E8E2D2"), Color("#D2C9AE")))
	btn.add_theme_stylebox_override("focus", make_button_style(Color(0, 0, 0, 0), ACCENT))
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", text_col)
	btn.add_theme_color_override("font_pressed_color", text_col)
	btn.add_theme_color_override("font_disabled_color", TEXT_DIM)

static func make_label(text: String, font_size: int, color: Color, pos: Vector2, size: Vector2, h_align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.position = pos
	lbl.size = size
	lbl.horizontal_alignment = h_align
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

# Warm cream gradient — paper feel.
static func draw_background(ci: CanvasItem, viewport: Vector2) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, viewport), BG_TOP)
	var bands := 24
	for i in range(bands):
		var t: float = float(i) / float(bands - 1)
		var col: Color = BG_TOP.lerp(BG_BOTTOM, t)
		var y: float = viewport.y * float(i) / float(bands)
		var h: float = viewport.y / float(bands) + 1.0
		ci.draw_rect(Rect2(Vector2(0, y), Vector2(viewport.x, h)), col)
	# Soft terracotta wash near top (warm spotlight)
	ci.draw_circle(Vector2(viewport.x * 0.5, -120), viewport.x * 0.9, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.05))

# Subtle paper-grain dots — replaces the cold starfield.
static func draw_stars(ci: CanvasItem, viewport: Vector2, seed_val: int = 7) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for _i in range(60):
		var x: float = rng.randf() * viewport.x
		var y: float = rng.randf() * viewport.y
		var r: float = rng.randf_range(0.5, 1.2)
		var a: float = rng.randf_range(0.04, 0.10)
		ci.draw_circle(Vector2(x, y), r, Color(0.18, 0.14, 0.08, a))

# Rounded rect filled with a vertical gradient (top → bottom).
static func draw_gradient_rect(ci: CanvasItem, rect: Rect2, top: Color, bottom: Color, _radius: float = 8.0) -> void:
	var strips := int(rect.size.y / 2.0)
	if strips < 2: strips = 2
	for i in range(strips):
		var t: float = float(i) / float(strips - 1)
		var col: Color = top.lerp(bottom, t)
		var y: float = rect.position.y + float(i) * (rect.size.y / float(strips))
		ci.draw_rect(Rect2(Vector2(rect.position.x, y), Vector2(rect.size.x, rect.size.y / float(strips) + 1.0)), col)

static func _draw_rounded_outline(ci: CanvasItem, rect: Rect2, radius: float, color: Color, filled: bool, width: float) -> void:
	var r: float = min(radius, rect.size.x / 2.0, rect.size.y / 2.0)
	var pts := PackedVector2Array([
		rect.position + Vector2(r, 0),
		rect.position + Vector2(rect.size.x - r, 0),
		rect.position + Vector2(rect.size.x, r),
		rect.position + Vector2(rect.size.x, rect.size.y - r),
		rect.position + Vector2(rect.size.x - r, rect.size.y),
		rect.position + Vector2(r, rect.size.y),
		rect.position + Vector2(0, rect.size.y - r),
		rect.position + Vector2(0, r),
	])
	if filled:
		ci.draw_colored_polygon(pts, color)
	elif width > 0:
		var outline := PackedVector2Array()
		outline.resize(pts.size() + 1)
		for i in range(pts.size()):
			outline[i] = pts[i]
		outline[pts.size()] = pts[0]
		ci.draw_polyline(outline, color, width, true)

static func draw_rounded_rect(ci: CanvasItem, rect: Rect2, color: Color, radius: float = 8.0, filled: bool = true, width: float = 1.0) -> void:
	_draw_rounded_outline(ci, rect, radius, color, filled, width)
