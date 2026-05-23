extends Control

# Main menu — title, play, settings, stats. Uses the unified themed
# background + glass-bubble ball rendering for visual consistency.

const StyleScript = preload("res://scripts/Style.gd")
const ProgressionScript = preload("res://scripts/Progression.gd")
const LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
const BallColorsScript = preload("res://scripts/BallColors.gd")
const IconScript = preload("res://scripts/Icon.gd")

var main_ref = null
var progression = null

var time_t: float = 0.0

func _ready():
	progression = ProgressionScript.new()
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	size = viewport
	mouse_filter = Control.MOUSE_FILTER_PASS

	# Play button — primary, icon properly aligned with centered text
	var play_btn := _make_icon_button("Play", "play", 19, Color("#1a1208"), true)
	play_btn.size = Vector2(240, 60)
	play_btn.position = Vector2((viewport.x - 240) / 2, viewport.y * 0.58)
	play_btn.pressed.connect(_on_play)
	add_child(play_btn)

	# Settings button — secondary
	var settings_btn := _make_icon_button("Settings", "settings", 16, StyleScript.TEXT, false)
	settings_btn.size = Vector2(180, 48)
	settings_btn.position = Vector2((viewport.x - 180) / 2, viewport.y * 0.58 + 76)
	settings_btn.pressed.connect(_on_settings)
	add_child(settings_btn)

	# Stats text — total stars / level progress
	var total_stars: int = 0
	var unlocked: int = progression.get_highest_unlocked()
	for i in range(unlocked + 1):
		total_stars += progression.get_stars(i)
	var stats_text := str(total_stars) + " stars   ·   Level " + str(unlocked + 1) + " of " + str(LevelGeneratorScript.get_total_levels())
	var stats_lbl := StyleScript.make_label(
		stats_text, 14, StyleScript.TEXT_MUTED,
		Vector2(0, viewport.y * 0.58 + 142), Vector2(viewport.x, 22))
	add_child(stats_lbl)

	set_process(true)

# Builds a button where the (icon + text) group is centered as one unit.
func _make_icon_button(label_text: String, icon_name: String, font_size: int, icon_color: Color, primary: bool) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", font_size)
	StyleScript.style_button(btn, primary)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT   # text anchored left; we shift via padding
	btn.focus_mode = Control.FOCUS_NONE

	var icon_size: int = max(20, font_size + 4)
	var gap: float = 10.0

	var icon_ctl := Control.new()
	icon_ctl.size = Vector2(icon_size, icon_size)
	icon_ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_ctl.set_meta("ic_name", icon_name)
	icon_ctl.set_meta("ic_color", icon_color)
	icon_ctl.set_meta("ic_size", icon_size)
	icon_ctl.draw.connect(func():
		IconScript.draw(icon_ctl, icon_ctl.get_meta("ic_name"),
			icon_ctl.size * 0.5, icon_ctl.get_meta("ic_size"), icon_ctl.get_meta("ic_color"))
	)
	btn.add_child(icon_ctl)

	var layout = func():
		var font := ThemeDB.fallback_font
		var text_w: float = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var group_w: float = float(icon_size) + gap + text_w
		var group_x: float = (btn.size.x - group_w) * 0.5
		icon_ctl.position = Vector2(group_x, (btn.size.y - float(icon_size)) * 0.5)
		# Push the text so it sits right after the icon+gap
		for state in ["normal", "hover", "pressed", "disabled"]:
			var sb: StyleBoxFlat = btn.get_theme_stylebox(state)
			if sb:
				sb.content_margin_left = group_x + float(icon_size) + gap
				sb.content_margin_right = group_x  # mirror so visuals stay balanced
	btn.resized.connect(layout)
	layout.call()
	return btn

func _process(delta):
	time_t += delta
	queue_redraw()

func _draw():
	var viewport = get_viewport().get_visible_rect().size
	# Unified themed background — uses underwater for the menu
	StyleScript.draw_themed_background(self, viewport, time_t, StyleScript.THEME_UNDERWATER)

	# Logo + title
	_draw_logo(viewport)
	_draw_title(viewport)

	# Subtitle
	var font := ThemeDB.fallback_font
	var subtitle := "A serene sorting puzzle"
	var sub_size: int = 14
	var st_size := font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size)
	draw_string(font, Vector2(viewport.x * 0.5 - st_size.x * 0.5, viewport.y * 0.48),
		subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size, StyleScript.TEXT_MUTED)

