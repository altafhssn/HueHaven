extends RefCounted

# Game State — manages tube contents, moves, undo, win detection

var level_data: Dictionary
var tubes: Array  # Array of Arrays — each inner array holds color indices (bottom->top)
var move_count: int = 0
var undo_stack: Array  # Array of [from_idx, to_idx] pairs
var completed_tubes: Array  # indices of completed tubes

func _init(data: Dictionary):
	level_data = data
	tubes = []
	for t in data.contents:
		var tube = t.duplicate()
		tubes.append(tube)
	move_count = 0
	undo_stack = []
	completed_tubes = []
	_update_completed_tubes()

func _update_completed_tubes():
	completed_tubes.clear()
	var capacity = level_data.capacity
	for i in range(tubes.size()):
		if _is_tube_monochrome(i, capacity):
			completed_tubes.append(i)

func _is_tube_monochrome(idx: int, capacity: int) -> bool:
	var t = tubes[idx]
	if t.size() < capacity:
		return false
	var first = t[0]
	for c in t:
		if c != first:
			return false
	return true

# Check if ball can move from source tube to target tube
func can_move(from_idx: int, to_idx: int) -> bool:
	if from_idx == to_idx:
		return false
	
	var src = tubes[from_idx]
	var dst = tubes[to_idx]
	var capacity = level_data.capacity
	
	# Source must have balls
	if src.size() == 0:
		return false
	
	# Target must not be full
	if dst.size() >= capacity:
		return false
	
	# Target must be empty OR top color matches source top
	var src_top = src[-1]
	if dst.size() > 0:
		var dst_top = dst[-1]
		if src_top != dst_top:
			return false
	
	return true

# Execute a move
func move_ball(from_idx: int, to_idx: int) -> bool:
	if not can_move(from_idx, to_idx):
		return false
	
	var src = tubes[from_idx]
	var dst = tubes[to_idx]
	
	# Pop from source
	var ball = src.pop_back()
	
	# Push to target
	dst.append(ball)
	
	# Record undo
	undo_stack.append([from_idx, to_idx])
	move_count += 1
	
	# Update completed tubes
	_update_completed_tubes()
	
	return true

# Undo last move
func undo() -> bool:
	if undo_stack.size() == 0:
		return false
	
	var move = undo_stack.pop_back()
	var from_idx = move[0]
	var to_idx = move[1]
	
	var dst = tubes[to_idx]
	var ball = dst.pop_back()
	
	var src = tubes[from_idx]
	src.append(ball)
	
	move_count = max(0, move_count - 1)
	
	# Update completed tubes
	_update_completed_tubes()
	
	return true

# Check if a tube is complete (full and monochrome)
func is_tube_complete(idx: int) -> bool:
	return completed_tubes.has(idx)

# Check if all tubes are complete (level won)
func is_level_won() -> bool:
	var capacity = level_data.capacity
	for i in range(tubes.size()):
		if not _is_tube_monochrome(i, capacity):
			return false
	return true

# Get top ball color of a tube (returns -1 if empty)
func get_top_color(tube_idx: int) -> int:
	var t = tubes[tube_idx]
	if t.size() == 0:
		return -1
	return t[-1]

# Count balls of a specific color in a tube
func count_color_in_tube(tube_idx: int, color_idx: int) -> int:
	var count = 0
	for c in tubes[tube_idx]:
		if c == color_idx:
			count += 1
	return count

# Reset to initial state
func reset():
	var data = level_data.duplicate(true)
	tubes = []
	for t in data.contents:
		tubes.append(t.duplicate())
	move_count = 0
	undo_stack = []
	completed_tubes = []
	_update_completed_tubes()

# Get star rating based on moves vs par
func get_star_rating() -> int:
	var par = level_data.par_moves
	if move_count <= par:
		return 3
	elif move_count <= par * 2:
		return 2
	else:
		return 1
