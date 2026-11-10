class_name DrawArt
extends RefCounted

static func draw_enemy(c: CanvasItem, pos: Vector2, look: String, scale: float, flash: float, slowed: bool) -> void:
	c.draw_set_transform(pos, 0.0, Vector2.ONE * scale)
	match look:
		"jinete":
			_jinete(c)
		"hobgoblin":
			_hobgoblin(c)
		"ogro_armadura":
			_ogro(c, true)
		"ogro":
			_ogro(c, false)
		"trol":
			_trol(c, false)
		"trol_furia":
			_trol(c, true)
		_:
			_goblin(c, Color("67c23a"), Color("b6e07a"), 1.0)
	if flash > 0.0:
		c.draw_circle(Vector2(0, -2), 18.0, Color(1, 1, 1, clampf(flash * 4.0, 0.0, 0.65)))
	if slowed:
		c.draw_circle(Vector2(0, -2), 16.0, Color(0.55, 0.82, 1.0, 0.35))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func draw_tower(c: CanvasItem, kind: String, pos: Vector2, aim: float, alpha: float) -> void:
	if kind == "canon":
		c.draw_set_transform(pos, aim, Vector2.ONE)
		_canon(c, alpha)
	else:
		var flip := -1.0 if cos(aim) < 0.0 else 1.0
		c.draw_set_transform(pos, 0.0, Vector2(flip, 1.0))
		if kind == "mago":
			_mago(c, alpha)
		else:
			_arquero(c, alpha)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func enemy_scale(look: String) -> float:
	match look:
		"jinete":
			return 1.15
		"hobgoblin":
			return 1.2
		"ogro_armadura", "ogro":
			return 1.55
		"trol", "trol_furia":
			return 1.75
		_:
			return 1.0


static func _ball(c: CanvasItem, p: Vector2, r: float, fill: Color, ink: Color = Color("1c140c"), ow: float = 3.0) -> void:
	if ow > 0.0 and ink.a > 0.0:
		c.draw_circle(p, r + ow, ink)
	c.draw_circle(p, r, fill)


static func _tri(c: CanvasItem, a: Vector2, b: Vector2, d: Vector2, fill: Color, ink: Color = Color("1c140c")) -> void:
	var center := (a + b + d) / 3.0
	c.draw_colored_polygon(PackedVector2Array([
		center + (a - center) * 1.22,
		center + (b - center) * 1.22,
		center + (d - center) * 1.22,
	]), ink)
	c.draw_colored_polygon(PackedVector2Array([a, b, d]), fill)


static func _eyes(c: CanvasItem, y: float, gap: float, r: float, angry: bool, pupil: Color = Color("1c140c")) -> void:
	_ball(c, Vector2(-gap, y), r, Color("fffdf8"), Color("1c140c"), 2.0)
	_ball(c, Vector2(gap, y), r, Color("fffdf8"), Color("1c140c"), 2.0)
	c.draw_circle(Vector2(-gap + 1.2, y + 0.8), r * 0.42, pupil)
	c.draw_circle(Vector2(gap + 1.2, y + 0.8), r * 0.42, pupil)
	c.draw_circle(Vector2(-gap - 0.6, y - 0.8), r * 0.18, Color.WHITE)
	c.draw_circle(Vector2(gap - 0.6, y - 0.8), r * 0.18, Color.WHITE)
	if angry:
		c.draw_line(Vector2(-gap - r, y - r - 1.0), Vector2(-gap + r * 0.3, y - r * 0.2), Color("1c140c"), 2.4, true)
		c.draw_line(Vector2(gap + r, y - r - 1.0), Vector2(gap - r * 0.3, y - r * 0.2), Color("1c140c"), 2.4, true)


static func _goblin(c: CanvasItem, skin: Color, belly: Color, s: float) -> void:
	c.draw_circle(Vector2(0, 16) * s, 12 * s, Color(0, 0, 0, 0.22))
	_tri(c, Vector2(-18, -6) * s, Vector2(-8, -18) * s, Vector2(-4, -2) * s, skin)
	_tri(c, Vector2(18, -6) * s, Vector2(8, -18) * s, Vector2(4, -2) * s, skin)
	_ball(c, Vector2(0, 2) * s, 15 * s, skin)
	_ball(c, Vector2(0, 7) * s, 8 * s, belly, Color(0, 0, 0, 0), 0)
	_eyes(c, -2 * s, 5.5 * s, 3.6 * s, true)
	_ball(c, Vector2(0, 7) * s, 3.2 * s, Color("2a1810"), Color("1c140c"), 1.5)
	c.draw_rect(Rect2(Vector2(-3.2, 5.2) * s, Vector2(2.2, 3.2) * s), Color("fff6e4"), true)
	c.draw_rect(Rect2(Vector2(1.0, 5.2) * s, Vector2(2.2, 3.2) * s), Color("fff6e4"), true)
	c.draw_circle(Vector2(-7, 4) * s, 2.2 * s, Color(1, 0.55, 0.55, 0.45))
	c.draw_circle(Vector2(7, 4) * s, 2.2 * s, Color(1, 0.55, 0.55, 0.45))


