extends CanvasLayer

# HUD — move counter, undo button, hint button, restart, win overlay

var main_ref = null

var move_label = null
var undo_button = null
var restart_button = null
var hint_button = null
var menu_button = null
var level_name_label = null

var win_overlay = null
var win_label = null
var stars_label = null
var next_button = null
var menu_from_win = null

var stuck_overlay = null
var stuck_label = null
var stuck_restart_button = null
var stuck_undo_button = null

var settings_overlay = null
var settings_open: bool = false
var settings_button = null
var cb_button = null
var mute_button = null
var close_settings_button = null

var ACCENT = Color("#e8d5a3")
var BG = Color("#0D0D1A")

func _ready():
	_setup_hud()

func _setup_hud():
	# Level name label
	level_name_label = Label.new()
	level_name_label.name = "LevelNameLabel"
	level_name_label.add_theme_font_size_override("font_size", 14)
	level_name_label.add_theme_color_override("font_color", Color("#e8d5a3"))
	level_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_name_label.position = Vector2(0, 110)
	level_name_label.size = Vector2(480, 24)
	add_child(level_name_label)
	
	# Move counter
	move_label = Label.new()
	move_label.text = "Moves: 0"
	move_label.add_theme_font_size_override("font_size", 14)
	move_label.add_theme_color_override("font_color", Color("#888888"))
	move_label.position = Vector2(16, 16)
	add_child(move_label)
	
	# Undo button
	undo_button = _make_button("↩ Undo", Vector2(16, 44), _on_undo)
	add_child(undo_button)
	
	# Restart button
	restart_button = _make_button("↻ Restart", Vector2(120, 44), _on_restart)
	add_child(restart_button)
	
	# Hint button (placeholder)
	hint_button = _make_button("? Hint", Vector2(240, 44), _on_hint)
	add_child(hint_button)
	
	# Menu button
	menu_button = _make_button("☰ Menu", Vector2(360, 44), _on_menu)
	add_child(menu_button)
	
	# Win overlay (hidden initially)
	win_overlay = ColorRect.new()
	win_overlay.color = Color(0, 0, 0, 0)
	win_overlay.size = get_viewport().get_visible_rect().size
	win_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_overlay.visible = false
	add_child(win_overlay)
	
	# Win title label
	win_label = Label.new()
	win_label.add_theme_font_size_override("font_size", 28)
	win_label.add_theme_color_override("font_color", ACCENT)
	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label.visible = false
	add_child(win_label)
	
	# Stars label
	stars_label = Label.new()
	stars_label.add_theme_font_size_override("font_size", 40)
	stars_label.add_theme_color_override("font_color", Color("#FFD700"))
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.visible = false
	add_child(stars_label)
	
	# Next level button
	next_button = _make_button("Next →", Vector2(180, 520), _on_next)
	next_button.visible = false
	add_child(next_button)
	
	# Menu from win button
	menu_from_win = _make_button("Level Select", Vector2(180, 560), _on_menu)
	menu_from_win.visible = false
	add_child(menu_from_win)

	# Settings button (gear)
	settings_button = _make_button("⚙", Vector2(440, 16), _on_open_settings)
	settings_button.size = Vector2(28, 28)
	add_child(settings_button)

	# Stuck overlay
	stuck_overlay = ColorRect.new()
	stuck_overlay.color = Color(0, 0, 0, 0)
	stuck_overlay.size = get_viewport().get_visible_rect().size
	stuck_overlay.visible = false
	stuck_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stuck_overlay)

	stuck_label = Label.new()
	stuck_label.add_theme_font_size_override("font_size", 22)
	stuck_label.add_theme_color_override("font_color", Color("#ff8888"))
	stuck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stuck_label.text = "No moves left!"
	stuck_label.position = Vector2(0, 420)
	stuck_label.size = Vector2(480, 30)
	stuck_label.visible = false
	add_child(stuck_label)

	stuck_undo_button = _make_button("↩ Undo", Vector2(120, 460), _on_undo)
	stuck_undo_button.visible = false
	add_child(stuck_undo_button)

	stuck_restart_button = _make_button("↻ Restart", Vector2(260, 460), _on_restart)
	stuck_restart_button.visible = false
	add_child(stuck_restart_button)

	# Settings overlay
	settings_overlay = ColorRect.new()
	settings_overlay.color = Color(0, 0, 0, 0)
	settings_overlay.size = get_viewport().get_visible_rect().size
	settings_overlay.visible = false
	settings_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(settings_overlay)

	cb_button = _make_button("", Vector2(140, 350), _on_toggle_colorblind)
	cb_button.size = Vector2(200, 32)
	cb_button.visible = false
	add_child(cb_button)

	mute_button = _make_button("", Vector2(140, 390), _on_toggle_mute)
	mute_button.size = Vector2(200, 32)
	mute_button.visible = false
	add_child(mute_button)

	close_settings_button = _make_button("Close", Vector2(180, 440), _on_close_settings)
	close_settings_button.size = Vector2(120, 32)
	close_settings_button.visible = false
	add_child(close_settings_button)

