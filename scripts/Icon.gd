extends RefCounted

# Geometric icon drawing — replaces emoji with crisp procedural shapes.
# Each icon is drawn into the given canvas at `center` with overall `size`,
# stroked with `color`.

const STROKE_W := 2.5

static func draw(ci: CanvasItem, name: String, center: Vector2, size: float, color: Color) -> void:
	match name:
		"back":     _back(ci, center, size, color)
		"settings": _settings(ci, center, size, color)
		"undo":     _undo(ci, center, size, color)
		"restart":  _restart(ci, center, size, color)
		"hint":     _hint(ci, center, size, color)
		"close":    _close(ci, center, size, color)
		"play":     _play(ci, center, size, color)
		"next":     _next(ci, center, size, color)
		"star":     _star(ci, center, size, color)
		"lock":     _lock(ci, center, size, color)

# Back arrow (←) — horizontal line with arrowhead on the left
static func _back(ci: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	var w: float = size * 0.55
	var h: float = size * 0.40
	var left := center + Vector2(-w * 0.5, 0)
	var right := center + Vector2(w * 0.5, 0)
	ci.draw_line(left, right, color, STROKE_W, true)
	ci.draw_line(left, left + Vector2(h * 0.5, -h * 0.5), color, STROKE_W, true)
	ci.draw_line(left, left + Vector2(h * 0.5, h * 0.5), color, STROKE_W, true)

# Next arrow (→)
static func _next(ci: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	var w: float = size * 0.55
	var h: float = size * 0.40
	var left := center + Vector2(-w * 0.5, 0)
	var right := center + Vector2(w * 0.5, 0)
	ci.draw_line(left, right, color, STROKE_W, true)
	ci.draw_line(right, right + Vector2(-h * 0.5, -h * 0.5), color, STROKE_W, true)
	ci.draw_line(right, right + Vector2(-h * 0.5, h * 0.5), color, STROKE_W, true)

# Gear icon — 8 notches around a hub
static func _settings(ci: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	var outer: float = size * 0.42
	var inner: float = size * 0.32
	var hub: float = size * 0.16
	var notches := 8
	# Build a gear polygon: alternate outer/inner radius at each tooth
	var pts := PackedVector2Array()
	var steps := notches * 4  # each tooth has 4 vertices (outer-out, outer-out, inner-in, inner-in)
	for i in range(steps):
		var angle: float = TAU * float(i) / float(steps)
		# Pattern: 0,1 outer; 2,3 inner
		var r: float = outer if (i % 4 < 2) else inner
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	# Close polygon
	pts.append(pts[0])
	ci.draw_polyline(pts, color, STROKE_W, true)
	# Hub circle outline
	_circle_outline(ci, center, hub, color)

# Undo (counterclockwise arc + arrowhead)
static func _undo(ci: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	_arrow_arc(ci, center, size, color, true)

# Restart (clockwise arc + arrowhead)
static func _restart(ci: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	_arrow_arc(ci, center, size, color, false)

static func _arrow_arc(ci: CanvasItem, center: Vector2, size: float, color: Color, counter_clockwise: bool) -> void:
	var r: float = size * 0.32
	# 270° arc (3/4 circle)
	var start_angle: float = -PI * 0.5  # top
	var arc_span: float = PI * 1.4
	var segments := 18
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var t_norm: float = float(i) / float(segments)
		var angle: float
		if counter_clockwise:
			angle = start_angle - arc_span * t_norm
		else:
			angle = start_angle + arc_span * t_norm
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	ci.draw_polyline(pts, color, STROKE_W, true)
	# Arrowhead at the end of the arc
	var end_pt: Vector2 = pts[pts.size() - 1]
	var prev_pt: Vector2 = pts[pts.size() - 2]
	var tangent: Vector2 = (end_pt - prev_pt).normalized()
	var perp: Vector2 = Vector2(-tangent.y, tangent.x)
	var head_len: float = size * 0.18
	ci.draw_line(end_pt, end_pt - tangent * head_len + perp * head_len * 0.6, color, STROKE_W, true)
	ci.draw_line(end_pt, end_pt - tangent * head_len - perp * head_len * 0.6, color, STROKE_W, true)

# Hint — lightbulb icon (circle + base)
static func _hint(ci: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	var bulb_r: float = size * 0.28
	var bulb_center := center + Vector2(0, -size * 0.05)
	_circle_outline(ci, bulb_center, bulb_r, color)
	# Filament — small arc inside
	var fil_y: float = bulb_center.y + bulb_r * 0.2
	ci.draw_line(Vector2(bulb_center.x - bulb_r * 0.45, fil_y),
		Vector2(bulb_center.x + bulb_r * 0.45, fil_y), color, STROKE_W * 0.7, true)
	# Base (cap below)
	var base_y: float = bulb_center.y + bulb_r + 2
	var base_w: float = bulb_r * 0.9
	ci.draw_rect(Rect2(center.x - base_w * 0.5, base_y, base_w, 3), color)
	ci.draw_rect(Rect2(center.x - base_w * 0.35, base_y + 4, base_w * 0.7, 2), color)

# Close (✕)
static func _close(ci: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	var s: float = size * 0.30
	ci.draw_line(center + Vector2(-s, -s), center + Vector2(s, s), color, STROKE_W, true)
	ci.draw_line(center + Vector2(-s, s), center + Vector2(s, -s), color, STROKE_W, true)

# Play (triangle pointing right)
static func _play(ci: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	var r: float = size * 0.35
	var pts := PackedVector2Array([
		center + Vector2(-r * 0.6, -r),
		center + Vector2(r, 0),
		center + Vector2(-r * 0.6, r),
	])
	ci.draw_colored_polygon(pts, color)

# Filled five-point star
static func _star(ci: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	var outer: float = size * 0.40
	var inner: float = size * 0.16
	var pts := PackedVector2Array()
	for i in range(10):
		var angle: float = -PI * 0.5 + TAU * float(i) / 10.0
		var r: float = outer if (i % 2 == 0) else inner
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	ci.draw_colored_polygon(pts, color)

# Padlock
static func _lock(ci: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	var body_w: float = size * 0.42
	var body_h: float = size * 0.34
	var body_rect := Rect2(center.x - body_w * 0.5, center.y - body_h * 0.3, body_w, body_h)
	ci.draw_rect(body_rect, color)
	# Shackle arc
	var arc_pts := PackedVector2Array()
	var arc_r: float = body_w * 0.35
	var arc_center := Vector2(center.x, body_rect.position.y)
	for i in range(13):
		var angle: float = -PI + (PI) * float(i) / 12.0
		arc_pts.append(arc_center + Vector2(cos(angle), sin(angle)) * arc_r)
	ci.draw_polyline(arc_pts, color, STROKE_W, true)

# --- helpers ---
static func _circle_outline(ci: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	var segments := 18
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var angle: float = TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	ci.draw_polyline(pts, color, STROKE_W, true)
