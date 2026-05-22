extends RefCounted

# Game State — tubes, moves, undo, win detection, specials.
#
# Ball storage: each entry in a tube is either an `int` (regular color index)
# or a `Dictionary` of the form { "type": <special>, "color": <int>, "meta": <variant> }.
# Specials: "bomb" (meta = remaining moves), "rainbow" (color = -1),
# "stone" (immovable), "magnet" (pulls same-color tops on placement),
# "hourglass" (refills bomb timers when placed).

const SPECIAL_BOMB := "bomb"
const SPECIAL_RAINBOW := "rainbow"
const SPECIAL_STONE := "stone"
const SPECIAL_MAGNET := "magnet"
const SPECIAL_HOURGLASS := "hourglass"

var level_data: Dictionary
var tubes: Array  # Array of Arrays — each inner array holds ball entries (bottom->top)
var move_count: int = 0
var undo_stack: Array
var completed_tubes: Array

# Events triggered by side effects of move_ball — Main reads & clears these.
var pending_effects: Array = []  # entries like { "type": "bomb_explode", "tube": int }

func _init(data: Dictionary):
	level_data = data
	tubes = []
	for t in data.contents:
		var tube := []
		for b in t:
			tube.append(_clone_ball(b))
		tubes.append(tube)
	move_count = 0
	undo_stack = []
	completed_tubes = []
	pending_effects = []
	_update_completed_tubes()

# --- Ball helpers ---

static func _clone_ball(b):
	if b is Dictionary:
		return b.duplicate(true)
	return b

static func is_special(b) -> bool:
	return b is Dictionary

static func get_ball_color(b) -> int:
	if b is Dictionary:
		return int(b.get("color", -1))
	return int(b)

static func get_special_type(b) -> String:
	if b is Dictionary:
		return String(b.get("type", ""))
	return ""

static func is_stone(b) -> bool:
	return get_special_type(b) == SPECIAL_STONE

static func is_rainbow(b) -> bool:
	return get_special_type(b) == SPECIAL_RAINBOW

# --- Completion ---

func _update_completed_tubes() -> void:
	completed_tubes.clear()
	var capacity = level_data.capacity
	for i in range(tubes.size()):
		if _is_tube_monochrome(i, capacity):
			completed_tubes.append(i)

func _is_tube_monochrome(idx: int, capacity: int) -> bool:
	var t = tubes[idx]
	if t.size() < capacity:
		return false
	var ref_color := -1
	for b in t:
		if is_stone(b):
			continue
		var c := get_ball_color(b)
		if is_rainbow(b):
			continue  # wildcard
		if ref_color < 0:
			ref_color = c
		elif c != ref_color:
			return false
	# A tube of all stones is not a completion.
	if ref_color < 0:
		return false
	return true

# --- Movement ---

func can_move(from_idx: int, to_idx: int) -> bool:
	if from_idx == to_idx:
		return false

	var src = tubes[from_idx]
	var dst = tubes[to_idx]
	var capacity = level_data.capacity

	if src.size() == 0:
		return false
	if dst.size() >= capacity:
		return false

	var src_top = src[-1]
	if is_stone(src_top):
		return false

	if dst.size() > 0:
		var dst_top = dst[-1]
		if is_stone(dst_top):
			return false
		# Rainbow wildcards on either side accept any color
		if not is_rainbow(src_top) and not is_rainbow(dst_top):
			if get_ball_color(src_top) != get_ball_color(dst_top):
				return false

	return true

func move_ball(from_idx: int, to_idx: int) -> bool:
	if not can_move(from_idx, to_idx):
		return false

	# Always snapshot the full state — keeps undo bulletproof under specials.
	var snapshot := { "tubes_before": _snapshot_tubes() }

	var src = tubes[from_idx]
	var dst = tubes[to_idx]

	var ball = src.pop_back()
	dst.append(ball)

	# Apply specials triggered by this placement
	_on_ball_placed(ball, to_idx)

	# Tick bomb timers on every move
	_tick_bombs()

	undo_stack.append(snapshot)
	move_count += 1
	_update_completed_tubes()
	return true

func _on_ball_placed(ball, to_idx: int) -> void:
	var stype := get_special_type(ball)
	if stype == SPECIAL_MAGNET:
		_resolve_magnet(to_idx, get_ball_color(ball))
		pending_effects.append({ "type": "magnet_pull", "tube": to_idx })
	elif stype == SPECIAL_HOURGLASS:
		_refill_bombs(5)
		pending_effects.append({ "type": "hourglass_use", "tube": to_idx })

func _resolve_magnet(to_idx: int, color: int) -> void:
	if color < 0:
		return
	var capacity = level_data.capacity
	var changed := true
	while changed and tubes[to_idx].size() < capacity:
		changed = false
		for i in range(tubes.size()):
			if i == to_idx:
				continue
			var src = tubes[i]
			if src.size() == 0:
				continue
			var top = src[-1]
			if is_stone(top) or is_special(top):
				continue
			if get_ball_color(top) == color:
				tubes[to_idx].append(src.pop_back())
				changed = true
				if tubes[to_idx].size() >= capacity:
					return

