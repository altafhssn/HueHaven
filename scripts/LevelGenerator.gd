extends RefCounted

# Level Generator — generates solvable Ball Sort puzzles
# Algorithm: Start with sorted tubes, then perform random valid moves to scramble
# This guarantees the puzzle has at least one solution (reverse the moves)

# Difficulty configs.
# `empty_tubes` is the key difficulty knob — fewer empties means much tighter solve space.
# `min_disorder` is the minimum total inter-ball transitions required after scramble
# (a monochrome tube contributes 0; a fully alternating tube contributes capacity-1).
const DIFFICULTY_PRESETS = {
	"very_easy":  { "colors": 3,  "empty_tubes": 2, "capacity": 4, "scramble_moves": 30,  "par_mult": 1.4, "min_disorder": 4,  "specials": [] },
	"easy":       { "colors": 4,  "empty_tubes": 2, "capacity": 4, "scramble_moves": 50,  "par_mult": 1.5, "min_disorder": 7,  "specials": [] },
	"medium":     { "colors": 5,  "empty_tubes": 2, "capacity": 4, "scramble_moves": 80,  "par_mult": 1.6, "min_disorder": 11, "specials": ["rainbow"] },
	"hard":       { "colors": 6,  "empty_tubes": 1, "capacity": 4, "scramble_moves": 120, "par_mult": 1.8, "min_disorder": 14, "specials": ["rainbow", "stone"] },
	"expert":     { "colors": 8,  "empty_tubes": 1, "capacity": 4, "scramble_moves": 180, "par_mult": 2.0, "min_disorder": 18, "specials": ["rainbow", "stone", "magnet", "hourglass"] },
	"master":     { "colors": 10, "empty_tubes": 1, "capacity": 4, "scramble_moves": 250, "par_mult": 2.2, "min_disorder": 22, "specials": ["rainbow", "stone", "magnet", "bomb", "hourglass"] },
}

# Level pack definitions
const LEVEL_PACKS = [
	{ "name": "Tutorial",   "levels": 10,  "difficulty": "very_easy", "min_colors": 3,  "max_colors": 3 },
	{ "name": "Easy",       "levels": 40,  "difficulty": "easy",      "min_colors": 4,  "max_colors": 4 },
	{ "name": "Medium",     "levels": 60,  "difficulty": "medium",    "min_colors": 5,  "max_colors": 5 },
	{ "name": "Hard",       "levels": 100, "difficulty": "hard",      "min_colors": 6,  "max_colors": 6 },
	{ "name": "Expert",     "levels": 150, "difficulty": "expert",    "min_colors": 7,  "max_colors": 8 },
	{ "name": "Master",     "levels": 140, "difficulty": "master",    "min_colors": 8,  "max_colors": 10 },
]

const TOTAL_LEVELS = 500

# Generate a level by global index (1-based)
static func generate_level(level_idx: int) -> Dictionary:
	var pack = _get_pack_for_level(level_idx)
	if pack == null:
		pack = LEVEL_PACKS[-1]  # Fallback to last pack

	var preset = DIFFICULTY_PRESETS[pack.difficulty]
	var seed_val = level_idx * 7919  # Prime multiplier for deterministic generation
	
	# Vary colors within pack range
	var color_range = pack.max_colors - pack.min_colors
	var colors = pack.min_colors + (level_idx % (color_range + 1))
	
	var min_disorder: int = preset.get("min_disorder", 0)
	var level = _generate_puzzle(colors, preset.capacity, preset.empty_tubes, preset.scramble_moves, preset.par_mult, min_disorder, seed_val)

	# Inject one special every few levels for tiers that support them
	var pool: Array = preset.get("specials", [])
	if not pool.is_empty() and (level_idx % 3) != 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_val + 13
		_inject_specials(level, pool, rng)

	return level

