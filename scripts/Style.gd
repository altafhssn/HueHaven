extends RefCounted

# Theme variants — each pack gets a different atmosphere.
const THEME_UNDERWATER := 0
const THEME_ALCHEMY := 1
const THEME_SCIFI := 2
const THEME_FOREST := 3

static func theme_for_pack(pack_idx: int) -> int:
	# Cycle through the 4 themes across 6 packs
	var cycle := [THEME_UNDERWATER, THEME_ALCHEMY, THEME_FOREST, THEME_SCIFI, THEME_ALCHEMY, THEME_FOREST]
	return cycle[pack_idx % cycle.size()]

# Top-level themed background dispatcher.
static func draw_themed_background(ci: CanvasItem, viewport: Vector2, t: float, theme: int) -> void:
	match theme:
		THEME_ALCHEMY: _draw_alchemy_bg(ci, viewport, t)
		THEME_SCIFI:   _draw_scifi_bg(ci, viewport, t)
		THEME_FOREST:  _draw_forest_bg(ci, viewport, t)
		_:             draw_animated_background(ci, viewport, t)  # underwater

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

# --- Alchemy Lab theme: warm stone wall, wood shelves, glowing potions ---
static func _draw_alchemy_bg(ci: CanvasItem, viewport: Vector2, t: float) -> void:
	# Warm stone wall gradient
	var top := Color("#3a2a20")
	var mid := Color("#2b1f17")
	var bot := Color("#1a120c")
	var bands := 28
	for i in range(bands):
		var pos: float = float(i) / float(bands - 1)
		var col: Color
		if pos < 0.5:
			col = top.lerp(mid, pos * 2.0)
		else:
			col = mid.lerp(bot, (pos - 0.5) * 2.0)
		var y: float = viewport.y * float(i) / float(bands)
		var h: float = viewport.y / float(bands) + 1.0
		ci.draw_rect(Rect2(Vector2(0, y), Vector2(viewport.x, h)), col)

	# Faint stone block grid texture
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for ry in range(8):
		for rx in range(6):
			var x: float = float(rx) * (viewport.x / 6.0) + rng.randf_range(-4, 4)
			var y: float = float(ry) * (viewport.y / 8.0) + rng.randf_range(-3, 3)
			var w: float = viewport.x / 6.0
			var h: float = viewport.y / 8.0
			ci.draw_rect(Rect2(Vector2(x, y), Vector2(w, h)),
				Color(0, 0, 0, rng.randf_range(0.02, 0.08)), false)

	# Wood shelf silhouettes (3 horizontal bars)
	for shelf_y in [viewport.y * 0.16, viewport.y * 0.42, viewport.y * 0.68]:
		var shelf_rect := Rect2(0, shelf_y, viewport.x, 10)
		ci.draw_rect(shelf_rect, Color("#3a2415"))
		ci.draw_rect(Rect2(0, shelf_y, viewport.x, 2), Color("#5a3a25"))
		ci.draw_rect(Rect2(0, shelf_y + 8, viewport.x, 2), Color(0, 0, 0, 0.3))

	# Glowing potion bottle silhouettes on each shelf
	var bottle_colors := [
		Color("#a040c0"), Color("#40c060"), Color("#c08040"),
		Color("#40a0c0"), Color("#c04060"), Color("#80c040"),
	]
	for shelf_idx in range(3):
		var shelf_y2: float = [viewport.y * 0.16, viewport.y * 0.42, viewport.y * 0.68][shelf_idx]
		for j in range(6):
			var bx: float = viewport.x * (0.08 + 0.16 * float(j))
			var by: float = shelf_y2 - 22
			var col: Color = bottle_colors[(shelf_idx * 6 + j) % bottle_colors.size()]
			var pulse: float = 0.5 + 0.5 * sin(t * 0.8 + float(shelf_idx * 6 + j) * 0.7)
			# Bottle silhouette
			ci.draw_rect(Rect2(bx - 6, by, 12, 18), Color("#1a1208"))
			ci.draw_rect(Rect2(bx - 3, by - 4, 6, 4), Color("#1a1208"))
			# Glow inside
			ci.draw_circle(Vector2(bx, by + 12), 6.5, Color(col.r, col.g, col.b, 0.55 + pulse * 0.25))
			# Outer glow halo
			ci.draw_circle(Vector2(bx, by + 12), 14, Color(col.r, col.g, col.b, 0.08 + pulse * 0.06))

	# Candles between bottles — flickering yellow glow
	for cand_idx in range(4):
		var cx: float = viewport.x * (0.18 + 0.22 * float(cand_idx))
		var cy: float = viewport.y * 0.30
		var flicker: float = 0.7 + 0.3 * sin(t * 5.0 + float(cand_idx) * 1.3)
		ci.draw_circle(Vector2(cx, cy), 18 * flicker, Color(1.0, 0.75, 0.35, 0.12 * flicker))
		ci.draw_circle(Vector2(cx, cy), 8 * flicker, Color(1.0, 0.85, 0.50, 0.30 * flicker))
		ci.draw_circle(Vector2(cx, cy), 3, Color(1.0, 0.95, 0.70, 0.9))

