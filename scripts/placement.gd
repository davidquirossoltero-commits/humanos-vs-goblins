class_name Placement
extends RefCounted


static func dist_to_segment(px: float, py: float, ax: float, ay: float, bx: float, by: float) -> float:
	var abx := bx - ax
	var aby := by - ay
	var len2 := abx * abx + aby * aby
	if len2 <= 0.0001:
		return Vector2(px - ax, py - ay).length()
	var t := clampf(((px - ax) * abx + (py - ay) * aby) / len2, 0.0, 1.0)
	return Vector2(px - (ax + abx * t), py - (ay + aby * t)).length()


static func segment_t(px: float, py: float, ax: float, ay: float, bx: float, by: float) -> float:
	var abx := bx - ax
	var aby := by - ay
	var len2 := abx * abx + aby * aby
	if len2 <= 0.0001:
		return 0.0
	return clampf(((px - ax) * abx + (py - ay) * aby) / len2, 0.0, 1.0)


static func block_reason(map: Dictionary, towers: Array, x: float, y: float, gap: float) -> String:
	var margin := float(map.build_margin)
	var width := float(map.width)
	var height := float(map.height)
	if x < margin or y < margin or x > width - margin or y > height - margin:
		return "margin"
	for rect in map.blocked:
		var rx := float(rect.x)
		var ry := float(rect.y)
		if x >= rx and y >= ry and x <= rx + float(rect.w) and y <= ry + float(rect.h):
			return "blocked"
	var pts: Array = map.waypoints
	var radius := float(map.path_radius)
	for i in pts.size() - 1:
		var a: Dictionary = pts[i]
		var b: Dictionary = pts[i + 1]
		if dist_to_segment(x, y, float(a.x), float(a.y), float(b.x), float(b.y)) < radius:
			return "path"
	for tower in towers:
		if Vector2(x, y).distance_to(Vector2(float(tower.x), float(tower.y))) < gap:
			return "gap"
	return ""


static func message(reason: String) -> String:
	match reason:
		"margin":
			return "Fuera de los límites de la aldea."
		"blocked":
			return "Esa zona está ocupada."
		"path":
			return "No puedes construir sobre el camino."
		"gap":
			return "Demasiado cerca de otra torre."
		_:
			return "Ahí no se puede construir."