# Logo mark — apothecary test tube with four stacked glass balls inside,
# warm rim glow inside a dark rounded squircle. Game-referenced.
func _draw_logo(viewport: Vector2):
	var cx: float = viewport.x * 0.5
	var cy: float = viewport.y * 0.22
	var icon_size: float = 170.0
	var icon_r: float = icon_size * 0.22  # iOS squircle-ish corner

	# ----- (1) Drop shadow + icon container -----
	for k in range(4):
		var sh_rect := Rect2(
			cx - icon_size * 0.5 - float(k),
			cy - icon_size * 0.5 + float(k) * 2.0,
			icon_size + float(k) * 2.0,
			icon_size + float(k) * 2.0)
		StyleScript.draw_rounded_rect(self, sh_rect, Color(0, 0, 0, 0.10), icon_r + float(k), true)
	var icon_rect := Rect2(cx - icon_size * 0.5, cy - icon_size * 0.5, icon_size, icon_size)
	StyleScript.draw_rounded_rect(self, icon_rect, Color("#1A2238"), icon_r, true)
	StyleScript.draw_gradient_rect(self, icon_rect, Color("#22304A"), Color("#0E1828"), icon_r)

	# ----- (2) Cool cyan rim glow (contained) -----
	var glow_tint := Color(0.45, 0.78, 0.95)  # soft cyan
	var top_glow := Rect2(icon_rect.position.x, icon_rect.position.y, icon_size, icon_size * 0.50)
	StyleScript.draw_gradient_rect(self, top_glow,
		Color(glow_tint.r, glow_tint.g, glow_tint.b, 0.16),
		Color(glow_tint.r, glow_tint.g, glow_tint.b, 0.0),
		icon_r)
	var bot_glow := Rect2(icon_rect.position.x, cy + icon_size * 0.05, icon_size, icon_size * 0.45)
	StyleScript.draw_gradient_rect(self, bot_glow,
		Color(glow_tint.r, glow_tint.g, glow_tint.b, 0.0),
		Color(glow_tint.r, glow_tint.g, glow_tint.b, 0.12),
		icon_r)

	# ----- (3) Test tube — capsule-shaped glass vial centered in the icon -----
	var tube_w: float = icon_size * 0.38
	var tube_h: float = icon_size * 0.80
	var tube_x: float = cx - tube_w * 0.5
	var tube_y: float = cy - tube_h * 0.5
	var tube_rect := Rect2(tube_x, tube_y, tube_w, tube_h)
	var tube_corner_r: float = tube_w * 0.50   # full-radius => capsule shape

	# Tube backdrop tint (slight cool wash so the glass reads)
	StyleScript.draw_rounded_rect(self, tube_rect, Color(0.55, 0.78, 0.95, 0.06), tube_corner_r, true)
	# Tube body gradient (translucent, brighter at top)
	StyleScript.draw_gradient_rect(self, tube_rect,
		Color(0.65, 0.85, 0.98, 0.14),
		Color(0.35, 0.55, 0.75, 0.08),
		tube_corner_r)
	# Tube outer rim — thin cool cyan border
	StyleScript.draw_rounded_rect(self, tube_rect,
		Color(0.55, 0.80, 0.95, 0.55),
		tube_corner_r, false, 1.6)
	# Left edge vertical highlight (light catching the glass)
	draw_rect(Rect2(tube_x + 3, tube_y + tube_corner_r * 0.5, 2, tube_h - tube_corner_r), Color(1, 1, 1, 0.22))

	# ----- (4) Three stacked color balls inside the tube -----
	# Sized + spaced so they sit comfortably without touching the tube ends.
	var ball_r: float = tube_w * 0.32
	var inner_pad: float = ball_r * 0.4 + 2.0
	var top_y: float = tube_y + inner_pad + ball_r
	var bot_y: float = tube_y + tube_h - inner_pad - ball_r
	var step_y: float = (bot_y - top_y) / 2.0
	var ball_colors := [
		Color("#9E7CB8"),  # soft lavender (top)
		Color("#5DA8C4"),  # cool teal (middle)
		Color("#7DBE82"),  # sage green (bottom)
	]
	for i in range(ball_colors.size()):
		var by: float = top_y + float(i) * step_y
		_draw_logo_ball(Vector2(cx, by), ball_r, ball_colors[i])

	# ----- (5) Subtle cool border around the whole icon -----
	StyleScript.draw_rounded_rect(self, icon_rect,
		Color(0.55, 0.80, 0.95, 0.22),
		icon_r, false, 1.5)

func _draw_logo_ball(center: Vector2, r: float, color: Color) -> void:
	# Translucent body — colors mix visually where they overlap
	var edge_col := color.darkened(0.40)
	edge_col.a = 0.75
	draw_circle(center, r + 0.5, edge_col)
	var body := color
	body.a = 0.80
	draw_circle(center, r, body)
	var core := color.lightened(0.20)
	core.a = 0.45
	draw_circle(center + Vector2(0, r * 0.06), r * 0.78, core)
	# Top-left highlight
	var hl := center + Vector2(-r * 0.32, -r * 0.36)
	draw_circle(hl, r * 0.48, Color(1, 1, 1, 0.10))
	draw_circle(hl, r * 0.32, Color(1, 1, 1, 0.30))
	draw_circle(hl, r * 0.18, Color(1, 1, 1, 0.55))
	draw_circle(hl, r * 0.08, Color(1, 1, 1, 0.85))

