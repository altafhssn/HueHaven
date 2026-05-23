extends RefCounted

# Claude dark palette — warm dark brown, terracotta accent, refined spacing.

# --- Background (warm dark, not cold navy) ---
const BG_TOP := Color("#221C16")
const BG_BOTTOM := Color("#14100C")
const BG_SOLID := Color("#1A1612")

# --- Panels & cards ---
const PANEL := Color("#2A231C")
const PANEL_HI := Color("#332B23")
const PANEL_BORDER := Color("#3D342B")
const PANEL_BORDER_HI := Color("#4F4538")

# --- Accent (Claude terracotta) ---
const ACCENT := Color("#D97757")
const ACCENT_HI := Color("#E5896B")
const ACCENT_DIM := Color("#B85F44")
const ACCENT_GLOW := Color("#D97757", 0.18)

# --- Text (warm cream, not stark white) ---
const TEXT := Color("#F0EAD5")
const TEXT_MUTED := Color("#9B9281")
const TEXT_DIM := Color("#5C5448")

# --- Semantic ---
const STAR := Color("#E8B850")
const DANGER := Color("#D96A57")
const SUCCESS := Color("#88B070")

# --- Tubes ---
const TUBE_BG := Color("#1F1A14")
const TUBE_BG_HI := Color("#2B2419")
const TUBE_BORDER := Color("#3D342B")
const TUBE_INNER_SHADOW := Color("#000000", 0.30)

# --- Buttons ---
const BTN_BG := Color("#2A231C")
const BTN_BG_HOVER := Color("#332B23")
const BTN_BG_PRESSED := Color("#1A1612")
const BTN_BORDER := Color("#3D342B")

static func make_button_style(bg: Color, border: Color, radius := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0, 0, 0, 0.30)
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
		border = ACCENT
		text_col = Color("#1A1208")
	btn.add_theme_stylebox_override("normal", make_button_style(bg, border))
	btn.add_theme_stylebox_override("hover", make_button_style(hi, ACCENT if not primary else ACCENT_HI))
	btn.add_theme_stylebox_override("pressed", make_button_style(pressed, border))
	btn.add_theme_stylebox_override("disabled", make_button_style(Color("#1A1612"), Color("#252019")))
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

# Static background (used by main menu / settings)
static func draw_background(ci: CanvasItem, viewport: Vector2) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, viewport), BG_TOP)
	var bands := 24
	for i in range(bands):
		var t: float = float(i) / float(bands - 1)
		var col: Color = BG_TOP.lerp(BG_BOTTOM, t)
		var y: float = viewport.y * float(i) / float(bands)
		var h: float = viewport.y / float(bands) + 1.0
		ci.draw_rect(Rect2(Vector2(0, y), Vector2(viewport.x, h)), col)
	# A single soft warm glow at top-left
	ci.draw_circle(Vector2(viewport.x * 0.2, viewport.y * 0.1), viewport.x * 0.7,
		Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.04))

# Animated background — two slow warm glows that breathe across the screen.
# Subtle by design: ambient, not decorative.
static func draw_animated_background(ci: CanvasItem, viewport: Vector2, t: float) -> void:
	# Warm dark gradient base
	ci.draw_rect(Rect2(Vector2.ZERO, viewport), BG_TOP)
	var bands := 20
	for i in range(bands):
		var grad_t: float = float(i) / float(bands - 1)
		var col: Color = BG_TOP.lerp(BG_BOTTOM, grad_t)
		var y: float = viewport.y * float(i) / float(bands)
		var h: float = viewport.y / float(bands) + 1.0
		ci.draw_rect(Rect2(Vector2(0, y), Vector2(viewport.x, h)), col)

	# Two slow warm glows — terracotta near top, soft amber near bottom.
	# Lissajous-style drift, gentle.
	var glow_a_x: float = viewport.x * (0.35 + 0.15 * sin(t * 0.08))
	var glow_a_y: float = viewport.y * (0.18 + 0.08 * cos(t * 0.05))
	var glow_a_r: float = viewport.x * 0.85
	_draw_soft_glow(ci, Vector2(glow_a_x, glow_a_y), glow_a_r,
		Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.035))

	var glow_b_x: float = viewport.x * (0.65 + 0.18 * sin(t * 0.06 + 2.1))
	var glow_b_y: float = viewport.y * (0.78 + 0.10 * cos(t * 0.04 + 2.1))
	var glow_b_r: float = viewport.x * 0.95
	_draw_soft_glow(ci, Vector2(glow_b_x, glow_b_y), glow_b_r,
		Color(0.85, 0.65, 0.45, 0.025))

	# Top edge subtle gradient — feels like ambient light from above
	for i in range(8):
		var alpha: float = (1.0 - float(i) / 8.0) * 0.025
		ci.draw_rect(Rect2(Vector2(0, float(i) * 6), Vector2(viewport.x, 6)),
			Color(0.95, 0.85, 0.70, alpha))

static func _draw_soft_glow(ci: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	# Three stacked translucent circles approximate a soft radial falloff
	ci.draw_circle(center, radius, Color(color.r, color.g, color.b, color.a))
	ci.draw_circle(center, radius * 0.65, Color(color.r, color.g, color.b, color.a * 1.4))
	ci.draw_circle(center, radius * 0.35, Color(color.r, color.g, color.b, color.a * 2.0))

# Legacy stub kept for callers — replaced by ambient draw_animated_background.
static func draw_stars(ci: CanvasItem, viewport: Vector2, seed_val: int = 7) -> void:
	pass

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