func _make_button(text: String, pos: Vector2, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", ACCENT)
	btn.add_theme_stylebox_override("normal", _make_style())
	btn.add_theme_stylebox_override("hover", _make_style(Color("#2A2A4E")))
	btn.add_theme_stylebox_override("pressed", _make_style(Color("#1A1A2E")))
	btn.pressed.connect(callback)
	btn.size = Vector2(90, 28)
	return btn

func _make_style(bg := Color("#1A1A2E")) -> StyleBox:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(1)
	sb.border_color = Color("#2A2A4E")
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	return sb

func _process(_delta):
	if not main_ref:
		return
	
	var state = main_ref.get_game_state()
	if not state:
		return
	
	# Update move counter
	move_label.text = "Moves: " + str(state.move_count)
	
	# Update level name
	if level_name_label:
		level_name_label.text = main_ref.get_current_level_name()

func show_win(stars: int, pack_info: Dictionary):
	if win_overlay.visible:
		return
	
	var viewport = get_viewport().get_visible_rect().size
	
	win_overlay.visible = true
	win_overlay.color = Color(0, 0, 0, 0.7)
	win_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Win title
	win_label.text = "Level Complete!"
	win_label.position = Vector2(0, viewport.y * 0.25)
	win_label.size = Vector2(viewport.x, 40)
	win_label.visible = true
	
	# Stars
	var star_text = ""
	for i in range(stars):
		star_text += "★"
	for i in range(3 - stars):
		star_text += "☆"
	
	stars_label.text = star_text
	stars_label.position = Vector2(0, viewport.y * 0.32)
	stars_label.size = Vector2(viewport.x, 60)
	stars_label.visible = true
	
	# Pack info
	var info_label = Label.new()
	info_label.name = "WinInfoLabel"
	info_label.text = pack_info.name + " Pack  —  Level " + str(pack_info.level_in_pack + 1)
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color("#888888"))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.position = Vector2(0, viewport.y * 0.42)
	info_label.size = Vector2(viewport.x, 24)
	add_child(info_label)
	
	# Show buttons
	next_button.visible = true
	menu_from_win.visible = true

func _hide_win():
	win_overlay.visible = false
	win_label.visible = false
	stars_label.visible = false
	next_button.visible = false
	menu_from_win.visible = false
	var info_label = get_node_or_null("WinInfoLabel")
	if info_label:
		info_label.queue_free()

func _on_undo():
	if main_ref:
		main_ref.undo_move()

func _on_restart():
	if main_ref:
		main_ref.restart_level()
		_hide_win()

func _on_hint():
	if main_ref:
		main_ref.show_hint()

func _on_next():
	_hide_win()
	if main_ref:
		main_ref.next_level()

func _on_menu():
	_hide_win()
	hide_stuck()
	_on_close_settings()
	if main_ref:
		main_ref.back_to_menu()

# --- Stuck overlay ---

func show_stuck():
	stuck_overlay.visible = true
	stuck_overlay.color = Color(0, 0, 0, 0.45)
	stuck_label.visible = true
	stuck_undo_button.visible = true
	stuck_restart_button.visible = true

func hide_stuck():
	if stuck_overlay:
		stuck_overlay.visible = false
		stuck_overlay.color = Color(0, 0, 0, 0)
	if stuck_label:
		stuck_label.visible = false
	if stuck_undo_button:
		stuck_undo_button.visible = false
	if stuck_restart_button:
		stuck_restart_button.visible = false

# --- Settings ---

func _on_open_settings():
	settings_open = true
	settings_overlay.visible = true
	settings_overlay.color = Color(0, 0, 0, 0.6)
	settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	cb_button.visible = true
	mute_button.visible = true
	close_settings_button.visible = true
	_refresh_settings_labels()

func _on_close_settings():
	settings_open = false
	if settings_overlay:
		settings_overlay.visible = false
		settings_overlay.color = Color(0, 0, 0, 0)
		settings_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if cb_button: cb_button.visible = false
	if mute_button: mute_button.visible = false
	if close_settings_button: close_settings_button.visible = false

func _refresh_settings_labels():
	if not main_ref:
		return
	cb_button.text = "Colorblind: " + ("ON" if main_ref.is_colorblind() else "OFF")
	mute_button.text = "Sound: " + ("OFF" if main_ref.is_muted() else "ON")

func _on_toggle_colorblind():
	if main_ref:
		main_ref.toggle_colorblind()
		_refresh_settings_labels()

func _on_toggle_mute():
	if main_ref:
		main_ref.toggle_mute()
		_refresh_settings_labels()
