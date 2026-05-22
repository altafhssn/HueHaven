extends Control

# Main menu — title, play, settings, stats.

const StyleScript = preload("res://scripts/Style.gd")
const ProgressionScript = preload("res://scripts/Progression.gd")
const LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
const BallColorsScript = preload("res://scripts/BallColors.gd")

var main_ref = null
var progression = null

var time_t: float = 0.0

func _ready():
	progression = ProgressionScript.new()
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	size = viewport
	mouse_filter = Control.MOUSE_FILTER_PASS

	# Play button
	var play_btn := Button.new()
	play_btn.text = "  Play  "
	play_btn.add_theme_font_size_override("font_size", 22)
	StyleScript.style_button(play_btn, true)
	play_btn.size = Vector2(220, 56)
	play_btn.position = Vector2((viewport.x - 220) / 2, viewport.y * 0.52)
	play_btn.pressed.connect(_on_play)
	play_btn.focus_mode = Control.FOCUS_NONE
	add_child(play_btn)

	# Settings button
	var settings_btn := Button.new()
	settings_btn.text = "Settings"
	settings_btn.add_theme_font_size_override("font_size", 16)
	StyleScript.style_button(settings_btn, false)
	settings_btn.size = Vector2(160, 42)
	settings_btn.position = Vector2((viewport.x - 160) / 2, viewport.y * 0.52 + 76)
	settings_btn.pressed.connect(_on_settings)
	settings_btn.focus_mode = Control.FOCUS_NONE
	add_child(settings_btn)

	# Stats text
	var total_stars: int = 0
	var unlocked: int = progression.get_highest_unlocked()
	for i in range(unlocked + 1):
		total_stars += progression.get_stars(i)
	var stats_lbl := StyleScript.make_label(
		"★ " + str(total_stars) + "    •    Lvl " + str(unlocked + 1) + " / " + str(LevelGeneratorScript.get_total_levels()),
		13, StyleScript.TEXT_MUTED,
		Vector2(0, viewport.y * 0.52 + 130), Vector2(viewport.x, 24))
	add_child(stats_lbl)

	set_process(true)

func _process(delta):
	time_t += delta
	queue_redraw()

func _draw():
	var viewport = get_viewport().get_visible_rect().size
	StyleScript.draw_background(self, viewport)
	StyleScript.draw_stars(self, viewport)

	# Decorative tubes at the top — three sample tubes with sample balls
	_draw_hero_tubes(viewport)

	# Title
	_draw_title(viewport)

	# Subtitle
	var font := ThemeDB.fallback_font
	var subtitle := "a serene sorting puzzle"
	var st_size := font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	draw_string(font, Vector2(viewport.x * 0.5 - st_size.x * 0.5, viewport.y * 0.36),
		subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, StyleScript.TEXT_MUTED)

func _draw_title(viewport: Vector2):
	var font := ThemeDB.fallback_font
	var title := "Ball Sort"
	var size_a := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 48)
	var x := viewport.x * 0.5 - size_a.x * 0.5
	var y := viewport.y * 0.28
	# Soft glow underneath
	draw_string_outline(font, Vector2(x, y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 48, 6, StyleScript.ACCENT_GLOW)
	draw_string(font, Vector2(x, y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 48, StyleScript.ACCENT)

func _draw_hero_tubes(viewport: Vector2):
	# Three sample tubes with sample stacks — drift gently
	var tube_w: float = 44.0
	var tube_h: float = 130.0
	var gap: float = 18.0
	var n: int = 3
	var total: float = float(n) * tube_w + float(n - 1) * gap
	var start_x: float = viewport.x * 0.5 - total * 0.5
	var top: float = viewport.y * 0.08
	var samples = [
		[0, 0, 1, 2],   # mixed
		[1, 1, 1, 0],   # mostly sorted
		[2, 0, 1, 2],   # mixed
	]
	var ball_r := 14.0
	for i in range(n):
		var sway := sin(time_t * 0.8 + i * 0.7) * 2.0
		var x := start_x + i * (tube_w + gap)
		var rect := Rect2(x, top + sway, tube_w, tube_h)
		_draw_tube_shape(rect, ball_r, samples[i])

func _draw_tube_shape(rect: Rect2, ball_r: float, balls: Array):
	# Tube background gradient
	StyleScript.draw_gradient_rect(self, rect, StyleScript.TUBE_BG_HI, StyleScript.TUBE_BG, 10.0)
	# Border
	StyleScript.draw_rounded_rect(self, rect, StyleScript.TUBE_BORDER, 10.0, false, 1.5)
	# Inner top highlight
	var hi_rect := Rect2(rect.position + Vector2(2, 2), Vector2(rect.size.x - 4, 4))
	draw_rect(hi_rect, Color(1, 1, 1, 0.06))
	# Balls bottom-up
	for j in range(balls.size()):
		var color: Color = BallColorsScript.get_color(balls[j])
		var cx: float = rect.position.x + rect.size.x * 0.5
		var cy: float = rect.position.y + rect.size.y - (j + 0.5) * (ball_r * 2 + 1)
		draw_circle(Vector2(cx + 2, cy + 2), ball_r, Color(0, 0, 0, 0.3))
		draw_circle(Vector2(cx, cy), ball_r, color)
		draw_circle(Vector2(cx - ball_r * 0.3, cy - ball_r * 0.3), ball_r * 0.35, Color(1, 1, 1, 0.28))

func _on_play():
	if main_ref:
		main_ref.show_level_select()

func _on_settings():
	if main_ref:
		main_ref.show_settings()
