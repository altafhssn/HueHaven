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
var anim_ball_color: int = -1

var viewport_size: Vector2
var cell_size: float = 64.0
var tube_width: float = 48.0
var tube_height: float = 220.0
var ball_radius: float = 18.0
var grid_offset: Vector2

var shake_tubes: Dictionary = {}  # tube_idx -> timer
var sparkle_tubes: Array = []     # tubes to show sparkle on

var current_level_idx: int = 0
var is_using_generated_levels: bool = false
var is_showing_level_select: bool = true
var win_shown: bool = false

func _ready():
	viewport_size = get_viewport().get_visible_rect().size
	
	# Init progression
	progression = ProgressionScript.new()
	
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
	move_animating = false
	win_shown = false
	queue_redraw()

func _calc_grid_offset(level_data) -> Vector2:
	var n_tubes = level_data.contents.size()
	var total_width = n_tubes * (tube_width + 12) - 12
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
		var tube_x = grid_offset.x + i * (tube_width + 12)
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
			var ball_color_idx = tube_contents[j]
			var y_pos = grid_offset.y + tube_height - (j + 1) * (ball_radius * 2 + 2)
			
			# Lift animation for selected tube's top ball
			var lift_offset = 0.0
			if selected_tube == i and j == n_balls - 1:
				lift_offset = -20.0 - sin(Time.get_ticks_msec() * 0.005) * 4.0
			
			_draw_ball(Vector2(tube_x + tube_width / 2, y_pos + lift_offset), ball_color_idx)
		
		# Empty slots indicator
		for e in range(capacity - n_balls):
			var slot_y = grid_offset.y + tube_height - (n_balls + e + 1) * (ball_radius * 2 + 2)
			var center = Vector2(tube_x + tube_width / 2, slot_y)
			draw_circle(center, ball_radius * 0.5, Color("#2A2A4E", 0.3))
		
		# Shake effect
		if shake_tubes.has(i):
			var st = shake_tubes[i]
			shake_tubes[i] = st - 0.016
			if shake_tubes[i] <= 0:
				shake_tubes.erase(i)
		
		# Sparkle effect for completed tubes
		if sparkle_tubes.has(i):
			var sparkle_alpha = abs(sin(Time.get_ticks_msec() * 0.004))
			var glow_rect = tube_rect.grow(2)
			draw_rounded_rect(glow_rect, Color("#e8d5a3", sparkle_alpha * 0.3), 8)
	
	# Draw animation ball if moving
	if move_animating:
		var anim_color = anim_ball_color
		if anim_color >= 0:
			var from_x = grid_offset.x + anim_from * (tube_width + 12) + tube_width / 2
			var to_x = grid_offset.x + anim_to * (tube_width + 12) + tube_width / 2
			var from_y = grid_offset.y + tube_height - (game_state.tubes[anim_from].size() + 1) * (ball_radius * 2 + 2)
			var to_y = grid_offset.y + tube_height - (game_state.tubes[anim_to].size() + 1) * (ball_radius * 2 + 2)
			
			var px = lerp(from_x, to_x, anim_progress)
			var py = lerp(from_y - 30, to_y, anim_progress)
			# Arc: go up then down
			var arc = sin(anim_progress * PI) * -60
			_draw_ball(Vector2(px, py + arc), anim_color)
	
	# Draw win overlay
	if game_state and game_state.is_level_won() and not win_shown:
		win_shown = true
		_on_level_won()

func _on_level_won():
	# Save stars
	var stars = game_state.get_star_rating()
	progression.set_stars(current_level_idx, stars)
	
	# Unlock next level
	if current_level_idx + 1 < LevelGeneratorScript.get_total_levels():
		progression.unlock_level(current_level_idx + 1)
	
	# Show win overlay via HUD
	if hud:
		var pack_info = LevelGeneratorScript.get_pack_info(current_level_idx)
		hud.show_win(stars, pack_info)

func _draw_ball(center: Vector2, color_idx: int):
	var color = BallColorsScript.get_color(color_idx)
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
		var tube_x = grid_offset.x + i * (tube_width + 12)
		var tube_rect = Rect2(tube_x, grid_offset.y, tube_width, tube_height)
		
		if tube_rect.has_point(pos):
			_on_tube_tapped(i)
			return

func _on_tube_tapped(tube_idx: int):
	if selected_tube < 0:
		# Selecting a tube
		var contents = game_state.tubes[tube_idx]
		if contents.size() > 0 and not game_state.is_tube_complete(tube_idx):
			selected_tube = tube_idx
	else:
		# Attempting to place ball
		if tube_idx == selected_tube:
			# Deselect
			selected_tube = -1
		elif game_state.can_move(selected_tube, tube_idx):
			# Valid move - animate it
			_start_move_animation(selected_tube, tube_idx)
			selected_tube = -1
		else:
			# Invalid move - shake target
			shake_tubes[tube_idx] = 0.3

func _start_move_animation(from: int, to: int):
	move_animating = true
	anim_from = from
	anim_to = to
	anim_progress = 0.0
	anim_ball_color = game_state.tubes[from][-1]

func _process(delta):
	if is_showing_level_select:
		return
	
	if move_animating:
		var speed = 2.0
		anim_progress += delta * speed
		if anim_progress >= 1.0:
			anim_progress = 1.0
			game_state.move_ball(anim_from, anim_to)
			move_animating = false
			anim_ball_color = -1
			
			# Check for completed tube
			if game_state.is_tube_complete(anim_to):
				sparkle_tubes.append(anim_to)
		
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
		game_state.undo()

func restart_level():
	if game_state:
		_load_generated_level(current_level_idx)

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
