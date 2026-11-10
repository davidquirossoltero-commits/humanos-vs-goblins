class_name Targeting
extends RefCounted


static func pick(units: Array, origin: Vector2, tower_range: float, mode: String) -> Dictionary:
	var pool: Array = []
	for unit in units:
		var point := Vector2(float(unit.x), float(unit.y))
		var reach := tower_range + float(unit.get("radius", 0.0))
		if point.distance_to(origin) <= reach:
			pool.append(unit)
	if pool.is_empty():
		return {}
	pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _better(a, b, origin, mode)
	)
	return pool[0]


static func _better(a: Dictionary, b: Dictionary, origin: Vector2, mode: String) -> bool:
	match mode:
		"last":
			return float(a.distance) < float(b.distance)
		"close":
			var da := origin.distance_to(Vector2(float(a.x), float(a.y)))
			var db := origin.distance_to(Vector2(float(b.x), float(b.y)))
			return da < db
		"strong":
			if int(a.hp) != int(b.hp):
				return int(a.hp) > int(b.hp)
			return float(a.distance) > float(b.distance)
		_:
			return float(a.distance) > float(b.distance)


static func next_mode(mode: String) -> String:
	var modes := ["first", "strong", "last", "close"]
	var idx := modes.find(mode)
	if idx < 0:
		return "first"
	return modes[(idx + 1) % modes.size()]


static func mode_label(mode: String) -> String:
	match mode:
		"strong":
			return "El más fuerte"
		"last":
			return "Último"
		"close":
			return "El más cercano"
		_:
			return "Primero"
