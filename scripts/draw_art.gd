class_name DrawArt
extends RefCounted

## Jugadores de fútbol fantástico. El arte es original: cascos, hombreras y un balón,
## sin copiar el material de ningún juego de tablero.


static func draw_enemy(c: CanvasItem, pos: Vector2, look: String, scale: float, flash: float, slowed: bool) -> void:
	var tint := Color(1, 1, 1, 1)
	if flash > 0.05:
		tint = Color(1.6, 1.6, 1.6, 1)
	elif slowed:
		tint = Color(0.65, 0.82, 1.15, 1)
	_sprite(c, look, pos, scale, 0.0, false, tint)


static func draw_tower(c: CanvasItem, kind: String, pos: Vector2, aim: float, alpha: float) -> void:
	var tint := Color(1, 1, 1, alpha)
	if kind == "canon":
		_sprite(c, "canon", pos, 118.0, aim, false, tint)
	else:
		var flip := cos(aim) < 0.0
		var height := 124.0 if kind == "mago" else 118.0
		_sprite(c, kind, pos, height, 0.0, flip, tint)


static func enemy_scale(look: String) -> float:
	match look:
		"jinete":
			return 118.0
		"hobgoblin":
			return 102.0
		"ogro_armadura", "ogro":
			return 136.0
		"trol", "trol_furia":
			return 156.0
		_:
			return 84.0


static func _sprite(c: CanvasItem, key: String, pos: Vector2, height: float, rotation: float, flip: bool, tint: Color) -> void:
	var texture := ArtBank.tex(key)
	if texture == null:
		c.draw_circle(pos, 18.0, Color("c4312e"))
		return
	var aspect := float(texture.get_width()) / float(texture.get_height())
	var width := height * aspect
	var sign := -1.0 if flip else 1.0
	c.draw_set_transform(pos, rotation, Vector2(sign, 1.0))
	c.draw_texture_rect(texture, Rect2(-width * 0.5, -height * 0.5, width, height), false, tint)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
