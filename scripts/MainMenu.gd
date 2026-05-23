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
	draw_string(font, Vector2(viewport.x * 0.5 - st_size.x * 0.5, viewport.y * 0.48),
		subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, StyleScript.TEXT_MUTED)

# Logo mark — rounded icon container with a glass dome holding three
# translucent color spheres, ambient warm rim glow. iOS-icon proportions.
func _draw_logo(viewport: Vector2):
	var cx: float = viewport.x * 0.5
	var cy: float = viewport.y * 0.22
	var icon_size: float = 170.0
	var icon_r: float = icon_size * 0.22  # squircle-ish radius
	var pulse: float = 1.0 + 0.015 * sin(time_t * 1.0)

	# ----- (1) Icon container — rounded square with dark navy gradient -----
	# Outer soft shadow under the icon
	for k in range(4):
		var sh_rect := Rect2(
			cx - icon_size * 0.5 - float(k),
			cy - icon_size * 0.5 + float(k) * 2.0,
			icon_size + float(k) * 2.0,
			icon_size + float(k) * 2.0)
		StyleScript.draw_rounded_rect(self, sh_rect, Color(0, 0, 0, 0.10), icon_r + float(k), true)

	var icon_rect := Rect2(cx - icon_size * 0.5, cy - icon_size * 0.5, icon_size, icon_size)
	# Dark navy base
	StyleScript.draw_rounded_rect(self, icon_rect, Color("#1A2238"), icon_r, true)
	# Vertical gradient on top of the base for subtle depth
	StyleScript.draw_gradient_rect(self, icon_rect, Color("#22304A"), Color("#0E1828"), icon_r)

	# ----- (2) Warm ambient rim glow (orange light wrapping the inside edge) -----
	# Top rim
	for k in range(4):
		var glow_y: float = cy - icon_size * 0.45 + float(k) * 6.0
		var glow_alpha: float = 0.10 - float(k) * 0.02
		draw_circle(Vector2(cx, glow_y), icon_size * 0.45,
			Color(StyleScript.ACCENT.r, StyleScript.ACCENT.g, StyleScript.ACCENT.b, glow_alpha))
	# Bottom rim
	for k in range(4):
		var glow_y2: float = cy + icon_size * 0.45 - float(k) * 6.0
		var glow_alpha2: float = 0.08 - float(k) * 0.015
		draw_circle(Vector2(cx, glow_y2), icon_size * 0.45,
			Color(StyleScript.ACCENT.r, StyleScript.ACCENT.g, StyleScript.ACCENT.b, glow_alpha2))

	# ----- (3) Glass dome — large translucent sphere in the center -----
	var dome_r: float = icon_size * 0.40 * pulse
	var dome_center := Vector2(cx, cy)
	# Dome backdrop tint (very subtle warm wash inside)
	draw_circle(dome_center, dome_r * 1.05,
		Color(StyleScript.ACCENT.r, StyleScript.ACCENT.g, StyleScript.ACCENT.b, 0.08))
	# Dome body — barely visible translucent glass
	draw_circle(dome_center, dome_r, Color(1.0, 1.0, 1.0, 0.04))
	# Subtle outer ring (glass edge)
	for k in range(2):
		draw_arc(dome_center, dome_r - float(k), 0, TAU, 64,
			Color(1, 1, 1, 0.18 - float(k) * 0.08), 1.0)

	# ----- (4) Three overlapping color spheres inside the dome -----
	var ball_r: float = icon_size * 0.20
	var sep: float = ball_r * 0.55
	var positions := [
		Vector2(cx, cy - sep * 0.9),                          # top
		Vector2(cx - sep * 0.92, cy + sep * 0.55),            # bottom-left
		Vector2(cx + sep * 0.92, cy + sep * 0.55),            # bottom-right
	]
	var colors := [
		Color("#FF8C5A"),  # warm coral (top)
		Color("#7AB8C4"),  # pale teal (bottom-left)
		Color("#7DBE82"),  # sage green (bottom-right)
	]
	for i in range(3):
		_draw_logo_ball(positions[i], ball_r, colors[i])

	# ----- (5) Bright top-left highlight on the glass dome -----
	var hl_center := dome_center + Vector2(-dome_r * 0.45, -dome_r * 0.55)
	draw_circle(hl_center, dome_r * 0.30, Color(1, 1, 1, 0.10))
	draw_circle(hl_center, dome_r * 0.22, Color(1, 1, 1, 0.18))
	draw_circle(hl_center, dome_r * 0.14, Color(1, 1, 1, 0.28))
	draw_circle(hl_center, dome_r * 0.07, Color(1, 1, 1, 0.55))

	# ----- (6) Tiny bottom-right secondary highlight -----
	var hl2 := dome_center + Vector2(dome_r * 0.55, dome_r * 0.50)
	draw_circle(hl2, dome_r * 0.10, Color(1, 1, 1, 0.10))

	# ----- (7) Icon rounded-rect border (very subtle) -----
	StyleScript.draw_rounded_rect(self, icon_rect,
		Color(StyleScript.ACCENT.r, StyleScript.ACCENT.g, StyleScript.ACCENT.b, 0.18),
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