static func _jinete(c: CanvasItem) -> void:
	c.draw_circle(Vector2(2, 18), 16, Color(0, 0, 0, 0.22))
	_ball(c, Vector2(-6, 8), 16, Color("c47a4a"))
	_ball(c, Vector2(14, 10), 9, Color("a8643a"))
	_ball(c, Vector2(20, 12), 3.2, Color("fff6e4"), Color("1c140c"), 1.5)
	c.draw_circle(Vector2(16, 6), 2.2, Color("1c140c"))
	_ball(c, Vector2(-16, 16), 4, Color("8a4e2c"), Color("1c140c"), 2)
	_ball(c, Vector2(2, 16), 4, Color("8a4e2c"), Color("1c140c"), 2)
	_goblin(c, Color("67c23a"), Color("b6e07a"), 0.72)


static func _hobgoblin(c: CanvasItem) -> void:
	_goblin(c, Color("3e8f32"), Color("8fce6a"), 1.15)
	_ball(c, Vector2(-14, -8), 6, Color("8d97a8"))
	_ball(c, Vector2(14, -6), 5, Color("6e5840"), Color("1c140c"), 2)
	c.draw_line(Vector2(12, -2), Vector2(26, 14), Color("6b3e22"), 5.0, true)
	_ball(c, Vector2(28, 16), 6.5, Color("8a5a32"))


static func _ogro(c: CanvasItem, armored: bool) -> void:
	c.draw_circle(Vector2(0, 20), 18, Color(0, 0, 0, 0.25))
	var skin := Color("7a8f3a")
	_ball(c, Vector2(0, 6), 20, skin)
	_ball(c, Vector2(0, 12), 11, Color("c5d48a"), Color(0, 0, 0, 0), 0)
	_ball(c, Vector2(-16, 8), 7, skin)
	_ball(c, Vector2(16, 8), 7, skin)
	if armored:
		_ball(c, Vector2(0, -8), 14, Color("8d97a8"))
		_tri(c, Vector2(-16, -10), Vector2(-8, -28), Vector2(-2, -8), Color("9aa3b2"))
		_tri(c, Vector2(16, -10), Vector2(8, -28), Vector2(2, -8), Color("9aa3b2"))
		_ball(c, Vector2(0, 4), 12, Color("6e7684"))
		c.draw_rect(Rect2(Vector2(-10, -6), Vector2(20, 5)), Color("1c140c"), true)
		_eyes(c, -4, 5, 2.4, true, Color("ffd24a"))
	else:
		_ball(c, Vector2(0, -8), 12, skin)
		_ball(c, Vector2(4, -2), 8, Color("efe6d4"), Color("1c140c"), 2)
		_eyes(c, -6, 5, 3.2, true)
		_ball(c, Vector2(0, 8), 4, Color("5a1e16"), Color("1c140c"), 1.5)
	_ball(c, Vector2(-18, 16), 5, skin)
	_ball(c, Vector2(18, 16), 5, skin)


static func _trol(c: CanvasItem, rage: bool) -> void:
	c.draw_circle(Vector2(0, 22), 20, Color(0, 0, 0, 0.25))
	var skin := Color("c16b6b") if rage else Color("6aa8b8")
	var belly := Color("e7a0a0") if rage else Color("b7e0ea")
	_ball(c, Vector2(0, 4), 22, skin)
	_ball(c, Vector2(0, 10), 12, belly, Color(0, 0, 0, 0), 0)
	_ball(c, Vector2(-8, 2), 7, Color("5f8f4a"), Color(0, 0, 0, 0), 0)
	_ball(c, Vector2(10, -2), 5, Color("6ea356"), Color(0, 0, 0, 0), 0)
	_ball(c, Vector2(0, -2), 6, skin)
	var pupil := Color("ff3030") if rage else Color("1c140c")
	_eyes(c, -8, 6, 3.4, true, pupil)
	if rage:
		_ball(c, Vector2(0, 8), 6, Color("7a1d1d"), Color("1c140c"), 2)
		c.draw_rect(Rect2(Vector2(-3, 5), Vector2(2.4, 4)), Color.WHITE, true)
		c.draw_rect(Rect2(Vector2(1, 5), Vector2(2.4, 4)), Color.WHITE, true)
	else:
		_ball(c, Vector2(0, 8), 3.5, Color("2a1810"), Color("1c140c"), 1.4)
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(-8, 16), Vector2(8, 16), Vector2(0, 26),
	]), Color("8d5a32"))
	c.draw_line(Vector2(14, 0), Vector2(30, 18), Color("5b4632"), 6.0, true)
	_ball(c, Vector2(32, 20), 8, Color("6d5438"))