# Generate a puzzle with given parameters
static func _generate_puzzle(colors: int, capacity: int, empty_tubes: int, scramble_moves: int, par_mult: float, min_disorder: int, seed_val: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	# Total tubes = colors + empty_tubes
	var total_tubes = colors + empty_tubes
	
	# Start with sorted tubes: each tube has `capacity` balls of the same color
	var tubes = []
	for c in range(colors):
		var tube = []
		for _b in range(capacity):
			tube.append(c)
		tubes.append(tube)
	
	# Add empty tubes
	for _e in range(empty_tubes):
		tubes.append([])
	
	# Scramble by performing random valid moves
	# Constraints to avoid trivial back-and-forth:
	#   * never reverse the immediately previous move
	#   * never make a move that completes a tube (would let us re-arrive at sorted)
	#   * never move from a tube that just received its previous ball
	var actual_moves = 0
	var attempts = 0
	# Allow extra attempts; we keep going past `scramble_moves` until disorder threshold is hit.
	var max_attempts = max(scramble_moves * 15, 400)
	var last_from := -1
	var last_to := -1

	while attempts < max_attempts:
		# Stop once we've made enough moves AND scattered the balls enough
		if actual_moves >= scramble_moves and _measure_disorder(tubes) >= min_disorder:
			break
		attempts += 1

		# Pick a random non-empty source tube — but not the tube that just
		# received a ball (forbids immediate reversal). Source CAN be a
		# complete monochrome tube — that's the whole point of scrambling.
		var from_candidates = []
		for i in range(total_tubes):
			if tubes[i].size() == 0:
				continue
			if i == last_to:
				continue
			from_candidates.append(i)
		if from_candidates.is_empty():
			for i in range(total_tubes):
				if tubes[i].size() > 0:
					from_candidates.append(i)
		if from_candidates.is_empty():
			break

		var from_idx = from_candidates[rng.randi() % from_candidates.size()]
		var src_top = tubes[from_idx][-1]

		# Pick a valid destination — never one that would complete the tube
		# and (if possible) never the previous source (immediate reverse).
		var to_candidates = []
		for i in range(total_tubes):
			if i == from_idx:
				continue
			if tubes[i].size() >= capacity:
				continue
			if tubes[i].size() > 0 and tubes[i][-1] != src_top:
				continue
			# Would this move complete a monochrome tube?
			if tubes[i].size() == capacity - 1 and _would_complete(tubes[i], src_top, capacity):
				continue
			# Avoid immediate reverse if a non-reverse option exists
			if i == last_from:
				continue
			to_candidates.append(i)
		if to_candidates.is_empty():
			# Relax: allow reverse but still no completion
			for i in range(total_tubes):
				if i == from_idx or tubes[i].size() >= capacity:
					continue
				if tubes[i].size() > 0 and tubes[i][-1] != src_top:
					continue
				if tubes[i].size() == capacity - 1 and _would_complete(tubes[i], src_top, capacity):
					continue
				to_candidates.append(i)
		if to_candidates.is_empty():
			continue

		var to_idx = to_candidates[rng.randi() % to_candidates.size()]
		var ball = tubes[from_idx].pop_back()
		tubes[to_idx].append(ball)
		last_from = from_idx
		last_to = to_idx
		actual_moves += 1

	
	# Calculate par moves
	var par_moves = max(1, ceili(scramble_moves * par_mult * (1.0 + float(colors) / 10.0)))

	# Deep copy tube contents
	var contents = []
	for t in tubes:
		var tube_copy = []
		for ball in t:
			tube_copy.append(ball)
		contents.append(tube_copy)

	return {
		"colors": colors,
		"capacity": capacity,
		"contents": contents,
		"par_moves": par_moves,
		"bombs": false,
		"specials": [],
	}

# Inject a single special ball by transmuting one existing regular ball.
# `pool` lists special types eligible to spawn. Idempotent on the input rng.
static func _inject_specials(level: Dictionary, pool: Array, rng: RandomNumberGenerator) -> void:
	if pool.is_empty():
		return
	var contents = level.contents
	var capacity = int(level.capacity)

	# Pick a special type for this level
	var stype: String = pool[rng.randi() % pool.size()]

	# Find candidate ball slots: avoid the topmost ball of a tube (would dominate
	# the puzzle), and never replace inside an already-empty tube.
	var candidates := []  # [tube_idx, ball_idx, color]
	for ti in range(contents.size()):
		var tube = contents[ti]
		for bi in range(tube.size() - 1):  # exclude top
			candidates.append([ti, bi, int(tube[bi])])
	if candidates.is_empty():
		# Fall back to top ball if needed
		for ti in range(contents.size()):
			var tube = contents[ti]
			if tube.size() > 0:
				candidates.append([ti, tube.size() - 1, int(tube[-1])])
	if candidates.is_empty():
		return

	var pick = candidates[rng.randi() % candidates.size()]
	var ti: int = pick[0]
	var bi: int = pick[1]
	var color: int = pick[2]

	var special_ball: Dictionary
	match stype:
		"bomb":
			special_ball = { "type": "bomb", "color": color, "meta": 12 + (rng.randi() % 6) }
		"rainbow":
			special_ball = { "type": "rainbow", "color": -1, "meta": null }
		"stone":
			special_ball = { "type": "stone", "color": color, "meta": null }
			# Stones must sit at the bottom to be solvable; relocate
			contents[ti].remove_at(bi)
			contents[ti].insert(0, special_ball)
			return
		"magnet":
			special_ball = { "type": "magnet", "color": color, "meta": null }
		"hourglass":
			special_ball = { "type": "hourglass", "color": -1, "meta": null }
		_:
			return

	contents[ti][bi] = special_ball
	level.specials = level.get("specials", [])
	level.specials.append(stype)

# Check if a tube is full and monochrome (completed)
static func _is_tube_complete(tube: Array, capacity: int) -> bool:
	if tube.size() < capacity:
		return false
	var first = tube[0]
	for ball in tube:
		if ball != first:
			return false
	return true

# Count adjacent-pair transitions across all tubes (higher = more scattered).
# A monochrome tube contributes 0; a fully alternating tube contributes capacity-1.
static func _measure_disorder(tubes: Array) -> int:
	var total := 0
	for tube in tubes:
		for i in range(1, tube.size()):
			if tube[i] != tube[i - 1]:
				total += 1
	return total

# Would placing `ball` on this tube complete it as a monochrome stack?
static func _would_complete(tube: Array, ball, capacity: int) -> bool:
	if tube.size() + 1 != capacity:
		return false
	for b in tube:
		if b != ball:
			return false
	return true


# Get which pack a level belongs to
static func _get_pack_for_level(level_idx: int) -> Dictionary:
	# level_idx is 0-based
	var cumulative = 0
	for pack in LEVEL_PACKS:
		cumulative += pack.levels
		if level_idx < cumulative:
			return pack
	return LEVEL_PACKS[-1]  # Last pack

# Get pack info for a level
static func get_pack_info(level_idx: int) -> Dictionary:
	var cumulative = 0
	for pack in LEVEL_PACKS:
		cumulative += pack.levels
		if level_idx < cumulative:
			return {
				"name": pack.name,
				"level_in_pack": level_idx - (cumulative - pack.levels),
				"pack_start": cumulative - pack.levels,
				"pack_levels": pack.levels,
			}
	return {
		"name": LEVEL_PACKS[-1].name,
		"level_in_pack": level_idx - (cumulative - LEVEL_PACKS[-1].levels),
		"pack_start": cumulative - LEVEL_PACKS[-1].levels,
		"pack_levels": LEVEL_PACKS[-1].levels,
	}

static func get_total_levels() -> int:
	return TOTAL_LEVELS

static func get_packs() -> Array:
	return LEVEL_PACKS.duplicate(true)
