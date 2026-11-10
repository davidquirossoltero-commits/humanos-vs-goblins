class_name DrawMap
extends RefCounted


static func render(c: CanvasItem, map: Dictionary) -> void:
	var width := float(map.width)
	var height := float(map.height)
	c.draw_rect(Rect2(0, 0, width, height), Color("6fbf4e"), true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for _i in 70:
		var blob := Color("8ed463") if rng.randf() > 0.45 else Color("59a43a")
		c.draw_circle(Vector2(rng.randf_range(0, width), rng.randf_range(0, height)), rng.randf_range(16, 54), blob)
	var pts := PackedVector2Array()
	for waypoint in map.waypoints:
		pts.append(Vector2(float(waypoint.x), float(waypoint.y)))
	_sausage(c, pts, 40.0, Color("5a3a22"))
	_sausage(c, pts, 31.0, Color("c4a06a"))
	_sausage(c, pts, 16.0, Color("e2c48a"))
	_pebbles(c, pts, rng)
	_props(c, map, pts, rng)
	if pts.size() >= 2:
		_cave(c, Vector2(42, pts[1].y))
		_castle(c, pts[pts.size() - 1])
	_label(c, Vector2(18, 168), "CUEVA")
	_label(c, Vector2(1128, 430), "CASTILLO")


static func _sausage(c: CanvasItem, pts: PackedVector2Array, radius: float, color: Color) -> void:
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var length := a.distance_to(b)
		var steps := maxi(int(length / (radius * 0.42)), 1)
		for s in steps + 1:
			c.draw_circle(a.lerp(b, float(s) / float(steps)), radius, color)
	for point in pts:
		c.draw_circle(point, radius, color)


static func _pebbles(c: CanvasItem, pts: PackedVector2Array, rng: RandomNumberGenerator) -> void:
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var length := a.distance_to(b)
		var steps := maxi(int(length / 26.0), 1)
		for s in steps:
			var p := a.lerp(b, float(s) / float(steps))
			p += Vector2(rng.randf_range(-8, 8), rng.randf_range(-6, 6))
			c.draw_circle(p, rng.randf_range(1.4, 2.6), Color("8d6a42"))


static func _near_path(map: Dictionary, pts: PackedVector2Array, point: Vector2, extra: float) -> bool:
	var radius := float(map.path_radius) + extra
	for i in pts.size() - 1:
		if Placement.dist_to_segment(point.x, point.y, pts[i].x, pts[i].y, pts[i + 1].x, pts[i + 1].y) < radius:
			return true
	return false


static func _props(c: CanvasItem, map: Dictionary, pts: PackedVector2Array, rng: RandomNumberGenerator) -> void:
	var houses := [Vector2(470, 340), Vector2(150, 600), Vector2(730, 620), Vector2(760, 360), Vector2(500, 110)]
	for house in houses:
		if house.y < 120:
			continue
		if not _near_path(map, pts, house, 28):
			_house(c, house, rng.randf() > 0.5)
	for _i in 18:
		var tree := Vector2(rng.randf_range(40, 1000), rng.randf_range(120, 680))
		if _near_path(map, pts, tree, 36):
			continue
		if tree.x > 1000 and tree.y > 360:
			continue
		_tree(c, tree, rng.randf_range(0.8, 1.25))
	for _i in 26:
		var flower := Vector2(rng.randf_range(20, 1000), rng.randf_range(110, 700))
		if _near_path(map, pts, flower, 10):
			continue
		_flower(c, flower, rng)


static func _house(c: CanvasItem, p: Vector2, red_roof: bool) -> void:
	c.draw_circle(p + Vector2(0, 8), 28, Color(0, 0, 0, 0.15))
	var wall := Color("f3e2c0")
	c.draw_rect(Rect2(p + Vector2(-26, -22), Vector2(52, 40)), Color("2a1a10"), true)
	c.draw_rect(Rect2(p + Vector2(-22, -18), Vector2(44, 34)), wall, true)
	c.draw_rect(Rect2(p + Vector2(-8, -4), Vector2(14, 20)), Color("6b3e22"), true)
	c.draw_rect(Rect2(p + Vector2(10, -16), Vector2(12, 10)), Color("87c7e8"), true)
	var roof := Color("c4473a") if red_roof else Color("3d6fbf")
	_roof(c, p + Vector2(0, -18), 34, 22, roof)


static func _roof(c: CanvasItem, p: Vector2, half_w: float, h: float, fill: Color) -> void:
	var a := p + Vector2(-half_w, 6)
	var b := p + Vector2(half_w, 6)
	var d := p + Vector2(0, -h)
	var center := (a + b + d) / 3.0
	c.draw_colored_polygon(PackedVector2Array([
		center + (a - center) * 1.12,
		center + (b - center) * 1.12,
		center + (d - center) * 1.12,
	]), Color("2a1a10"))
	c.draw_colored_polygon(PackedVector2Array([a, b, d]), fill)


static func _tree(c: CanvasItem, p: Vector2, scale: float) -> void:
	c.draw_rect(Rect2(p + Vector2(-4, -2) * scale, Vector2(8, 18) * scale), Color("6b4428"), true)
	var leaf := Color("2f8a32")
	c.draw_circle(p + Vector2(0, -16) * scale, 16 * scale, Color("1c3a16"))
	c.draw_circle(p + Vector2(0, -16) * scale, 13 * scale, leaf)
	c.draw_circle(p + Vector2(-10, -8) * scale, 10 * scale, Color("277a2c"))
	c.draw_circle(p + Vector2(9, -10) * scale, 9 * scale, Color("3ea043"))


static func _flower(c: CanvasItem, p: Vector2, rng: RandomNumberGenerator) -> void:
	c.draw_line(p, p + Vector2(0, 8), Color("2f7a32"), 2.0, true)
	var petal := Color("ffd24a")
	if rng.randf() > 0.66:
		petal = Color("ff7a93")
	elif rng.randf() > 0.5:
		petal = Color("fffaf0")
	c.draw_circle(p, 3.2, petal)
	c.draw_circle(p, 1.3, Color("e2a31a"))


static func _cave(c: CanvasItem, p: Vector2) -> void:
	c.draw_circle(p + Vector2(0, 8), 48, Color("3f7a32"))
	c.draw_circle(p + Vector2(0, 16), 36, Color("2c5a24"))
	c.draw_circle(p, 26, Color("140e0a"))
	c.draw_rect(Rect2(p + Vector2(-30, -24), Vector2(10, 50)), Color("6b4428"), true)
	c.draw_rect(Rect2(p + Vector2(20, -24), Vector2(10, 50)), Color("6b4428"), true)
	c.draw_rect(Rect2(p + Vector2(-34, -30), Vector2(68, 12)), Color("8a5a32"), true)
	c.draw_circle(p + Vector2(-8, -2), 3.2, Color("ff3b3b"))
	c.draw_circle(p + Vector2(7, 0), 3.2, Color("ff3b3b"))


static func _castle(c: CanvasItem, gate: Vector2) -> void:
	c.draw_circle(gate + Vector2(40, 16), 70, Color(0, 0, 0, 0.15))
	var stone := Color("b7bcc6")
	var dark := Color("6e7684")
	var ink := Color("2a1a10")
	_tower(c, gate + Vector2(8, -8), stone, dark, ink)
	_tower(c, gate + Vector2(92, -8), stone, dark, ink)
	c.draw_rect(Rect2(gate + Vector2(-8, -36), Vector2(118, 70)), ink, true)
	c.draw_rect(Rect2(gate + Vector2(-4, -32), Vector2(110, 62)), stone, true)
	for i in 8:
		c.draw_rect(Rect2(gate + Vector2(-4 + i * 14, -46), Vector2(8, 16)), stone, true)
		c.draw_rect(Rect2(gate + Vector2(-6 + i * 14, -48), Vector2(12, 18)), ink, false, 2.0)
	c.draw_circle(gate + Vector2(0, 4), 22, Color("1a120c"))
	c.draw_rect(Rect2(gate + Vector2(-16, 2), Vector2(32, 28)), Color("1a120c"), true)
	for i in 5:
		c.draw_line(gate + Vector2(-12 + i * 6, -8), gate + Vector2(-12 + i * 6, 24), Color("4a4038"), 2.0, true)
	c.draw_line(gate + Vector2(8, -78), gate + Vector2(8, -48), Color("6b3e22"), 3.0, true)
	_banner(c, gate + Vector2(8, -78), Color("c4473a"))
	c.draw_circle(gate + Vector2(-20, -10), 4, Color("ffb15a"))
	c.draw_circle(gate + Vector2(24, -10), 4, Color("ffb15a"))


static func _tower(c: CanvasItem, p: Vector2, stone: Color, dark: Color, ink: Color) -> void:
	c.draw_rect(Rect2(p + Vector2(-18, -70), Vector2(36, 90)), ink, true)
	c.draw_rect(Rect2(p + Vector2(-14, -66), Vector2(28, 82)), stone, true)
	c.draw_rect(Rect2(p + Vector2(-18, -82), Vector2(10, 18)), stone, true)
	c.draw_rect(Rect2(p + Vector2(-4, -86), Vector2(10, 22)), stone, true)
	c.draw_rect(Rect2(p + Vector2(8, -82), Vector2(10, 18)), stone, true)
	c.draw_rect(Rect2(p + Vector2(-6, -40), Vector2(12, 16)), dark, true)


static func _banner(c: CanvasItem, p: Vector2, fill: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array([
		p, p + Vector2(22, 6), p + Vector2(16, 16), p + Vector2(0, 12),
	]), fill)
	c.draw_polyline(PackedVector2Array([
		p, p + Vector2(22, 6), p + Vector2(16, 16), p + Vector2(0, 12), p,
	]), Color("2a1a10"), 2.0, true)


static func _label(c: CanvasItem, pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	c.draw_string(font, pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0, 0, 0, 0.35))
	c.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff1cc"))
