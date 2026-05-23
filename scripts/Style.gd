extends RefCounted

# Visual style — dark serene palette with warm accents.

# --- Background tones (deep navy → near-black) ---
const BG_TOP := Color("#14142a")
const BG_BOTTOM := Color("#06060f")
const BG_SOLID := Color("#0d0d1a")

# --- Panels & cards ---
const PANEL := Color("#1c1c34")
const PANEL_HI := Color("#2a2a4a")
const PANEL_BORDER := Color("#3a3a5c")
const PANEL_BORDER_HI := Color("#52527a")

# --- Accent (warm terracotta) ---
const ACCENT := Color("#cc785c")
const ACCENT_HI := Color("#d98b6f")
const ACCENT_DIM := Color("#a6604a")
const ACCENT_GLOW := Color("#cc785c", 0.18)

# --- Text ---
const TEXT := Color("#e8dcc4")
const TEXT_MUTED := Color("#7a7468")
const TEXT_DIM := Color("#4a4858")

# --- Semantic ---
const STAR := Color("#f0c860")
const DANGER := Color("#d96363")
const SUCCESS := Color("#7da66a")

# --- Tubes ---
const TUBE_BG := Color("#181830")
const TUBE_BG_HI := Color("#252544")
const TUBE_BORDER := Color("#3e3e62")
const TUBE_INNER_SHADOW := Color("#000000", 0.40)

# --- Buttons ---
const BTN_BG := Color("#1f1f38")
const BTN_BG_HOVER := Color("#2c2c50")
const BTN_BG_PRESSED := Color("#15152a")
const BTN_BORDER := Color("#3a3a5c")

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
	sb.shadow_color = Color(0, 0, 0, 0.25)
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
		text_col = Color("#1a1208")
	btn.add_theme_stylebox_override("normal", make_button_style(bg, border))
	btn.add_theme_stylebox_override("hover", make_button_style(hi, ACCENT))
	btn.add_theme_stylebox_override("pressed", make_button_style(pressed, ACCENT_DIM))
	btn.add_theme_stylebox_override("disabled", make_button_style(Color("#15152a"), Color("#262640")))
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

static func draw_background(ci: CanvasItem, viewport: Vector2) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, viewport), BG_TOP)
	var bands := 24
	for i in range(bands):
		var t: float = float(i) / float(bands - 1)
		var col: Color = BG_TOP.lerp(BG_BOTTOM, t)
		var y: float = viewport.y * float(i) / float(bands)
		var h: float = viewport.y / float(bands) + 1.0
		ci.draw_rect(Rect2(Vector2(0, y), Vector2(viewport.x, h)), col)
	# Top spotlight wash
	ci.draw_circle(Vector2(viewport.x * 0.5, -120), viewport.x * 0.9,
		Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.04))

# Animated background — slowly drifting soft orbs over the dark gradient.
static func draw_animated_background(ci: CanvasItem, viewport: Vector2, t: float) -> void:
	# Dark base gradient
	ci.draw_rect(Rect2(Vector2.ZERO, viewport), BG_TOP)
	var bands := 20
	for i in range(bands):
		var grad_t: float = float(i) / float(bands - 1)
		var col: Color = BG_TOP.lerp(BG_BOTTOM, grad_t)
		var y: float = viewport.y * float(i) / float(bands)
		var h: float = viewport.y / float(bands) + 1.0
		ci.draw_rect(Rect2(Vector2(0, y), Vector2(viewport.x, h)), col)

	var cx: float = viewport.x * 0.5
	var cy: float = viewport.y * 0.5
	# Subtler, jewel-tone orbs on dark — opacity around 4-6%.
	var orbs := [
		# [tint, radius, speed_x, speed_y, amp_x, amp_y, phase]
		[Color(0.85, 0.50, 0.40, 1.0),  viewport.x * 0.55, 0.06, 0.04, viewport.x * 0.35, viewport.y * 0.30, 0.0],   # warm terra
		[Color(0.35, 0.55, 0.70, 1.0),  viewport.x * 0.50, 0.08, 0.05, viewport.x * 0.40, viewport.y * 0.25, 1.7],   # deep teal
		[Color(0.60, 0.50, 0.85, 1.0),  viewport.x * 0.45, 0.05, 0.07, viewport.x * 0.30, viewport.y * 0.32, 3.4],   # dusk purple
		[Color(0.50, 0.65, 0.45, 1.0),  viewport.x * 0.40, 0.07, 0.045, viewport.x * 0.42, viewport.y * 0.28, 5.1],  # muted sage
		[Color(0.85, 0.70, 0.45, 1.0),  viewport.x * 0.42, 0.075, 0.06, viewport.x * 0.32, viewport.y * 0.34, 2.3],  # honey
	]

	for orb in orbs:
		var tint: Color = orb[0]
		var radius: float = orb[1]
		var sx: float = orb[2]
		var sy: float = orb[3]
		var amp_x: float = orb[4]
		var amp_y: float = orb[5]
		var phase: float = orb[6]
		var px: float = cx + sin(t * sx + phase) * amp_x
		var py: float = cy + cos(t * sy + phase * 0.7) * amp_y
		var a: float = 0.05
		ci.draw_circle(Vector2(px, py), radius, Color(tint.r, tint.g, tint.b, a))
		ci.draw_circle(Vector2(px, py), radius * 0.75, Color(tint.r, tint.g, tint.b, a * 1.2))
		ci.draw_circle(Vector2(px, py), radius * 0.50, Color(tint.r, tint.g, tint.b, a * 1.6))

# Faint starfield — almost invisible, used by main menu / settings.
static func draw_stars(ci: CanvasItem, viewport: Vector2, seed_val: int = 7) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for _i in range(40):
		var x: float = rng.randf() * viewport.x
		var y: float = rng.randf() * viewport.y
		var r: float = rng.randf_range(0.6, 1.3)
		var a: float = rng.randf_range(0.05, 0.14)
		ci.draw_circle(Vector2(x, y), r, Color(1, 1, 1, a))

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
