extends RefCounted

# Claude dark palette — warm dark brown, terracotta accent, refined spacing.

# --- Background: underwater (deep teal → abyss) ---
const BG_TOP := Color("#0F3954")
const BG_MID := Color("#0A2A40")
const BG_BOTTOM := Color("#040E1A")
const BG_SOLID := Color("#0A2A40")

# --- Panels & cards (dark teal panels) ---
const PANEL := Color("#0E2A40")
const PANEL_HI := Color("#143A55")
const PANEL_BORDER := Color("#1E4866")
const PANEL_BORDER_HI := Color("#3A6890")

# --- Accent (warm orange for primary actions — pops on teal) ---
const ACCENT := Color("#FF8C5A")
const ACCENT_HI := Color("#FFA070")
const ACCENT_DIM := Color("#D9683A")
const ACCENT_GLOW := Color("#FF8C5A", 0.30)

# --- Text (cool soft white) ---
const TEXT := Color("#E8F2F8")
const TEXT_MUTED := Color("#8AA8BE")
const TEXT_DIM := Color("#4A6478")

# --- Semantic ---
const STAR := Color("#FFD060")
const DANGER := Color("#FF6A5A")
const SUCCESS := Color("#7AD89A")

# --- Tubes (glass vials) ---
const TUBE_BG := Color("#0A2236")
const TUBE_BG_HI := Color("#143A55")
const TUBE_BORDER := Color("#3A6890")
const TUBE_INNER_SHADOW := Color("#000000", 0.40)

# --- Buttons ---
const BTN_BG := Color("#0E2A40")
const BTN_BG_HOVER := Color("#163B55")
const BTN_BG_PRESSED := Color("#06182A")
const BTN_BORDER := Color("#2A5070")

static func make_button_style(bg: Color, border: Color, radius := 24) -> StyleBoxFlat:
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

# Static background — same look as animated, but with t=0.
static func draw_background(ci: CanvasItem, viewport: Vector2) -> void:
	draw_animated_background(ci, viewport, 0.0)

# Underwater background: deep teal gradient, god rays from above,
# drifting bubble particles, ambient floor glow.
static func draw_animated_background(ci: CanvasItem, viewport: Vector2, t: float) -> void:
	# --- (1) Three-stop vertical gradient: surface light → mid → abyss ---
	var bands := 32
	for i in range(bands):
		var pos: float = float(i) / float(bands - 1)
		var col: Color
		if pos < 0.5:
			col = BG_TOP.lerp(BG_MID, pos * 2.0)
		else:
			col = BG_MID.lerp(BG_BOTTOM, (pos - 0.5) * 2.0)
		var y: float = viewport.y * float(i) / float(bands)
		var h: float = viewport.y / float(bands) + 1.0
		ci.draw_rect(Rect2(Vector2(0, y), Vector2(viewport.x, h)), col)

	# --- (2) God rays: vertical light shafts from above ---
	# Slight horizontal drift over time
	var rays := [
		[0.12, 0.07, 0.10],   # x_top_norm, width_norm, alpha
		[0.32, 0.09, 0.07],
		[0.50, 0.08, 0.13],
		[0.68, 0.10, 0.09],
		[0.88, 0.08, 0.06],
	]
	for ray_data in rays:
		var x_norm: float = ray_data[0] + sin(t * 0.15 + ray_data[0] * 10.0) * 0.015
		var w_norm: float = ray_data[1]
		var alpha: float = ray_data[2]
		_draw_god_ray(ci, viewport, x_norm, w_norm, alpha)

	# --- (3) Top surface glow (sunlight from above) ---
	ci.draw_circle(Vector2(viewport.x * 0.5, -60), viewport.x * 0.95,
		Color(0.55, 0.78, 0.92, 0.10))
	ci.draw_circle(Vector2(viewport.x * 0.5, -30), viewport.x * 0.7,
		Color(0.70, 0.85, 0.95, 0.08))

	# --- (4) Drifting bubble particles ---
	# Pseudo-random fixed-spawn positions, animated upward; wrap on top.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var bubble_count := 28
	for i in range(bubble_count):
		var base_x: float = rng.randf() * viewport.x
		var seed_y: float = rng.randf() * viewport.y
		var radius: float = rng.randf_range(1.2, 3.5)
		var speed: float = rng.randf_range(8.0, 22.0)
		var drift_amp: float = rng.randf_range(6.0, 18.0)
		var phase: float = rng.randf() * TAU
		# Wrap the y position upward
		var y_pos: float = fposmod(seed_y - t * speed, viewport.y + 40.0) - 20.0
		var x_pos: float = base_x + sin(t * 0.4 + phase) * drift_amp
		var alpha: float = 0.18 + 0.12 * sin(t * 0.5 + phase)
		# Outer halo
		ci.draw_circle(Vector2(x_pos, y_pos), radius * 1.6, Color(0.7, 0.9, 1.0, alpha * 0.35))
		# Body
		ci.draw_circle(Vector2(x_pos, y_pos), radius, Color(0.85, 0.95, 1.0, alpha))
		# Specular
		ci.draw_circle(Vector2(x_pos - radius * 0.3, y_pos - radius * 0.3), radius * 0.35,
			Color(1, 1, 1, alpha * 0.9))

	# --- (5) Bottom abyss vignette ---
	for i in range(6):
		var alpha2: float = float(i) / 6.0 * 0.18
		var h: float = 24.0
		ci.draw_rect(Rect2(Vector2(0, viewport.y - float(i + 1) * h), Vector2(viewport.x, h)),
			Color(0, 0, 0, alpha2))

static func _draw_god_ray(ci: CanvasItem, viewport: Vector2, x_norm: float, w_norm: float, alpha: float) -> void:
	# Trapezoid widening downward, with soft falloff via layered polygons.
	var x_top: float = viewport.x * x_norm
	var width_top: float = viewport.x * w_norm
	var width_bot: float = viewport.x * w_norm * 2.4
	var height: float = viewport.y * 0.75
	# Center the bottom trapezoid below the top
	var x_top_a: float = x_top - width_top * 0.5
	var x_top_b: float = x_top + width_top * 0.5
	var x_bot_a: float = x_top - width_bot * 0.5
	var x_bot_b: float = x_top + width_bot * 0.5
	# 3 stacked polygons for soft edges
	for k in range(3):
		var scale: float = 1.0 + float(k) * 0.5
		var a: float = alpha / (float(k) + 1.0)
		var col := Color(0.85, 0.95, 1.0, a)
		var pts := PackedVector2Array([
			Vector2(x_top - width_top * scale * 0.5, 0),
			Vector2(x_top + width_top * scale * 0.5, 0),
			Vector2(x_top + width_bot * scale * 0.5, height),
			Vector2(x_top - width_bot * scale * 0.5, height),
		])
		ci.draw_colored_polygon(pts, col)

# Stubs kept for backward compatibility
static func draw_stars(_ci: CanvasItem, _viewport: Vector2, _seed_val: int = 7) -> void:
	pass

static func _draw_soft_glow(ci: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	ci.draw_circle(center, radius, Color(color.r, color.g, color.b, color.a))
	ci.draw_circle(center, radius * 0.65, Color(color.r, color.g, color.b, color.a * 1.4))
	ci.draw_circle(center, radius * 0.35, Color(color.r, color.g, color.b, color.a * 2.0))

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
