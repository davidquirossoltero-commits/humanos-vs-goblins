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


static func draw_tower(c: CanvasItem, kind: String, pos: Vector2, aim: float, alpha: float, height: float = -1.0) -> void:
	var tint := Color(1, 1, 1, alpha)
	var used := height
	if used <= 0.0:
		used = 78.0 if kind == "canon" else 88.0
	if kind == "canon":
		# El cañón se queda plantado. El proyectil sale hacia el blanco, la cureña no gira.
		_sprite(c, "canon", pos, used, 0.0, false, tint)
	else:
		var flip := cos(aim) < 0.0
		_sprite(c, kind, pos, used, 0.0, flip, tint)


static func enemy_scale(look: String) -> float:
	match look:
		"jinete":
			return 86.0
		"hobgoblin":
			return 74.0
		"ogro_armadura", "ogro":
			return 96.0
		"trol", "trol_furia":
			return 108.0
		_:
			return 62.0


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