static func _platform(c: CanvasItem, alpha: float) -> void:
	var wood := Color("a56b3c")
	wood.a = alpha
	var ink := Color("1c140c")
	ink.a = alpha
	_ball(c, Vector2(0, 8), 22, wood, ink, 3)
	var plank := Color("c48a55")
	plank.a = alpha
	c.draw_line(Vector2(-14, 4), Vector2(14, 12), plank, 3.0, true)
	c.draw_line(Vector2(-12, 12), Vector2(16, 4), plank, 3.0, true)


static func _arquero(c: CanvasItem, alpha: float) -> void:
	_platform(c, alpha)
	var tunic := Color("3d6fbf")
	tunic.a = alpha
	var skin := Color("f0c29a")
	skin.a = alpha
	var ink := Color("1c140c")
	ink.a = alpha
	_ball(c, Vector2(0, -6), 11, tunic, ink, 3)
	_ball(c, Vector2(0, -22), 8, skin, ink, 2.5)
	_ball(c, Vector2(0, -28), 9, Color("c5ccd6", alpha), ink, 2.5)
	c.draw_line(Vector2(2, -30), Vector2(2, -38), Color("8d97a8", alpha), 3.0, true)
	c.draw_arc(Vector2(12, -10), 14, -1.1, 1.0, 12, Color("6b3e22", alpha), 3.0, true)
	c.draw_line(Vector2(8, -16), Vector2(22, -4), Color("d8d2c4", alpha), 2.0, true)
	_ball(c, Vector2(-12, -4), 4, Color("8a5a32", alpha), ink, 1.5)


static func _mago(c: CanvasItem, alpha: float) -> void:
	var stone := Color("8d8f99")
	stone.a = alpha
	var ink := Color("1c140c")
	ink.a = alpha
	_ball(c, Vector2(0, 10), 20, stone, ink, 3)
	_ball(c, Vector2(0, -2), 14, Color("6e7078", alpha), ink, 2)
	_tri(c, Vector2(-16, -4), Vector2(16, -4), Vector2(0, -36), Color("7a4db8", alpha), ink)
	_ball(c, Vector2(0, -8), 7, Color("f4f0ea", alpha), ink, 2)
	_tri(c, Vector2(-8, -16), Vector2(8, -16), Vector2(0, -40), Color("5b348f", alpha), ink)
	c.draw_line(Vector2(12, -2), Vector2(24, -28), Color("6b3e22", alpha), 3.0, true)
	_ball(c, Vector2(26, -32), 6, Color("ffe36b", alpha), ink, 2)
	c.draw_circle(Vector2(26, -32), 2.4, Color(1, 1, 1, alpha))
	c.draw_circle(Vector2(-10, -22), 1.6, Color("ffe36b", alpha))
	c.draw_circle(Vector2(6, -26), 1.4, Color("fff6c8", alpha))


static func _canon(c: CanvasItem, alpha: float) -> void:
	var ink := Color("1c140c")
	ink.a = alpha
	_ball(c, Vector2(-6, 10), 10, Color("6b3e22", alpha), ink, 2.5)
	_ball(c, Vector2(16, 10), 10, Color("6b3e22", alpha), ink, 2.5)
	c.draw_rect(Rect2(Vector2(-14, -8), Vector2(36, 16)), Color("8b5a32", alpha), true)
	c.draw_rect(Rect2(Vector2(-16, -10), Vector2(40, 20)), Color("8b5a32", alpha), false, 3.0)
	_ball(c, Vector2(22, -2), 7, Color("4e5560", alpha), ink, 2.5)
	c.draw_rect(Rect2(Vector2(8, -7), Vector2(28, 12)), Color("5c6570", alpha), true)
	c.draw_rect(Rect2(Vector2(6, -9), Vector2(32, 16)), ink, false, 3.0)
	c.draw_line(Vector2(10, -5), Vector2(34, -5), Color("c5ced6", alpha), 2.0, true)
	_ball(c, Vector2(-8, -16), 6, Color("3d6fbf", alpha), ink, 2)
	_ball(c, Vector2(-8, -26), 5, Color("f0c29a", alpha), ink, 2)
