extends Node2D

# Main entry point for Ball Sort
# Loads level, manages game state, renders tubes, handles HUD

var GameStateScript = preload("res://scripts/GameState.gd")
var LevelDataScript = preload("res://scripts/LevelData.gd")
var BallColorsScript = preload("res://scripts/BallColors.gd")
var LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
var ProgressionScript = preload("res://scripts/Progression.gd")
var LevelSelectScript = preload("res://scripts/LevelSelect.gd")

var game_state = null
var tube_grid = null
var hud = null
var level_select = null
var progression = null

var selected_tube: int = -1
var selected_ball_lift: float = 0.0
var move_animating: bool = false
var anim_from: int = -1
var anim_to: int = -1
var anim_progress: float = 0.0
var anim_ball = null  # raw ball entry (int or Dictionary)

var confetti: Array = []   # active confetti particles
var stuck: bool = false    # no legal moves remain
var colorblind: bool = false

var viewport_size: Vector2
var cell_size: float = 64.0
var tube_width: float = 48.0
var tube_height: float = 220.0
var ball_radius: float = 18.0
var _tube_gap: float = 12.0
var grid_offset: Vector2

var shake_tubes: Dictionary = {}  # tube_idx -> timer
var sparkle_tubes: Array = []     # tubes to show sparkle on

var hint_from: int = -1
var hint_to: int = -1
var hint_timer: float = 0.0

var current_level_idx: int = 0
var is_using_generated_levels: bool = false
var is_showing_level_select: bool = true
var win_shown: bool = false

func _ready():
	viewport_size = get_viewport().get_visible_rect().size

	# Init progression
	progression = ProgressionScript.new()
	colorblind = progression.is_colorblind()

	# Sync audio mute state
	var audio = get_node_or_null("/root/Audio")
	if audio:
		audio.set_muted(progression.is_muted())

	# Create HUD
	var HUDClass = preload("res://scripts/HUD.gd")
	hud = HUDClass.new()
	add_child(hud)
	hud.main_ref = self
	hud.visible = false  # Hide HUD until game starts
	
	# Start with level select
	_show_level_select()

func _show_level_select():
	is_showing_level_select = true
	win_shown = false
	
	# Hide game HUD
	if hud:
		hud.visible = false
	
	# Remove old level select if exists
	if level_select and is_instance_valid(level_select):
		level_select.queue_free()
	
	# Create new level select
	var LSClass = preload("res://scripts/LevelSelect.gd")
	level_select = LSClass.new()
	level_select.main_ref = self
	add_child(level_select)

func start_level(level_idx: int):
	is_showing_level_select = false
	is_using_generated_levels = true
	win_shown = false
	
	# Remove level select
	if level_select and is_instance_valid(level_select):
		level_select.queue_free()
		level_select = null
	
	# Show HUD
	if hud:
		hud.visible = true
	
	_load_generated_level(level_idx)

func _load_generated_level(idx: int):
	current_level_idx = idx
	
	# Generate level
	var level_data = LevelGeneratorScript.generate_level(idx)
	
	game_state = GameStateScript.new(level_data)
	grid_offset = _calc_grid_offset(level_data)
	selected_tube = -1
	shake_tubes.clear()
	sparkle_tubes.clear()
	confetti.clear()
	move_animating = false
	win_shown = false
	stuck = false
	hint_from = -1
	hint_to = -1
	hint_timer = 0
	queue_redraw()

func _calc_grid_offset(level_data) -> Vector2:
	var n_tubes = level_data.contents.size()
	# Scale tube/ball size down for crowded levels so they fit within the viewport.
	var margin = 24.0
	var gap = 12.0
	var available = viewport_size.x - margin * 2
	var max_tube_w = (available - gap * (n_tubes - 1)) / n_tubes
	tube_width = clamp(max_tube_w, 24.0, 48.0)
	# If still too narrow, shrink the gap
	if max_tube_w < 24.0:
		gap = max(2.0, (available - 24.0 * n_tubes) / max(1, n_tubes - 1))
		tube_width = 24.0
	ball_radius = clamp(tube_width * 0.42, 8.0, 18.0)
	tube_height = (ball_radius * 2 + 2) * level_data.capacity + 12
	_tube_gap = gap

	var total_width = n_tubes * (tube_width + gap) - gap
	var start_x = (viewport_size.x - total_width) / 2
	return Vector2(start_x, 180)

