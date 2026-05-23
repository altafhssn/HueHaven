extends Control

# Full-screen settings page.

const StyleScript = preload("res://scripts/Style.gd")
const ProgressionScript = preload("res://scripts/Progression.gd")
const IconScript = preload("res://scripts/Icon.gd")

var main_ref = null
var progression = null
var cb_btn = null
var mute_btn = null
var haptic_btn = null
var reset_btn = null

func _ready():
	progression = ProgressionScript.new()
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	size = viewport
	mouse_filter = Control.MOUSE_FILTER_PASS

	# Back button (top-left) — geometric icon
	var back := Button.new()
	back.text = ""
	back.size = Vector2(44, 44)
	back.position = Vector2(16, 16)
	StyleScript.style_button(back, false)
	back.pressed.connect(_on_back)
	back.focus_mode = Control.FOCUS_NONE
	var back_glyph := Control.new()
	back_glyph.size = back.size
	back_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_glyph.draw.connect(func():
		IconScript.draw(back_glyph, "back", back_glyph.size * 0.5, back_glyph.size.x, StyleScript.TEXT)
	)
	back.add_child(back_glyph)
	add_child(back)

	# Title
	add_child(StyleScript.make_label("Settings", 28, StyleScript.ACCENT,
		Vector2(0, 40), Vector2(viewport.x, 40)))

	# Group label "Game"
	add_child(StyleScript.make_label("GAME", 11, StyleScript.TEXT_DIM,
		Vector2(24, viewport.y * 0.20), Vector2(viewport.x - 48, 18),
		HORIZONTAL_ALIGNMENT_LEFT))

	# Colorblind toggle row
	cb_btn = _make_row("Colorblind shapes", _on_toggle_cb,
		Vector2(24, viewport.y * 0.20 + 24), viewport.x - 48)
	add_child(cb_btn)

	# Mute toggle row
	mute_btn = _make_row("Sound", _on_toggle_mute,
		Vector2(24, viewport.y * 0.20 + 84), viewport.x - 48)
	add_child(mute_btn)

	# Haptics toggle row
	haptic_btn = _make_row("Haptics", _on_toggle_haptics,
		Vector2(24, viewport.y * 0.20 + 144), viewport.x - 48)
	add_child(haptic_btn)

	# Group label "Data"
	add_child(StyleScript.make_label("DATA", 11, StyleScript.TEXT_DIM,
		Vector2(24, viewport.y * 0.20 + 230), Vector2(viewport.x - 48, 18),
		HORIZONTAL_ALIGNMENT_LEFT))

	# Reset progress button
	reset_btn = Button.new()
	reset_btn.text = "Reset progress"
	reset_btn.add_theme_font_size_override("font_size", 14)
	StyleScript.style_button(reset_btn, false)
	reset_btn.add_theme_color_override("font_color", StyleScript.DANGER)
	reset_btn.size = Vector2(viewport.x - 48, 48)
	reset_btn.position = Vector2(24, viewport.y * 0.20 + 254)
	reset_btn.pressed.connect(_on_reset)
	reset_btn.focus_mode = Control.FOCUS_NONE
	add_child(reset_btn)

	# Version footer
	add_child(StyleScript.make_label("v0.2 — HueHaven", 11, StyleScript.TEXT_DIM,
		Vector2(0, viewport.y - 30), Vector2(viewport.x, 20)))

	_refresh()

func _make_row(label_text: String, callback: Callable, pos: Vector2, w: float) -> Button:
	# A row-shaped button that shows "Label    [ON/OFF]"
	var b := Button.new()
	b.add_theme_font_size_override("font_size", 14)
	StyleScript.style_button(b, false)
	b.size = Vector2(w, 48)
	b.position = pos
	b.pressed.connect(callback)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.text = label_text
	b.focus_mode = Control.FOCUS_NONE
	return b

func _refresh():
	var colorblind_on: bool = progression.is_colorblind()
	var sound_on: bool = not progression.is_muted()
	var haptics_on: bool = progression.is_haptics_enabled()
	if main_ref:
		colorblind_on = main_ref.is_colorblind()
		sound_on = not main_ref.is_muted()
		haptics_on = main_ref.is_haptics_enabled()
	cb_btn.text = "  Colorblind shapes" + _suffix(colorblind_on)
	mute_btn.text = "  Sound" + _suffix(sound_on)
	haptic_btn.text = "  Haptics" + _suffix(haptics_on)

func _suffix(on: bool) -> String:
	return "                                   ON " if on else "                                   OFF"

func _on_toggle_cb():
	if main_ref:
		main_ref.toggle_colorblind()
	_refresh()

func _on_toggle_mute():
	if main_ref:
		main_ref.toggle_mute()
	_refresh()

func _on_toggle_haptics():
	if main_ref:
		main_ref.toggle_haptics()
	_refresh()

func _on_reset():
	if main_ref and main_ref.progression:
		main_ref.progression.reset_all()
	if progression:
		progression.load_save()
	_refresh()

func _on_back():
	if main_ref:
		main_ref.show_main_menu()

func _process(_delta):
	queue_redraw()

func _draw():
	var viewport = get_viewport().get_visible_rect().size
	StyleScript.draw_themed_background(self, viewport, Time.get_ticks_msec() / 1000.0,
		StyleScript.THEME_UNDERWATER)
