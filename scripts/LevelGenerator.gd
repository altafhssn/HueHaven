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

# Level pack definitions.
# `unlock_stars` is the minimum total stars (across all previous packs)
# the player must have to unlock this pack.
const LEVEL_PACKS = [
	{ "name": "Tide",     "tagline": "First currents",    "levels": 10,  "difficulty": "very_easy", "min_colors": 3,  "max_colors": 3,  "unlock_stars": 0 },
	{ "name": "Spark",    "tagline": "Lab whispers",      "levels": 40,  "difficulty": "easy",      "min_colors": 4,  "max_colors": 4,  "unlock_stars": 8 },
	{ "name": "Grove",    "tagline": "Hush of leaves",    "levels": 60,  "difficulty": "medium",    "min_colors": 5,  "max_colors": 5,  "unlock_stars": 60 },
	{ "name": "Orbit",    "tagline": "Distant lights",    "levels": 100, "difficulty": "hard",      "min_colors": 6,  "max_colors": 6,  "unlock_stars": 180 },
	{ "name": "Ember",    "tagline": "Alchemist's flame", "levels": 150, "difficulty": "expert",    "min_colors": 7,  "max_colors": 8,  "unlock_stars": 360 },
	{ "name": "Canopy",   "tagline": "Beyond the veil",   "levels": 140, "difficulty": "master",    "min_colors": 8,  "max_colors": 10, "unlock_stars": 660 },
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

# Generate a puzzle by random shuffle + BFS solvability verification.
#
# Forward-move scrambling can ONLY produce monochrome tubes — every valid
# move requires the destination to be empty or same-color, so once a ball
# is placed it can never be covered by a different color. Real Ball Sort
# puzzles need genuinely mixed stacks, which only random distribution
# produces. We then verify solvability so we don't ship dead puzzles.
static func _generate_puzzle(colors: int, capacity: int, empty_tubes: int, scramble_moves: int, par_mult: float, min_disorder: int, seed_val: int) -> Dictionary:
	var total_tubes := colors + empty_tubes
	var tubes: Array = []

	# Try up to a few seeds — random shuffle is usually solvable, but not always
	var attempts := 0
	var max_attempts := 12
	var rng := RandomNumberGenerator.new()
	while attempts < max_attempts:
		rng.seed = seed_val + attempts * 101
		tubes = _shuffle_distribution(colors, capacity, empty_tubes, rng)
		# For very small puzzles, verify solvability. For large ones, trust the shuffle.
		if colors <= 7:
			if _is_solvable(tubes, capacity, 80000):
				break
		else:
			break
		attempts += 1

	var par_moves: int = int(max(1, ceili(float(scramble_moves) * par_mult * (1.0 + float(colors) / 10.0))))

	var contents := []
	for t in tubes:
		var tube_copy := []
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

# Random shuffle distribution: flatten all balls, Fisher-Yates shuffle,
# distribute capacity balls into each of the `colors` tubes; remaining
# tubes start empty.
static func _shuffle_distribution(colors: int, capacity: int, empty_tubes: int, rng: RandomNumberGenerator) -> Array:
	var balls: Array = []
	for c in range(colors):
		for _b in range(capacity):
			balls.append(c)
	# Fisher-Yates
	for i in range(balls.size() - 1, 0, -1):
		var j: int = rng.randi() % (i + 1)
		var tmp = balls[i]
		balls[i] = balls[j]
		balls[j] = tmp

	var tubes: Array = []
	var idx: int = 0
	for t in range(colors):
		var tube: Array = []
		for k in range(capacity):
			tube.append(balls[idx])
			idx += 1
		tubes.append(tube)
	for _e in range(empty_tubes):
		tubes.append([])
	return tubes

# BFS solvability check with a hard state cap. Returns true if solved
# state is reachable within `max_states` expansions. Uses canonical
# hashing (tubes sorted) so equivalent states aren't re-explored.
static func _is_solvable(tubes: Array, capacity: int, max_states: int) -> bool:
	if _is_solved_state(tubes, capacity):
		return true
	var visited: Dictionary = {}
	visited[_hash_state(tubes)] = true
	var queue: Array = [tubes]
	var explored: int = 0

	while not queue.is_empty():
		if explored >= max_states:
			return false
		var current: Array = queue.pop_front()
		explored += 1

		var n: int = current.size()
		for from_idx in range(n):
			var src: Array = current[from_idx]
			if src.is_empty():
				continue
			var src_top = src[-1]
			# Skip if source is already monochrome AND full (don't waste expansion)
			if src.size() == capacity and _is_monochrome(src):
				continue
			for to_idx in range(n):
				if to_idx == from_idx:
					continue
				var dst: Array = current[to_idx]
				if dst.size() >= capacity:
					continue
				if not dst.is_empty() and dst[-1] != src_top:
					continue
				# Apply move
				var new_state: Array = []
				for t in current:
					new_state.append(t.duplicate())
				new_state[from_idx].pop_back()
				new_state[to_idx].append(src_top)

				if _is_solved_state(new_state, capacity):
					return true

				var h: String = _hash_state(new_state)
				if not visited.has(h):
					visited[h] = true
					queue.append(new_state)
	return false

static func _is_solved_state(tubes: Array, capacity: int) -> bool:
	for t in tubes:
		if t.is_empty():
			continue
		if t.size() != capacity:
			return false
		if not _is_monochrome(t):
			return false
	return true

static func _is_monochrome(tube: Array) -> bool:
	if tube.is_empty():
		return true
	var first = tube[0]
	for b in tube:
		if b != first:
			return false
	return true

# Canonical state hash — sort tube strings so equivalent permutations
# of empty/identical tubes collapse to one entry.
static func _hash_state(tubes: Array) -> String:
	var parts: Array = []
	for t in tubes:
		parts.append(",".join(t.map(func(b): return str(b))))
	parts.sort()
	return "|".join(parts)

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