func _draw():
	if is_showing_level_select:
		return
	
	if not game_state:
		return
	
	var level_data = game_state.level_data
	var tubes = game_state.tubes
	var n_tubes = tubes.size()
	var capacity = level_data.capacity
	
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#0D0D1A"))
	
	# Draw each tube
	for i in range(n_tubes):
		# Shake offset: oscillates and fades as timer expires
		var shake_x = 0.0
		if shake_tubes.has(i):
			var t = shake_tubes[i]
			shake_x = sin(t * 60.0) * 8.0 * min(t / 0.3, 1.0)
		var tube_x = grid_offset.x + i * (tube_width + _tube_gap) + shake_x
		var tube_rect = Rect2(tube_x, grid_offset.y, tube_width, tube_height)
		
		# Tube background
		var bg_color = Color("#1A1A2E")
		if selected_tube == i:
			bg_color = Color("#2A2A4E")
		
		# Tube shape (rounded rectangle)
		draw_rounded_rect(tube_rect, bg_color, 6)
		draw_rounded_rect(tube_rect, Color("#2A2A4E"), 6, false, 1.5)
		
		if selected_tube == i:
			var glow_rect = tube_rect.grow(3)
			draw_rounded_rect(glow_rect, Color("#e8d5a3"), 8, false, 1.0)
		
		# Draw balls in tube (bottom to top)
		var tube_contents = tubes[i]
		var n_balls = tube_contents.size()
		
		for j in range(n_balls):
			var ball_entry = tube_contents[j]
			var y_pos = grid_offset.y + tube_height - (j + 1) * (ball_radius * 2 + 2)

			# Lift animation for selected tube's top ball
			var lift_offset = 0.0
			if selected_tube == i and j == n_balls - 1:
				lift_offset = -20.0 - sin(Time.get_ticks_msec() * 0.005) * 4.0

			_draw_ball(Vector2(tube_x + tube_width / 2, y_pos + lift_offset), ball_entry)
		
		# Empty slots indicator
		for e in range(capacity - n_balls):
			var slot_y = grid_offset.y + tube_height - (n_balls + e + 1) * (ball_radius * 2 + 2)
			var center = Vector2(tube_x + tube_width / 2, slot_y)
			draw_circle(center, ball_radius * 0.5, Color("#2A2A4E", 0.3))
		
		# Sparkle effect for completed tubes
		if sparkle_tubes.has(i):
			var sparkle_alpha = abs(sin(Time.get_ticks_msec() * 0.004))
			var glow_rect = tube_rect.grow(2)
			draw_rounded_rect(glow_rect, Color("#e8d5a3", sparkle_alpha * 0.3), 8)

		# Hint highlight: from tube (blue), to tube (green)
		if hint_timer > 0 and (i == hint_from or i == hint_to):
			var pulse = abs(sin(Time.get_ticks_msec() * 0.008))
			var hint_color = Color("#88ddff") if i == hint_from else Color("#88ff88")
			hint_color.a = pulse * 0.7
			var hint_rect = tube_rect.grow(4)
			draw_rounded_rect(hint_rect, hint_color, 10, false, 2.5)
	
	# Draw animation ball if moving
	if move_animating and anim_ball != null:
		var from_x = grid_offset.x + anim_from * (tube_width + _tube_gap) + tube_width / 2
		var to_x = grid_offset.x + anim_to * (tube_width + _tube_gap) + tube_width / 2
		var from_y = grid_offset.y + tube_height - (game_state.tubes[anim_from].size() + 1) * (ball_radius * 2 + 2)
		var to_y = grid_offset.y + tube_height - (game_state.tubes[anim_to].size() + 1) * (ball_radius * 2 + 2)

		var px = lerp(from_x, to_x, anim_progress)
		var py = lerp(from_y - 30, to_y, anim_progress)
		var arc = sin(anim_progress * PI) * -60
		_draw_ball(Vector2(px, py + arc), anim_ball)

	# Confetti
	for p in confetti:
		var alpha = clamp(p.life / 1.5, 0.0, 1.0)
		var col: Color = p.color
		col.a = alpha
		draw_circle(p.pos, p.size, col)

func _on_level_won():
	# Save stars
	var stars = game_state.get_star_rating()
	progression.set_stars(current_level_idx, stars)

	# Unlock next level
	if current_level_idx + 1 < LevelGeneratorScript.get_total_levels():
		progression.unlock_level(current_level_idx + 1)

	# Audio
	var audio = get_node_or_null("/root/Audio")
	if audio:
		audio.play("win")

	# Burst confetti
	_spawn_confetti(viewport_size.x * 0.5, viewport_size.y * 0.4, 60)

	# Show win overlay via HUD
	if hud:
		var pack_info = LevelGeneratorScript.get_pack_info(current_level_idx)
		hud.show_win(stars, pack_info)