# --- Sci-Fi theme: deep nebula, glowing floor strips, console panels ---
static func _draw_scifi_bg(ci: CanvasItem, viewport: Vector2, t: float) -> void:
	# Deep space gradient
	var top := Color("#0a0a1a")
	var mid := Color("#16203a")
	var bot := Color("#040814")
	var bands := 28
	for i in range(bands):
		var pos: float = float(i) / float(bands - 1)
		var col: Color
		if pos < 0.5:
			col = top.lerp(mid, pos * 2.0)
		else:
			col = mid.lerp(bot, (pos - 0.5) * 2.0)
		var y: float = viewport.y * float(i) / float(bands)
		var h: float = viewport.y / float(bands) + 1.0
		ci.draw_rect(Rect2(Vector2(0, y), Vector2(viewport.x, h)), col)

	# Nebula clouds (3 large soft circles, slowly drifting)
	var nebula_a := Vector2(viewport.x * (0.30 + 0.05 * sin(t * 0.05)), viewport.y * 0.18)
	_draw_soft_glow(ci, nebula_a, viewport.x * 0.55, Color(0.50, 0.30, 0.70, 0.10))
	var nebula_b := Vector2(viewport.x * (0.70 + 0.05 * cos(t * 0.04)), viewport.y * 0.22)
	_draw_soft_glow(ci, nebula_b, viewport.x * 0.50, Color(0.30, 0.55, 0.80, 0.09))
	var nebula_c := Vector2(viewport.x * (0.50 + 0.06 * sin(t * 0.06 + 1.5)), viewport.y * 0.08)
	_draw_soft_glow(ci, nebula_c, viewport.x * 0.40, Color(0.80, 0.30, 0.50, 0.08))

	# Twinkling star particles
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for _i in range(70):
		var sx: float = rng.randf() * viewport.x
		var sy: float = rng.randf() * viewport.y * 0.6
		var sr: float = rng.randf_range(0.5, 1.4)
		var twinkle: float = 0.5 + 0.5 * sin(t * 1.5 + rng.randf() * TAU)
		ci.draw_circle(Vector2(sx, sy), sr, Color(1, 1, 1, 0.25 + 0.35 * twinkle))

	# Glowing floor strips (perspective effect — diagonal lines toward bottom)
	var floor_y: float = viewport.y * 0.78
	for strip_i in range(5):
		var x_top: float = viewport.x * (0.15 + 0.175 * float(strip_i))
		var x_bot: float = viewport.x * (-0.05 + 0.275 * float(strip_i))
		var pulse: float = 0.6 + 0.4 * sin(t * 1.2 + float(strip_i) * 0.5)
		ci.draw_line(Vector2(x_top, floor_y), Vector2(x_bot, viewport.y),
			Color(0.30, 0.85, 1.0, 0.20 + 0.15 * pulse), 2.0)
		ci.draw_line(Vector2(x_top, floor_y), Vector2(x_bot, viewport.y),
			Color(0.30, 0.85, 1.0, 0.08), 5.0)  # soft outer glow

	# Top console-screen panels (small dark rects with glowing dots)
	for panel_i in range(4):
		var px: float = viewport.x * (0.10 + 0.22 * float(panel_i))
		var py: float = viewport.y * 0.06
		ci.draw_rect(Rect2(px, py, 56, 18), Color("#0a1428"))
		ci.draw_rect(Rect2(px, py, 56, 18), Color("#2a4870"), false)
		# Screen content — colored dot
		var dot_palette: Array = [Color("#3acfff"), Color("#9affb0"), Color("#ff6a8a"), Color("#ffd066")]
		var dot_color: Color = dot_palette[panel_i % 4]
		var dot_pulse: float = 0.5 + 0.5 * sin(t * 2.0 + float(panel_i))
		ci.draw_circle(Vector2(px + 10 + (panel_i % 3) * 14, py + 9), 2.5,
			Color(dot_color.r, dot_color.g, dot_color.b, 0.6 + 0.4 * dot_pulse))