func _draw_title(viewport: Vector2):
	var font := ThemeDB.fallback_font
	# "Hue" + "Haven" — two-tone wordmark
	var hue := "Hue"
	var haven := "Haven"
	var title_size := 46
	var hue_w: Vector2 = font.get_string_size(hue, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size)
	var haven_w: Vector2 = font.get_string_size(haven, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size)
	var total_w: float = hue_w.x + haven_w.x
	var x0: float = viewport.x * 0.5 - total_w * 0.5
	var y: float = viewport.y * 0.42
	# Soft glow underneath the whole title
	draw_string_outline(font, Vector2(x0, y), hue, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, 8,
		Color(StyleScript.ACCENT.r, StyleScript.ACCENT.g, StyleScript.ACCENT.b, 0.25))
	draw_string_outline(font, Vector2(x0 + hue_w.x, y), haven, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, 8,
		Color(StyleScript.ACCENT.r, StyleScript.ACCENT.g, StyleScript.ACCENT.b, 0.25))
	# "Hue" in cream — the wordmark's calm half
	draw_string(font, Vector2(x0, y), hue, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, StyleScript.TEXT)
	# "Haven" in accent — the wordmark's warm half
	draw_string(font, Vector2(x0 + hue_w.x, y), haven, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, StyleScript.ACCENT)

func _draw_hero_tubes(viewport: Vector2):
	# Three sample tubes with sample stacks — drift gently
	var tube_w: float = 54.0
	var tube_h: float = 170.0
	var gap: float = 14.0
	var n: int = 3
	var total: float = float(n) * tube_w + float(n - 1) * gap
	var start_x: float = viewport.x * 0.5 - total * 0.5
	var top: float = viewport.y * 0.07
	var samples = [
		[0, 0, 1, 2],
		[1, 1, 2, 0],
		[2, 0, 1, 2],
	]
	var ball_r: float = 18.0
	for i in range(n):
		var sway := sin(time_t * 0.8 + i * 0.7) * 2.0
		var x := start_x + i * (tube_w + gap)
		var rect := Rect2(x, top + sway, tube_w, tube_h)
		_draw_tube_shape(rect, ball_r, samples[i])

func _draw_tube_shape(rect: Rect2, ball_r: float, balls: Array):
	# Glass vial body
	var glass_top := Color(0.55, 0.78, 0.92, 0.18)
	var glass_bot := Color(0.30, 0.50, 0.70, 0.10)
	StyleScript.draw_gradient_rect(self, rect, glass_top, glass_bot, 16.0)
	StyleScript.draw_rounded_rect(self, rect, Color(0.50, 0.72, 0.88, 0.55), 16.0, false, 1.5)
	# Balls bottom-up
	for j in range(balls.size()):
		var color: Color = BallColorsScript.get_color(balls[j])
		var cx: float = rect.position.x + rect.size.x * 0.5
		var cy: float = rect.position.y + rect.size.y - (j + 0.5) * (ball_r * 2 + 1)
		_draw_glass_ball(Vector2(cx, cy), ball_r, color)

func _draw_glass_ball(center: Vector2, r: float, color: Color):
	# Matches the in-game glass-bubble look (compact version)
	draw_circle(center + Vector2(1, r * 0.22), r * 1.0, Color(0, 0, 0, 0.20))
	var edge_col := color.darkened(0.45)
	edge_col.a = 0.85
	draw_circle(center, r + 0.5, edge_col)
	var body_col := color
	body_col.a = 0.78
	draw_circle(center, r - 0.5, body_col)
	var core_col := color.lightened(0.10)
	core_col.a = 0.55
	draw_circle(center + Vector2(0, r * 0.05), r * 0.80, core_col)
	draw_circle(center + Vector2(0, r * 0.45), r * 0.55, Color(1, 1, 1, 0.18))
	var hl := center + Vector2(-r * 0.28, -r * 0.38)
	draw_circle(hl, r * 0.48, Color(1, 1, 1, 0.20))
	draw_circle(hl, r * 0.36, Color(1, 1, 1, 0.36))
	draw_circle(hl, r * 0.22, Color(1, 1, 1, 0.62))
	draw_circle(hl, r * 0.12, Color(1, 1, 1, 0.85))

func _on_play():
	if main_ref:
		main_ref.show_level_select()

func _on_settings():
	if main_ref:
		main_ref.show_settings()