func _spawn_confetti(x: float, y: float, count: int):
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var palette = [
		Color("#EF5350"), Color("#42A5F5"), Color("#66BB6A"),
		Color("#FFEE58"), Color("#AB47BC"), Color("#FFA726"),
	]
	for _i in range(count):
		var angle = rng.randf_range(-PI, 0)  # upward arc
		var speed = rng.randf_range(150.0, 380.0)
		confetti.append({
			"pos": Vector2(x + rng.randf_range(-20, 20), y),
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"life": rng.randf_range(1.0, 1.8),
			"size": rng.randf_range(3.0, 6.0),
			"color": palette[rng.randi() % palette.size()],
		})

func _spawn_explosion(tube_idx: int):
	# Visual: shake the tube + small confetti puff
	shake_tubes[tube_idx] = 0.5
	var x = grid_offset.x + tube_idx * (tube_width + _tube_gap) + tube_width / 2
	var y = grid_offset.y + tube_height * 0.5
	_spawn_confetti(x, y, 20)

func _draw_ball(center: Vector2, ball_entry):
	var stype: String = GameStateScript.get_special_type(ball_entry)
	var color_idx: int = GameStateScript.get_ball_color(ball_entry)

	# Base body color
	var color: Color
	if stype == "rainbow":
		# Animated rainbow gradient
		var hue = fmod(Time.get_ticks_msec() * 0.0005, 1.0)
		color = Color.from_hsv(hue, 0.7, 0.95)
	elif stype == "stone":
		color = Color("#5A5A6E")
	elif color_idx >= 0:
		color = BallColorsScript.get_color(color_idx)
	else:
		color = Color("#888888")

	if color == Color.TRANSPARENT:
		return

	# Ball shadow
	draw_circle(center + Vector2(2, 2), ball_radius, Color(0, 0, 0, 0.3))
	# Ball body
	draw_circle(center, ball_radius, color)
	# Glossy highlight
	var highlight_center = center + Vector2(-ball_radius * 0.3, -ball_radius * 0.3)
	draw_circle(highlight_center, ball_radius * 0.35, Color(1, 1, 1, 0.25))
	# Rim light
	draw_arc(center, ball_radius - 1, 0, TAU, 16, Color(1, 1, 1, 0.1), 1.0)

	# Color-blind shape marker
	if colorblind and color_idx >= 0 and stype != "rainbow":
		_draw_colorblind_marker(center, color_idx)

	# Special overlay
	if stype != "":
		_draw_special_overlay(center, ball_entry)

func _draw_colorblind_marker(center: Vector2, color_idx: int):
	var marker_color = Color(1, 1, 1, 0.85)
	var r = ball_radius * 0.45
	match color_idx % 6:
		0:  # circle
			draw_arc(center, r, 0, TAU, 12, marker_color, 2.0)
		1:  # triangle
			var pts = PackedVector2Array([
				center + Vector2(0, -r),
				center + Vector2(r * 0.9, r * 0.6),
				center + Vector2(-r * 0.9, r * 0.6),
				center + Vector2(0, -r),
			])
			draw_polyline(pts, marker_color, 2.0)
		2:  # square
			var s = r * 0.8
			var pts2 = PackedVector2Array([
				center + Vector2(-s, -s),
				center + Vector2(s, -s),
				center + Vector2(s, s),
				center + Vector2(-s, s),
				center + Vector2(-s, -s),
			])
			draw_polyline(pts2, marker_color, 2.0)
		3:  # diamond
			var pts3 = PackedVector2Array([
				center + Vector2(0, -r),
				center + Vector2(r, 0),
				center + Vector2(0, r),
				center + Vector2(-r, 0),
				center + Vector2(0, -r),
			])
			draw_polyline(pts3, marker_color, 2.0)
		4:  # star (4-point)
			draw_line(center + Vector2(0, -r), center + Vector2(0, r), marker_color, 2.0)
			draw_line(center + Vector2(-r, 0), center + Vector2(r, 0), marker_color, 2.0)
		5:  # ring
			draw_arc(center, r, 0, TAU, 16, marker_color, 2.0)
			draw_arc(center, r * 0.5, 0, TAU, 10, marker_color, 1.5)

