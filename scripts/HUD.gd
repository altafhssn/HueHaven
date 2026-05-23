extends CanvasLayer

# HUD — move counter, undo button, hint button, restart, win overlay

const StyleScript = preload("res://scripts/Style.gd")
const IconScript = preload("res://scripts/Icon.gd")

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
var stars_glyph: Control = null
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

var win_card: Panel = null
var stuck_card: Panel = null
var settings_card: Panel = null

var ACCENT = Color("#e8d5a3")
var BG = Color("#0D0D1A")

func _ready():
	_setup_hud()

func _setup_hud():
	var vp: Vector2 = get_viewport().get_visible_rect().size

	# Menu button (top-left)
	menu_button = _make_icon_button("back", Vector2(14, 14), 38, _on_menu)
	add_child(menu_button)

	# Settings button (top-right)
	settings_button = _make_icon_button("settings", Vector2(vp.x - 52, 14), 38, _on_open_settings)
	add_child(settings_button)

	# Level name (centered, top) — bold, uppercase, letter-spaced
	level_name_label = Label.new()
	level_name_label.name = "LevelNameLabel"
	level_name_label.add_theme_font_size_override("font_size", 22)
	level_name_label.add_theme_color_override("font_color", StyleScript.TEXT)
	level_name_label.add_theme_constant_override("outline_size", 6)
	level_name_label.add_theme_color_override("font_outline_color", Color(0.5, 0.78, 0.92, 0.35))
	level_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_name_label.position = Vector2(0, 18)
	level_name_label.size = Vector2(vp.x, 28)
	add_child(level_name_label)

	# Moves chip — pill, centered just below level name
	var chip := Panel.new()
	chip.name = "MovesChip"
	chip.size = Vector2(120, 26)
	chip.position = Vector2((vp.x - 120) / 2, 50)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = StyleScript.PANEL
	chip_style.border_color = StyleScript.PANEL_BORDER
	chip_style.set_border_width_all(1)
	chip_style.corner_radius_top_left = 13
	chip_style.corner_radius_top_right = 13
	chip_style.corner_radius_bottom_left = 13
	chip_style.corner_radius_bottom_right = 13
	chip.add_theme_stylebox_override("panel", chip_style)
	add_child(chip)

	move_label = Label.new()
	move_label.text = "0 moves"
	move_label.add_theme_font_size_override("font_size", 12)
	move_label.add_theme_color_override("font_color", StyleScript.TEXT_MUTED)
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	move_label.position = Vector2((vp.x - 120) / 2, 50)
	move_label.size = Vector2(120, 26)
	move_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(move_label)

	# Bottom action bar with its own panel background
	var bar_h: float = 96.0
	var bar := Panel.new()
	bar.name = "ActionBar"
	bar.size = Vector2(vp.x, bar_h)
	bar.position = Vector2(0, vp.y - bar_h)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_style := StyleBoxFlat.new()
	# Translucent surface so the animated background still bleeds through
	bar_style.bg_color = Color(StyleScript.PANEL.r, StyleScript.PANEL.g, StyleScript.PANEL.b, 0.85)
	bar_style.border_color = StyleScript.PANEL_BORDER
	bar_style.border_width_top = 1
	bar.add_theme_stylebox_override("panel", bar_style)
	add_child(bar)

	# Three primary actions, vertically centered in the bar
	var btn_w: float = 116.0
	var btn_h: float = 50.0
	var gap: float = 14.0
	var total: float = btn_w * 3 + gap * 2
	var start_x: float = (vp.x - total) / 2
	var btn_y: float = vp.y - bar_h + (bar_h - btn_h) / 2

	undo_button = _make_action_button("undo", "Undo", Vector2(start_x, btn_y), btn_w, btn_h, _on_undo, false)
	add_child(undo_button)
	hint_button = _make_action_button("hint", "Hint", Vector2(start_x + btn_w + gap, btn_y), btn_w, btn_h, _on_hint, true)
	add_child(hint_button)
	restart_button = _make_action_button("restart", "Restart", Vector2(start_x + (btn_w + gap) * 2, btn_y), btn_w, btn_h, _on_restart, false)
	add_child(restart_button)
	
	# --- Win overlay: dim + centered card ---
	win_overlay = ColorRect.new()
	win_overlay.color = Color(0, 0, 0, 0)
	win_overlay.size = vp
	win_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_overlay.visible = false
	add_child(win_overlay)

	var card_w := 320.0
	var card_h := 290.0
	var card_x := (vp.x - card_w) / 2
	var card_y := (vp.y - card_h) / 2

	win_card = Panel.new()
	win_card.position = Vector2(card_x, card_y)
	win_card.size = Vector2(card_w, card_h)
	win_card.add_theme_stylebox_override("panel", _card_style())
	win_card.visible = false
	win_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(win_card)

	win_label = Label.new()
	win_label.add_theme_font_size_override("font_size", 26)
	win_label.add_theme_color_override("font_color", StyleScript.TEXT)
	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label.position = Vector2(card_x, card_y + 28)
	win_label.size = Vector2(card_w, 32)
	win_label.visible = false
	add_child(win_label)

	# Stars row — uses a custom-draw Control with geometric stars
	stars_label = Label.new()  # kept as backing data for compat
	stars_label.add_theme_font_size_override("font_size", 1)
	stars_label.modulate.a = 0
	add_child(stars_label)

	stars_glyph = Control.new()
	stars_glyph.position = Vector2(card_x, card_y + 80)
	stars_glyph.size = Vector2(card_w, 64)
	stars_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stars_glyph.visible = false
	stars_glyph.set_meta("filled", 0)
	stars_glyph.draw.connect(func():
		var filled: int = stars_glyph.get_meta("filled", 0)
		var star_sz: float = 52.0
		var gap2: float = 14.0
		var total2: float = 3.0 * star_sz + 2.0 * gap2
		var sx0: float = (stars_glyph.size.x - total2) * 0.5 + star_sz * 0.5
		for s in range(3):
			var sx: float = sx0 + float(s) * (star_sz + gap2)
			var col := StyleScript.STAR if s < filled else StyleScript.TEXT_DIM
			IconScript.draw(stars_glyph, "star", Vector2(sx, stars_glyph.size.y * 0.5), star_sz, col)
	)
	add_child(stars_glyph)

	next_button = _make_text_button("Next →", Vector2(card_x + 30, card_y + 200), card_w - 60, 44, _on_next)
	next_button.add_theme_font_size_override("font_size", 16)
	StyleScript.style_button(next_button, true)
	next_button.visible = false
	add_child(next_button)

	menu_from_win = _make_text_button("Level Select", Vector2(card_x + 30, card_y + 200 + 50), card_w - 60, 36, _on_menu)
	menu_from_win.add_theme_color_override("font_color", StyleScript.TEXT_MUTED)
	menu_from_win.visible = false
	add_child(menu_from_win)

	# --- Stuck overlay: dim + centered card ---
	stuck_overlay = ColorRect.new()
	stuck_overlay.color = Color(0, 0, 0, 0)
	stuck_overlay.size = vp
	stuck_overlay.visible = false
	stuck_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stuck_overlay)

	var sc_w := 300.0
	var sc_h := 140.0
	stuck_card = Panel.new()
	stuck_card.position = Vector2((vp.x - sc_w) / 2, vp.y * 0.42 - 22)
	stuck_card.size = Vector2(sc_w, sc_h)
	stuck_card.add_theme_stylebox_override("panel", _card_style())
	stuck_card.visible = false
	stuck_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stuck_card)

	stuck_label = Label.new()
	stuck_label.add_theme_font_size_override("font_size", 20)
	stuck_label.add_theme_color_override("font_color", StyleScript.DANGER)
	stuck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stuck_label.text = "No moves left"
	stuck_label.position = Vector2(0, vp.y * 0.42)
	stuck_label.size = Vector2(vp.x, 28)
	stuck_label.visible = false
	add_child(stuck_label)

	stuck_undo_button = _make_text_button("↺  Undo", Vector2(vp.x / 2 - 120, vp.y * 0.42 + 50), 110, 44, _on_undo)
	stuck_undo_button.visible = false
	add_child(stuck_undo_button)

	stuck_restart_button = _make_text_button("↻  Restart", Vector2(vp.x / 2 + 10, vp.y * 0.42 + 50), 110, 44, _on_restart)
	stuck_restart_button.visible = false
	add_child(stuck_restart_button)

	# --- Settings modal: dim + centered card ---
	settings_overlay = ColorRect.new()
	settings_overlay.color = Color(0, 0, 0, 0)
	settings_overlay.size = vp
	settings_overlay.visible = false
	settings_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(settings_overlay)

	var stg_w := 320.0
	var stg_h := 240.0
	var sx := (vp.x - 280) / 2
	var sy := (vp.y - 220) / 2

	settings_card = Panel.new()
	settings_card.position = Vector2((vp.x - stg_w) / 2, (vp.y - stg_h) / 2)
	settings_card.size = Vector2(stg_w, stg_h)
	settings_card.add_theme_stylebox_override("panel", _card_style())
	settings_card.visible = false
	settings_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(settings_card)
	cb_button = _make_text_button("", Vector2(sx, sy + 40), 280, 44, _on_toggle_colorblind)
	cb_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	cb_button.visible = false
	add_child(cb_button)

	mute_button = _make_text_button("", Vector2(sx, sy + 92), 280, 44, _on_toggle_mute)
	mute_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	mute_button.visible = false
	add_child(mute_button)

	close_settings_button = _make_text_button("Close", Vector2(sx + 60, sy + 158), 160, 40, _on_close_settings)
	close_settings_button.visible = false
	add_child(close_settings_button)