func _tick_bombs() -> void:
	for i in range(tubes.size()):
		var tube = tubes[i]
		for j in range(tube.size()):
			var b = tube[j]
			if get_special_type(b) == SPECIAL_BOMB:
				b.meta = max(0, int(b.get("meta", 0)) - 1)
				if b.meta <= 0:
					_explode_bomb(i, j)
					pending_effects.append({ "type": "bomb_explode", "tube": i })
					return  # mutated tubes; one explosion per move keeps things sane

func _explode_bomb(tube_idx: int, ball_idx: int) -> void:
	# Remove the bomb and scramble the rest of that tube's balls.
	var tube = tubes[tube_idx]
	tube.remove_at(ball_idx)
	# Shuffle remaining balls (deterministic via RNG seeded by move_count + tube_idx)
	var rng := RandomNumberGenerator.new()
	rng.seed = (move_count + 1) * 31 + tube_idx
	for k in range(tube.size() - 1, 0, -1):
		var swap_idx = rng.randi() % (k + 1)
		var tmp = tube[k]
		tube[k] = tube[swap_idx]
		tube[swap_idx] = tmp

func _refill_bombs(add_moves: int) -> void:
	for tube in tubes:
		for b in tube:
			if get_special_type(b) == SPECIAL_BOMB:
				b.meta = int(b.get("meta", 0)) + add_moves

func _snapshot_tubes() -> Array:
	var snap := []
	for t in tubes:
		var s := []
		for b in t:
			s.append(_clone_ball(b))
		snap.append(s)
	return snap

# --- Undo ---

func undo() -> bool:
	if undo_stack.size() == 0:
		return false

	var move = undo_stack.pop_back()
	tubes = move.tubes_before

	move_count = max(0, move_count - 1)
	_update_completed_tubes()
	return true

# --- Queries ---

func is_tube_complete(idx: int) -> bool:
	return completed_tubes.has(idx)

func is_level_won() -> bool:
	var capacity = level_data.capacity
	for i in range(tubes.size()):
		var t = tubes[i]
		# A non-empty tube must be monochrome and full
		if t.size() > 0 and not _is_tube_monochrome(i, capacity):
			# Allow all-stone tubes (rare) to pass
			var all_stone := true
			for b in t:
				if not is_stone(b):
					all_stone = false
					break
			if not all_stone:
				return false
	return true

# Returns true if at least one legal move exists
func has_any_move() -> bool:
	var n = tubes.size()
	for from_idx in range(n):
		if tubes[from_idx].size() == 0:
			continue
		if _is_tube_monochrome(from_idx, level_data.capacity):
			continue
		for to_idx in range(n):
			if can_move(from_idx, to_idx):
				return true
	return false

func get_top_color(tube_idx: int) -> int:
	var t = tubes[tube_idx]
	if t.size() == 0:
		return -1
	return get_ball_color(t[-1])

func reset() -> void:
	var data = level_data.duplicate(true)
	tubes = []
	for t in data.contents:
		var tube := []
		for b in t:
			tube.append(_clone_ball(b))
		tubes.append(tube)
	move_count = 0
	undo_stack = []
	completed_tubes = []
	pending_effects = []
	_update_completed_tubes()

# --- Hint ---

func find_hint() -> Array:
	var capacity = level_data.capacity
	var n = tubes.size()
	var best := [-1, -1]
	var best_score := -999

	for from_idx in range(n):
		var src = tubes[from_idx]
		if src.size() == 0:
			continue
		if _is_tube_monochrome(from_idx, capacity):
			continue
		var src_top = src[-1]
		if is_stone(src_top):
			continue
		var src_color := get_ball_color(src_top)

		for to_idx in range(n):
			if to_idx == from_idx:
				continue
			if not can_move(from_idx, to_idx):
				continue

			var dst = tubes[to_idx]
			var score := 0

			if dst.size() > 0:
				score += 10
				var all_same := true
				for b in dst:
					if is_stone(b):
						continue
					var c := get_ball_color(b)
					if c != src_color and not is_rainbow(b):
						all_same = false
						break
				if all_same:
					score += 5
					if dst.size() == capacity - 1:
						score += 100

			if src.size() == 1:
				score += 3
			if dst.size() == 0 and src.size() > 1:
				score -= 5

			if score > best_score:
				best_score = score
				best = [from_idx, to_idx]

	return best

# --- Star rating ---

func get_star_rating() -> int:
	var par = level_data.par_moves
	if move_count <= par:
		return 3
	elif move_count <= par * 2:
		return 2
	else:
		return 1

# Consume queued visual effect events (Main reads + clears these)
func take_effects() -> Array:
	var e = pending_effects
	pending_effects = []
	return e