func _draw_special_overlay(center: Vector2, ball_entry):
	var stype: String = GameStateScript.get_special_type(ball_entry)
	var fg := Color(1, 1, 1, 0.95)
	match stype:
		"bomb":
			# Fuse circle + remaining-moves number
			var remaining = int(ball_entry.get("meta", 0))
			draw_arc(center, ball_radius * 0.55, 0, TAU, 16, Color(0, 0, 0, 0.6), 2.5)
			_draw_centered_text(center + Vector2(0, 0), str(remaining), 12, fg)
		"rainbow":
			# Sparkle dot at center
			draw_circle(center, ball_radius * 0.2, Color(1, 1, 1, 0.9))
		"stone":
			# Cross-hatch
			var r = ball_radius * 0.55
			draw_line(center + Vector2(-r, -r), center + Vector2(r, r), Color(0, 0, 0, 0.4), 2.0)
			draw_line(center + Vector2(-r, r), center + Vector2(r, -r), Color(0, 0, 0, 0.4), 2.0)
		"magnet":
			# U-shape
			var r2 = ball_radius * 0.5
			draw_arc(center + Vector2(0, r2 * 0.2), r2, PI, TAU, 12, fg, 2.5)
			draw_line(center + Vector2(-r2, r2 * 0.2), center + Vector2(-r2, -r2 * 0.6), fg, 2.5)
			draw_line(center + Vector2(r2, r2 * 0.2), center + Vector2(r2, -r2 * 0.6), fg, 2.5)
		"hourglass":
			# Hourglass shape
			var r3 = ball_radius * 0.5
			var pts = PackedVector2Array([
				center + Vector2(-r3, -r3),
				center + Vector2(r3, -r3),
				center + Vector2(-r3, r3),
				center + Vector2(r3, r3),
				center + Vector2(-r3, -r3),
			])
			draw_polyline(pts, fg, 2.0)

func _draw_centered_text(pos: Vector2, text: String, size: int, color: Color):
	var font = ThemeDB.fallback_font
	var fs = size
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, fs * 0.4), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)

func draw_rounded_rect(rect: Rect2, color: Color, radius: float, filled: bool = true, width: float = 1.0):
	var r = min(radius, rect.size.x / 2, rect.size.y / 2)
	var pts = PackedVector2Array()
	
	# Top edge
	pts.append(rect.position + Vector2(r, 0))
	pts.append(rect.position + Vector2(rect.size.x - r, 0))
	pts.append(rect.position + Vector2(rect.size.x, r))
	pts.append(rect.position + Vector2(rect.size.x, rect.size.y - r))
	pts.append(rect.position + Vector2(rect.size.x - r, rect.size.y))
	pts.append(rect.position + Vector2(r, rect.size.y))
	pts.append(rect.position + Vector2(0, rect.size.y - r))
	pts.append(rect.position + Vector2(0, r))
	
	if filled:
		draw_colored_polygon(pts, color)
	else:
		var outline = PackedVector2Array()
		outline.resize(pts.size() + 1)
		for i in range(pts.size()):
			outline[i] = pts[i]
		outline[pts.size()] = pts[0]
		draw_polyline(outline, color, width, true)

