extends RefCounted

# Level data definitions — hand-crafted test levels for prototyping
# Level format:
#   colors: number of distinct colors
#   capacity: balls per tube
#   contents: array of tubes, each tube = array of color indices (bottom->top)
#   par_moves: optimal move count for 3-star rating
#   bombs: false
#   specials: []

const LEVELS = [
	# Level 1 — Very easy (3 colors, 4 tubes)
	{
		"colors": 3,
		"capacity": 4,
		"contents": [
			[0, 1, 0, 2],   # Red, Blue, Red, Green
			[1, 2, 1, 0],   # Blue, Green, Blue, Red
			[2, 0, 2, 1],   # Green, Red, Green, Blue
			[],              # Empty
			[],              # Empty
		],
		"par_moves": 10,
		"bombs": false,
		"specials": [],
	},
	# Level 2 — Easy (3 colors, 4 tubes)
	{
		"colors": 3,
		"capacity": 4,
		"contents": [
			[0, 0, 1, 2],
			[1, 2, 2, 0],
			[2, 1, 0, 1],
			[],
			[],
		],
		"par_moves": 10,
		"bombs": false,
		"specials": [],
	},
	# Level 3 — Easy (4 colors, 5 tubes)
	{
		"colors": 4,
		"capacity": 4,
		"contents": [
			[0, 1, 2, 0],
			[3, 2, 1, 3],
			[1, 0, 3, 2],
			[2, 3, 0, 1],
			[],
		],
		"par_moves": 14,
		"bombs": false,
		"specials": [],
	},
	# Level 4 — Medium (4 colors, 6 tubes)
	{
		"colors": 4,
		"capacity": 4,
		"contents": [
			[0, 1, 2, 3],
			[3, 2, 1, 0],
			[1, 0, 3, 2],
			[2, 3, 0, 1],
			[],
			[],
		],
		"par_moves": 16,
		"bombs": false,
		"specials": [],
	},
	# Level 5 — Medium (5 colors, 7 tubes)
	{
		"colors": 5,
		"capacity": 4,
		"contents": [
			[0, 1, 2, 3],
			[4, 0, 1, 2],
			[3, 4, 0, 1],
			[2, 3, 4, 0],
			[1, 2, 3, 4],
			[],
			[],
		],
		"par_moves": 20,
		"bombs": false,
		"specials": [],
	},
]

static func get_level(idx: int) -> Dictionary:
	idx = idx % LEVELS.size()
	return LEVELS[idx].duplicate(true)

static func get_first_level() -> Dictionary:
	return LEVELS[0].duplicate(true)

static func get_level_count() -> int:
	return LEVELS.size()