func _card_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = StyleScript.PANEL
	sb.border_color = StyleScript.PANEL_BORDER_HI
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_left = 16
	sb.corner_radius_bottom_right = 16
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 6)
	return sb

func _make_action_button(icon_name: String, label_text: String, pos: Vector2, w: float, h: float, callback: Callable, primary: bool) -> Button:
	var btn := Button.new()
	btn.text = "    " + label_text  # leading space leaves room for icon
	btn.position = pos
	btn.size = Vector2(w, h)
	btn.add_theme_font_size_override("font_size", 15)
	StyleScript.style_button(btn, primary)
	btn.pressed.connect(callback)
	btn.focus_mode = Control.FOCUS_NONE
	# Icon glyph on the left
	var glyph := Control.new()
	glyph.position = Vector2(12, (h - 22) * 0.5)
	glyph.size = Vector2(22, 22)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_col: Color = Color("#1a1208") if primary else StyleScript.TEXT
	glyph.set_meta("icon_name", icon_name)
	glyph.set_meta("icon_color", icon_col)
	glyph.draw.connect(func():
		var name: String = glyph.get_meta("icon_name", "")
		var col: Color = glyph.get_meta("icon_color", Color.WHITE)
		IconScript.draw(glyph, name, glyph.size * 0.5, 22, col)
	)
	btn.add_child(glyph)
	return btn