# --- Mystical Forest theme: deep green gradient, fireflies, glowing mushrooms ---
static func _draw_forest_bg(ci: CanvasItem, viewport: Vector2, t: float) -> void:
	# Deep forest gradient — emerald → black
	var top := Color("#15302a")
	var mid := Color("#0c2018")
	var bot := Color("#040c08")
	var bands := 28
	for i in range(bands):
		var pos: float = float(i) / float(bands - 1)
		var col: Color
		if pos < 0.5:
			col = top.lerp(mid, pos * 2.0)
		else:
			col = mid.lerp(bot, (pos - 0.5) * 2.0)
		var y: float = viewport.y * float(i) / float(bands)
		var h: float = viewport.y / float(bands) + 1.0
		ci.draw_rect(Rect2(Vector2(0, y), Vector2(viewport.x, h)), col)

	# Tree silhouettes on edges (darker vertical bands)
	var tree_col := Color("#050a08")
	# Left tree
	ci.draw_rect(Rect2(0, 0, viewport.x * 0.08, viewport.y), tree_col)
	for tree_y in range(0, int(viewport.y), 60):
		ci.draw_circle(Vector2(viewport.x * 0.06, float(tree_y) + 30), 22, tree_col)
	# Right tree
	ci.draw_rect(Rect2(viewport.x * 0.92, 0, viewport.x * 0.08, viewport.y), tree_col)
	for tree_y2 in range(0, int(viewport.y), 70):
		ci.draw_circle(Vector2(viewport.x * 0.94, float(tree_y2) + 35), 22, tree_col)

	# Soft mist bands
	for mist_i in range(4):
		var my: float = viewport.y * (0.20 + 0.18 * float(mist_i))
		var sway: float = sin(t * 0.3 + float(mist_i)) * 20.0
		ci.draw_rect(Rect2(Vector2(-50 + sway, my), Vector2(viewport.x + 100, 40)),
			Color(0.5, 0.8, 0.7, 0.04))

	# Fireflies — small glowing dots drifting around
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for i in range(22):
		var base_x: float = rng.randf() * viewport.x
		var base_y: float = rng.randf() * viewport.y * 0.85
		var drift_x: float = sin(t * 0.6 + rng.randf() * TAU) * 30.0
		var drift_y: float = cos(t * 0.4 + rng.randf() * TAU) * 25.0
		var pulse: float = 0.4 + 0.6 * sin(t * 2.0 + rng.randf() * TAU)
		var fx: float = base_x + drift_x
		var fy: float = base_y + drift_y
		# Cyan/green firefly
		var hue_sel: int = rng.randi() % 3
		var col: Color = [Color(0.5, 1.0, 0.7, 1.0), Color(0.3, 0.9, 1.0, 1.0), Color(0.9, 1.0, 0.4, 1.0)][hue_sel]
		# Outer glow
		ci.draw_circle(Vector2(fx, fy), 8.0, Color(col.r, col.g, col.b, 0.10 * pulse))
		ci.draw_circle(Vector2(fx, fy), 4.0, Color(col.r, col.g, col.b, 0.30 * pulse))
		ci.draw_circle(Vector2(fx, fy), 1.5, Color(col.r, col.g, col.b, 0.95 * pulse))

	# Glowing mushrooms along the bottom — cyan circles
	for m_idx in range(6):
		var mx: float = viewport.x * (0.10 + 0.15 * float(m_idx)) + sin(float(m_idx) * 1.7) * 10
		var my2: float = viewport.y * 0.92 + sin(float(m_idx)) * 5
		var pulse2: float = 0.6 + 0.4 * sin(t * 1.5 + float(m_idx))
		ci.draw_circle(Vector2(mx, my2), 14.0, Color(0.4, 1.0, 0.9, 0.10 * pulse2))
		ci.draw_circle(Vector2(mx, my2), 7.0, Color(0.5, 1.0, 0.95, 0.30 * pulse2))
		ci.draw_circle(Vector2(mx, my2), 3.0, Color(0.8, 1.0, 1.0, 0.85 * pulse2))

	# Bottom moss/ground
	ci.draw_rect(Rect2(0, viewport.y - 28, viewport.x, 28), Color("#0a1810"))

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
