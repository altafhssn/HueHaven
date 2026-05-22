extends RefCounted

# Centralized visual style — colors, fonts, builders for buttons / panels.
# All UI screens import this so the look stays consistent.

const BG_TOP := Color("#11112a")
const BG_BOTTOM := Color("#06060f")
const BG_SOLID := Color("#0D0D1A")

const PANEL := Color("#181830")
const PANEL_HI := Color("#22224a")
const PANEL_BORDER := Color("#2e2e58")

const ACCENT := Color("#e8d5a3")
const ACCENT_DIM := Color("#a89a78")
const ACCENT_GLOW := Color("#e8d5a3", 0.18)

const TEXT := Color("#e8d5a3")
const TEXT_MUTED := Color("#7a7a96")
const TEXT_DIM := Color("#4a4a66")

const STAR := Color("#FFD700")
const DANGER := Color("#ff7a7a")
const SUCCESS := Color("#9be38a")

const TUBE_BG := Color("#15152a")
const TUBE_BG_HI := Color("#22224a")
const TUBE_BORDER := Color("#2a2a4e")
const TUBE_INNER_SHADOW := Color("#000000", 0.35)

static func make_button_style(bg: Color, border: Color, radius := 8) -> StyleBoxFlat:
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
	return sb

static func style_button(btn: Button, primary := false) -> void:
	var bg: Color = PANEL
	var hi: Color = PANEL_HI
	var border: Color = PANEL_BORDER
	if primary:
		bg = Color("#3a2f1a")
		hi = Color("#4a3a22")
		border = ACCENT
	btn.add_theme_stylebox_override("normal", make_button_style(bg, border))
	btn.add_theme_stylebox_override("hover", make_button_style(hi, ACCENT))
	btn.add_theme_stylebox_override("pressed", make_button_style(Color("#0e0e1f"), border))
	btn.add_theme_stylebox_override("disabled", make_button_style(Color("#0e0e1a"), Color("#1c1c30")))
	btn.add_theme_stylebox_override("focus", make_button_style(Color(0, 0, 0, 0), Color("#e8d5a3", 0.6)))
	btn.add_theme_color_override("font_color", TEXT)
	btn.add_theme_color_override("font_hover_color", Color("#fff5d8"))
	btn.add_theme_color_override("font_pressed_color", ACCENT_DIM)
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

# Vertical gradient background drawn into a CanvasItem.
static func draw_background(ci: CanvasItem, viewport: Vector2) -> void:
	# Solid base
	ci.draw_rect(Rect2(Vector2.ZERO, viewport), BG_BOTTOM)
	# Three-band vertical gradient via stacked translucent rects
	var bands := 24
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var col := BG_TOP.lerp(BG_BOTTOM, t)
		var y := viewport.y * float(i) / bands
		var h := viewport.y / bands + 1
		ci.draw_rect(Rect2(Vector2(0, y), Vector2(viewport.x, h)), col)
	# Top spotlight glow
	ci.draw_circle(Vector2(viewport.x * 0.5, -40), viewport.x * 0.8, Color("#e8d5a3", 0.04))

# Decorative star particles in the background (static, seeded).
static func draw_stars(ci: CanvasItem, viewport: Vector2, seed_val: int = 7) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for _i in range(36):
		var x := rng.randf() * viewport.x
		var y := rng.randf() * viewport.y
		var r := rng.randf_range(0.6, 1.4)
		var a := rng.randf_range(0.05, 0.18)
		ci.draw_circle(Vector2(x, y), r, Color(1, 1, 1, a))

# Rounded rect filled with a vertical gradient (top->bottom).
static func draw_gradient_rect(ci: CanvasItem, rect: Rect2, top: Color, bottom: Color, radius: float = 8.0) -> void:
	# Approximate with stacked horizontal strips
	var strips := int(rect.size.y / 2)
	for i in range(strips):
		var t := float(i) / float(strips - 1)
		var col := top.lerp(bottom, t)
		var y := rect.position.y + float(i) * (rect.size.y / strips)
		ci.draw_rect(Rect2(Vector2(rect.position.x, y), Vector2(rect.size.x, rect.size.y / strips + 1)), col)
	# Overlay rounded corner mask via outline
	_draw_rounded_outline(ci, rect, radius, Color(0, 0, 0, 0), false, 0)

static func _draw_rounded_outline(ci: CanvasItem, rect: Rect2, radius: float, color: Color, filled: bool, width: float) -> void:
	var r = min(radius, rect.size.x / 2, rect.size.y / 2)
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