func _make_text_button(text: String, pos: Vector2, w: float, h: float, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(w, h)
	btn.add_theme_font_size_override("font_size", 14)
	StyleScript.style_button(btn, false)
	btn.pressed.connect(callback)
	btn.focus_mode = Control.FOCUS_NONE
	return btn

func _make_icon_button(icon_name: String, pos: Vector2, sz: float, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = ""  # icon drawn via child Control
	btn.position = pos
	btn.size = Vector2(sz, sz)
	StyleScript.style_button(btn, false)
	btn.pressed.connect(callback)
	btn.focus_mode = Control.FOCUS_NONE
	# Icon overlay
	var glyph := Control.new()
	glyph.size = btn.size
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.set_meta("icon_name", icon_name)
	glyph.set_meta("icon_color", StyleScript.TEXT)
	glyph.draw.connect(func():
		var name: String = glyph.get_meta("icon_name", "")
		var col: Color = glyph.get_meta("icon_color", Color.WHITE)
		IconScript.draw(glyph, name, glyph.size * 0.5, glyph.size.x, col)
	)
	btn.add_child(glyph)
	return btn

# Legacy helpers (still called by older code paths in this file)
func _make_button(text: String, pos: Vector2, callback: Callable) -> Button:
	return _make_text_button(text, pos, 100, 36, callback)

func _process(_delta):
	if not main_ref:
		return
	
	var state = main_ref.get_game_state()
	if not state:
		return
	
	# Update move counter — par hint when present
	var par := int(state.level_data.get("par_moves", 0))
	if par > 0:
		move_label.text = str(state.move_count) + " / " + str(par) + " moves"
	else:
		move_label.text = str(state.move_count) + " moves"

	# Update level name (uppercase for impact, like the reference)
	if level_name_label:
		level_name_label.text = main_ref.get_current_level_name().to_upper()

func show_win(stars: int, pack_info: Dictionary):
	if win_overlay.visible:
		return

	win_overlay.visible = true
	win_overlay.color = Color(0, 0, 0, 0.55)
	win_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if win_card:
		win_card.visible = true

	# Title
	win_label.text = "Level Complete"
	win_label.visible = true

	# Stars — geometric
	if stars_glyph:
		stars_glyph.set_meta("filled", stars)
		stars_glyph.visible = true
		stars_glyph.queue_redraw()

	# Pack info label
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var card_w := 320.0
	var card_x := (vp.x - card_w) / 2
	var card_y := (vp.y - 280) / 2
	var info_label = Label.new()
	info_label.name = "WinInfoLabel"
	info_label.text = pack_info.name + " · Level " + str(pack_info.level_in_pack + 1)
	info_label.add_theme_font_size_override("font_size", 13)
	info_label.add_theme_color_override("font_color", StyleScript.TEXT_MUTED)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.position = Vector2(card_x, card_y + 152)
	info_label.size = Vector2(card_w, 22)
	add_child(info_label)

	next_button.visible = true
	menu_from_win.visible = true

func _hide_win():
	win_overlay.visible = false
	if win_card:
		win_card.visible = false
	win_label.visible = false
	if stars_glyph:
		stars_glyph.visible = false
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
	stuck_overlay.color = Color(0, 0, 0, 0.5)
	if stuck_card:
		stuck_card.visible = true
	stuck_label.visible = true
	stuck_undo_button.visible = true
	stuck_restart_button.visible = true

func hide_stuck():
	if stuck_overlay:
		stuck_overlay.visible = false
		stuck_overlay.color = Color(0, 0, 0, 0)
	if stuck_card:
		stuck_card.visible = false
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
	if settings_card:
		settings_card.visible = true
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
	if settings_card: settings_card.visible = false
	if cb_button: cb_button.visible = false
	if mute_button: mute_button.visible = false
	if close_settings_button: close_settings_button.visible = false

func _refresh_settings_labels():
	if not main_ref:
		return
	cb_button.text = "    Colorblind shapes" + ("     ON" if main_ref.is_colorblind() else "     OFF")
	mute_button.text = "    Sound" + ("                  OFF" if main_ref.is_muted() else "                  ON")

func _on_toggle_colorblind():
	if main_ref:
		main_ref.toggle_colorblind()
		_refresh_settings_labels()

func _on_toggle_mute():
	if main_ref:
		main_ref.toggle_mute()
		_refresh_settings_labels()
