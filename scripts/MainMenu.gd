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

	# Play button (primary, with play-icon)
	var play_btn := Button.new()
	play_btn.text = "    Play"
	play_btn.add_theme_font_size_override("font_size", 22)
	StyleScript.style_button(play_btn, true)
	play_btn.size = Vector2(240, 60)
	play_btn.position = Vector2((viewport.x - 240) / 2, viewport.y * 0.58)
	play_btn.pressed.connect(_on_play)
	play_btn.focus_mode = Control.FOCUS_NONE
	var play_icon := Control.new()
	play_icon.position = Vector2(16, (60 - 26) * 0.5)
	play_icon.size = Vector2(26, 26)
	play_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_icon.draw.connect(func():
		IconScript.draw(play_icon, "play", play_icon.size * 0.5, 26, Color("#1a1208"))
	)
	play_btn.add_child(play_icon)
	add_child(play_btn)

	# Settings button (secondary)
	var settings_btn := Button.new()
	settings_btn.text = "    Settings"
	settings_btn.add_theme_font_size_override("font_size", 16)
	StyleScript.style_button(settings_btn, false)
	settings_btn.size = Vector2(180, 46)
	settings_btn.position = Vector2((viewport.x - 180) / 2, viewport.y * 0.58 + 80)
	settings_btn.pressed.connect(_on_settings)
	settings_btn.focus_mode = Control.FOCUS_NONE
	var set_icon := Control.new()
	set_icon.position = Vector2(14, (46 - 22) * 0.5)
	set_icon.size = Vector2(22, 22)
	set_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_icon.draw.connect(func():
		IconScript.draw(set_icon, "settings", set_icon.size * 0.5, 22, StyleScript.TEXT)
	)
	settings_btn.add_child(set_icon)
	add_child(settings_btn)

	# Stats text — total stars / level progress
	var total_stars: int = 0
	var unlocked: int = progression.get_highest_unlocked()
	for i in range(unlocked + 1):
		total_stars += progression.get_stars(i)
	var stats_text := str(total_stars) + " stars  ·  Level " + str(unlocked + 1) + " of " + str(LevelGeneratorScript.get_total_levels())
	var stats_lbl := StyleScript.make_label(
		stats_text, 13, StyleScript.TEXT_MUTED,
		Vector2(0, viewport.y * 0.58 + 144), Vector2(viewport.x, 24))
	add_child(stats_lbl)

	set_process(true)

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
	var subtitle := "a serene sorting puzzle"
	var st_size := font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	draw_string(font, Vector2(viewport.x * 0.5 - st_size.x * 0.5, viewport.y * 0.46),
		subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, StyleScript.TEXT_MUTED)

# Logo mark — three overlapping translucent color circles forming a triangle.
# Represents color (hue) blending into harmony (haven).
func _draw_logo(viewport: Vector2):
	var cx: float = viewport.x * 0.5
	var cy: float = viewport.y * 0.22
	var r: float = 38.0
	var sep: float = r * 0.65  # how far each circle is from the center

	# Soft backplate glow
	draw_circle(Vector2(cx, cy), r * 2.4, Color(StyleScript.ACCENT.r, StyleScript.ACCENT.g, StyleScript.ACCENT.b, 0.07))
	draw_circle(Vector2(cx, cy), r * 1.7, Color(StyleScript.ACCENT.r, StyleScript.ACCENT.g, StyleScript.ACCENT.b, 0.06))

	# Three circles at 120° apart (top, bottom-left, bottom-right)
	var positions := [
		Vector2(cx, cy - sep),                              # top
		Vector2(cx - sep * 0.866, cy + sep * 0.5),          # bottom-left
		Vector2(cx + sep * 0.866, cy + sep * 0.5),          # bottom-right
	]
	var colors := [
		Color("#ff8c5a"),  # warm orange (terracotta)
		Color("#4f9fc8"),  # cool blue
		Color("#7ac085"),  # soft green
	]
	# Animated tiny pulse — barely-there breathing
	var pulse: float = 1.0 + 0.02 * sin(time_t * 1.0)

	# Draw each circle in additive-style blending: outer halo, then body, then inner highlight
	for i in range(3):
		var c: Color = colors[i]
		var p: Vector2 = positions[i]
		var rr: float = r * pulse
		# Outer halo
		draw_circle(p, rr * 1.15, Color(c.r, c.g, c.b, 0.18))
		# Body — translucent so where they overlap the colors mix visually
		draw_circle(p, rr, Color(c.r, c.g, c.b, 0.72))
		# Top highlight
		draw_circle(p + Vector2(-rr * 0.30, -rr * 0.32), rr * 0.32, Color(1, 1, 1, 0.35))
		draw_circle(p + Vector2(-rr * 0.30, -rr * 0.32), rr * 0.18, Color(1, 1, 1, 0.55))

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
	var y: float = viewport.y * 0.40
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
