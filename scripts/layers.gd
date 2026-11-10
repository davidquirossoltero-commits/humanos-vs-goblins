class_name LayerLogic
extends RefCounted

## Daño por capas al estilo de los globos: el exceso sigue hacia la capa interior
## y las crías salen con toda su vida, sin recibir ese mismo golpe.


static func create_enemy(def_id: String, distance: float, enemies: Dictionary) -> Dictionary:
	var layer: Dictionary = enemies[def_id].layers[0]
	return {
		"def_id": def_id,
		"layer_index": 0,
		"hp": int(layer.hp),
		"distance": maxf(0.0, distance),
		"slow_until": 0.0,
		"slow_factor": 1.0,
	}


static func layer_of(enemy: Dictionary, enemies: Dictionary) -> Dictionary:
	var layers: Array = enemies[str(enemy.def_id)].layers
	return layers[int(enemy.layer_index)]


static func speed_of(enemy: Dictionary, enemies: Dictionary, now: float) -> float:
	var spd := float(layer_of(enemy, enemies).speed)
	if now < float(enemy.slow_until):
		spd *= float(enemy.slow_factor)
	return spd


static func apply_slow(enemy: Dictionary, now: float, duration: float, factor: float) -> Dictionary:
	var copy := enemy.duplicate(true)
	copy.slow_until = maxf(float(copy.slow_until), now + duration)
	copy.slow_factor = factor
	return copy


static func rbe(def_id: String, layer_index: int, enemies: Dictionary, depth: int = 0) -> int:
	if depth > 8:
		push_error("Ciclo en las capas de %s" % def_id)
		return 0
	var layers: Array = enemies[def_id].layers
	var total := 0
	for i in range(layer_index, layers.size()):
		var layer: Dictionary = layers[i]
		total += int(layer.leak)
		for spawn in layer.get("spawns", []):
			total += int(spawn.count) * rbe(str(spawn.id), 0, enemies, depth + 1)
	return total


static func damage_enemy(enemy: Dictionary, amount: int, enemies: Dictionary, spacing: float = 28.0) -> Dictionary:
	var current := enemy.duplicate(true)
	var gold := 0
	var spawned: Array = []
	var broken := 0
	var dmg := maxi(amount, 0)
	var def: Dictionary = enemies[str(current.def_id)]
	var layers: Array = def.layers
	while dmg > 0:
		var hp := int(current.hp)
		if hp > dmg:
			current.hp = hp - dmg
			dmg = 0
		else:
			dmg -= hp
			var idx := int(current.layer_index)
			var layer: Dictionary = layers[idx]
			gold += int(layer.reward)
			broken += 1
			var dist := float(current.distance)
			var step := 1
			for spawn in layer.get("spawns", []):
				var count := int(spawn.count)
				var sid := str(spawn.id)
				for _n in count:
					var child_dist := maxf(0.0, dist - float(step) * spacing)
					spawned.append(create_enemy(sid, child_dist, enemies))
					step += 1
			if idx + 1 < layers.size():
				current.layer_index = idx + 1
				current.hp = int(layers[idx + 1].hp)
			else:
				return {"enemy": null, "gold": gold, "spawned": spawned, "layers_broken": broken}
	return {"enemy": current, "gold": gold, "spawned": spawned, "layers_broken": broken}
