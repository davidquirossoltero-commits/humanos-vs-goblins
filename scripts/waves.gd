class_name WaveLogic
extends RefCounted


static func build_schedule(wave: Dictionary, group_gap: float = 1.2) -> Array:
	var events: Array = []
	var t := 0.0
	for group in wave.groups:
		var count := int(group.count)
		var interval := float(group.interval)
		var enemy_id := str(group.enemy_id)
		for i in count:
			events.append({"time": t, "enemy_id": enemy_id})
			if i < count - 1:
				t += interval
		t += group_gap
	return events


static func wave_rbe(wave: Dictionary, enemies: Dictionary) -> int:
	var total := 0
	for group in wave.groups:
		total += int(group.count) * LayerLogic.rbe(str(group.enemy_id), 0, enemies)
	return total


static func describe(wave: Dictionary, enemies: Dictionary) -> String:
	var parts := PackedStringArray()
	for group in wave.groups:
		var n := int(group.count)
		var def: Dictionary = enemies[str(group.enemy_id)]
		var label := str(def.name) if n == 1 else str(def.plural)
		parts.append("%d %s" % [n, label])
	return " · ".join(parts)
