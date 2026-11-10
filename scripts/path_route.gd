class_name PathRoute
extends RefCounted

var points := PackedVector2Array()
var seg_len := PackedFloat32Array()
var seg_start := PackedFloat32Array()
var total := 0.0


func _init(waypoints: Array) -> void:
	for waypoint in waypoints:
		points.append(Vector2(float(waypoint.x), float(waypoint.y)))
	var count := points.size()
	if count < 2:
		return
	seg_len.resize(count - 1)
	seg_start.resize(count - 1)
	var acc := 0.0
	for i in count - 1:
		var length := points[i].distance_to(points[i + 1])
		seg_start[i] = acc
		seg_len[i] = length
		acc += length
	total = acc


func reached(distance: float) -> bool:
	return distance >= total


func pose(distance: float) -> Dictionary:
	if points.is_empty():
		return {"pos": Vector2.ZERO, "angle": 0.0}
	if points.size() == 1 or total <= 0.0:
		return {"pos": points[0], "angle": 0.0}
	var d := clampf(distance, 0.0, total)
	var i := 0
	while i < seg_len.size() - 1 and float(seg_start[i + 1]) <= d:
		i += 1
	var length := float(seg_len[i])
	var t := 0.0 if length <= 0.0001 else (d - float(seg_start[i])) / length
	var a := points[i]
	var b := points[i + 1]
	return {"pos": a.lerp(b, t), "angle": a.angle_to_point(b)}