func _unhandled_input(event):
	if is_showing_level_select:
		return
	if not game_state or game_state.is_level_won() or move_animating:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_tube_tap(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_tube_tap(event.position)

func _tube_tap(pos: Vector2):
	var level_data = game_state.level_data
	var n_tubes = level_data.contents.size()
	
	# Find which tube was tapped
	for i in range(n_tubes):
		var tube_x = grid_offset.x + i * (tube_width + _tube_gap)
		var tube_rect = Rect2(tube_x, grid_offset.y, tube_width, tube_height)
		
		if tube_rect.has_point(pos):
			_on_tube_tapped(i)
			return

func _on_tube_tapped(tube_idx: int):
	# Player interaction clears the active hint
	if hint_timer > 0:
		hint_timer = 0
		hint_from = -1
		hint_to = -1

	var audio = get_node_or_null("/root/Audio")

	if selected_tube < 0:
		# Selecting a tube
		var contents = game_state.tubes[tube_idx]
		if contents.size() > 0 and not game_state.is_tube_complete(tube_idx):
			# Refuse to select a tube whose top is a stone
			var top = contents[-1]
			if GameStateScript.is_stone(top):
				shake_tubes[tube_idx] = 0.3
				if audio: audio.play("invalid")
				return
			selected_tube = tube_idx
			if audio: audio.play("select")
	else:
		# Attempting to place ball
		if tube_idx == selected_tube:
			# Deselect
			selected_tube = -1
			if audio: audio.play("deselect")
		elif game_state.can_move(selected_tube, tube_idx):
			# Valid move - animate it
			_start_move_animation(selected_tube, tube_idx)
			selected_tube = -1
		else:
			# Invalid move - shake target
			shake_tubes[tube_idx] = 0.3
			if audio: audio.play("invalid")

func _start_move_animation(from: int, to: int):
	move_animating = true
	anim_from = from
	anim_to = to
	anim_progress = 0.0
	anim_ball = game_state.tubes[from][-1]
	var audio = get_node_or_null("/root/Audio")
	if audio:
		audio.play("move")

func _process(delta):
	if is_showing_level_select:
		return

	# Decrement shake timers
	if not shake_tubes.is_empty():
		var to_remove: Array = []
		for idx in shake_tubes.keys():
			shake_tubes[idx] -= delta
			if shake_tubes[idx] <= 0:
				to_remove.append(idx)
		for idx in to_remove:
			shake_tubes.erase(idx)

	# Decrement hint timer
	if hint_timer > 0:
		hint_timer -= delta
		if hint_timer <= 0:
			hint_from = -1
			hint_to = -1

	if move_animating:
		var speed = 2.0
		anim_progress += delta * speed
		if anim_progress >= 1.0:
			anim_progress = 1.0
			game_state.move_ball(anim_from, anim_to)
			move_animating = false
			anim_ball = null

			# Drain queued special effects
			var audio = get_node_or_null("/root/Audio")
			for fx in game_state.take_effects():
				if audio:
					audio.play(fx.type)
				if fx.type == "bomb_explode":
					_spawn_explosion(fx.tube)

			# Check for completed tube
			if game_state.is_tube_complete(anim_to):
				sparkle_tubes.append(anim_to)
				if audio: audio.play("complete_tube")

			# Check win after the move actually resolves
			if game_state.is_level_won() and not win_shown:
				win_shown = true
				_on_level_won()
			elif not game_state.has_any_move() and not stuck:
				stuck = true
				if audio: audio.play("stuck")
				if hud:
					hud.show_stuck()

	# Confetti physics
	if not confetti.is_empty():
		var still_alive: Array = []
		for p in confetti:
			p.vel.y += 220.0 * delta
			p.pos += p.vel * delta
			p.life -= delta
			if p.life > 0 and p.pos.y < viewport_size.y + 40:
				still_alive.append(p)
		confetti = still_alive

	queue_redraw()

func _input(event):
	if is_showing_level_select:
		return
	if game_state and game_state.is_level_won() and not move_animating:
		# Win screen input handled by HUD now
		pass

# Public methods for HUD
func undo_move():
	if not move_animating and game_state:
		var ok = game_state.undo()
		if ok:
			var audio = get_node_or_null("/root/Audio")
			if audio: audio.play("undo")
			stuck = false
			if hud and hud.has_method("hide_stuck"):
				hud.hide_stuck()

func toggle_colorblind() -> bool:
	colorblind = not colorblind
	progression.set_setting("colorblind", colorblind)
	queue_redraw()
	return colorblind

func toggle_mute() -> bool:
	var audio = get_node_or_null("/root/Audio")
	var new_state = not progression.is_muted()
	progression.set_setting("muted", new_state)
	if audio:
		audio.set_muted(new_state)
	return new_state

func is_colorblind() -> bool:
	return colorblind

func is_muted() -> bool:
	return progression.is_muted()

func show_hint():
	if not game_state or move_animating or game_state.is_level_won():
		return
	var hint = game_state.find_hint()
	if hint[0] >= 0:
		hint_from = hint[0]
		hint_to = hint[1]
		hint_timer = 1.8

func restart_level():
	if game_state:
		_load_generated_level(current_level_idx)
		if hud and hud.has_method("hide_stuck"):
			hud.hide_stuck()

func next_level():
	var next_idx = current_level_idx + 1
	if next_idx < LevelGeneratorScript.get_total_levels():
		_load_generated_level(next_idx)
	else:
		# Back to level select
		_show_level_select()

func back_to_menu():
	_show_level_select()

func get_current_level() -> int:
	return current_level_idx

func get_game_state():
	return game_state

func get_current_level_name() -> String:
	if is_using_generated_levels:
		var pack_info = LevelGeneratorScript.get_pack_info(current_level_idx)
		return pack_info.name + " " + str(pack_info.level_in_pack + 1)
	else:
		return "Level " + str(current_level_idx + 1)
