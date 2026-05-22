extends Control

# Level Select Screen — grid of level buttons with star ratings

var LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
var ProgressionScript = preload("res://scripts/Progression.gd")

var progression = null

var cols: int = 5
var cell_size: float = 70.0
var cell_gap: float = 8.0
var grid_start_x: float = 0.0
var grid_start_y: float = 140.0

var current_pack_index: int = 0
var scroll_offset: float = 0.0
var max_scroll: float = 0.0
var dragging: bool = false
var drag_start_y: float = 0.0
var scroll_velocity: float = 0.0

var pack_label = null
var level_buttons: Array = []
var back_button = null

var main_ref = null  # Reference to main game controller

func _ready():
	var viewport = get_viewport().get_visible_rect().size
	
	# Title
	var title = _make_label("Ball Sort", 28, Color("#e8d5a3"), Vector2(0, 30), Vector2(viewport.x, 50))
	add_child(title)
	
	# Pack name
	pack_label = _make_label("", 16, Color("#888888"), Vector2(0, 70), Vector2(viewport.x, 30))
	add_child(pack_label)
	
	# Back button
	back_button = _make_button("← Back", Vector2(16, 16), _on_back)
	add_child(back_button)
	
	# Grid dimensions
	cols = max(4, int(viewport.x / (cell_size + cell_gap)))
	
	# Load progression
	progression = ProgressionScript.new()
	
	# Show first pack
	current_pack_index = 0
	_show_pack(current_pack_index)

func _show_pack(pack_idx: int):
	# Clear old buttons
	for btn in level_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	level_buttons.clear()
	
	var packs = LevelGeneratorScript.get_packs()
	if pack_idx < 0 or pack_idx >= packs.size():
		return
	
	var pack = packs[pack_idx]
	var start_level = 0
	for i in range(pack_idx):
		start_level += packs[i].levels
	
	pack_label.text = pack.name + " Pack  (" + str(start_level + 1) + "-" + str(start_level + pack.levels) + ")"
	
	var viewport = get_viewport().get_visible_rect().size
	
	# Calculate grid
	var total_width = cols * (cell_size + cell_gap) - cell_gap
	grid_start_x = (viewport.x - total_width) / 2
	
	# Create level buttons
	for i in range(pack.levels):
		var level_idx = start_level + i
		var col = i % cols
		var row = i / cols
		
		var x = grid_start_x + col * (cell_size + cell_gap)
		var y = grid_start_y + row * (cell_size + cell_gap)
		
		var btn = _make_level_button(level_idx, Vector2(x, y))
		add_child(btn)
		level_buttons.append(btn)
	
	# Calculate max scroll
	var rows = ceili(float(pack.levels) / float(cols))
	var content_height = rows * (cell_size + cell_gap) + 40
	var visible_height = viewport.y - grid_start_y - 20
	max_scroll = max(0, content_height - visible_height)
	
	# Nav buttons (prev/next pack)
	if pack_idx > 0:
		var prev_btn = _make_button("◀ " + packs[pack_idx - 1].name, Vector2(16, viewport.y - 50), _on_prev_pack)
		add_child(prev_btn)
		level_buttons.append(prev_btn)
	
	if pack_idx < packs.size() - 1:
		var next_btn = _make_button(packs[pack_idx + 1].name + " ▶", Vector2(viewport.x - 200, viewport.y - 50), _on_next_pack)
		add_child(next_btn)
		level_buttons.append(next_btn)

func _make_level_button(level_idx: int, pos: Vector2) -> Control:
	var container = Control.new()
	container.position = pos
	container.size = Vector2(cell_size, cell_size + 20)
	
	var is_unlocked = progression.is_level_unlocked(level_idx)
	var stars = progression.get_stars(level_idx)
	var level_num = level_idx + 1
	
	# Background
	var bg = ColorRect.new()
	bg.size = Vector2(cell_size, cell_size)
	bg.color = Color("#1A1A2E") if is_unlocked else Color("#111122")
	container.add_child(bg)
	
	# Border
	var border = ColorRect.new()
	border.position = Vector2(-1, -1)
	border.size = Vector2(cell_size + 2, cell_size + 2)
	border.color = Color("#2A2A4E") if is_unlocked else Color("#1A1A20")
	container.add_child(border)
	
	if is_unlocked:
		# Level number
		var label = Label.new()
		label.text = str(level_num)
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color("#e8d5a3"))
		label.position = Vector2(0, cell_size * 0.2)
		label.size = Vector2(cell_size, cell_size * 0.5)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(label)
		
		# Stars
		if stars > 0:
			var stars_text = ""
			for s in range(stars):
				stars_text += "★"
			var star_label = Label.new()
			star_label.text = stars_text
			star_label.add_theme_font_size_override("font_size", 12)
			star_label.add_theme_color_override("font_color", Color("#e8d5a3"))
			star_label.position = Vector2(0, cell_size - 16)
			star_label.size = Vector2(cell_size, 16)
			star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			container.add_child(star_label)
		
		# Click handler
		container.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_level_selected(level_idx)
		)
		container.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		# Lock icon
		var lock = Label.new()
		lock.text = "🔒"
		lock.add_theme_font_size_override("font_size", 24)
		lock.position = Vector2(0, cell_size * 0.25)
		lock.size = Vector2(cell_size, cell_size * 0.5)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(lock)
	
	return container

func _on_level_selected(level_idx: int):
	if main_ref:
		main_ref.start_level(level_idx)

func _on_back():
	if main_ref:
		main_ref.show_level_select()

func _on_prev_pack():
	current_pack_index -= 1
	_show_pack(current_pack_index)

func _on_next_pack():
	current_pack_index += 1
	_show_pack(current_pack_index)

func _make_label(text: String, font_size: int, color: Color, pos: Vector2, size: Vector2) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.position = pos
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _make_button(text: String, pos: Vector2, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color("#e8d5a3"))
	btn.add_theme_stylebox_override("normal", _make_style())
	btn.add_theme_stylebox_override("hover", _make_style(Color("#2A2A4E")))
	btn.add_theme_stylebox_override("pressed", _make_style(Color("#1A1A2E")))
	btn.pressed.connect(callback)
	btn.size = Vector2(100, 28)
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

func _draw():
	var viewport = get_viewport().get_visible_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport), Color("#0D0D1A"))

func _input(event):
	# Scroll with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_scroll(-30)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_scroll(30)

func _scroll(amount: float):
	scroll_offset = clamp(scroll_offset + amount, 0, max_scroll)
	for btn in level_buttons:
		if is_instance_valid(btn):
			btn.position.y = btn.position.y - amount
