class_name Catalog
extends RefCounted

var balance: Dictionary = {}
var towers: Dictionary = {}
var tower_order: Array = []
var enemies: Dictionary = {}
var waves: Array = []
var map: Dictionary = {}


func _init() -> void:
	balance = _read("res://data/balance.json")
	var tower_list: Array = _read("res://data/towers.json")
	for tower in tower_list:
		towers[str(tower.id)] = tower
		tower_order.append(str(tower.id))
	var enemy_list: Array = _read("res://data/enemies.json")
	for enemy in enemy_list:
		enemies[str(enemy.id)] = enemy
	waves = _read("res://data/waves.json")
	map = _read("res://data/map.json")


func tower(id: String) -> Dictionary:
	return towers[id]


func enemy(id: String) -> Dictionary:
	return enemies[id]


func stats_for(tower_id: String, upgrades: Array) -> Dictionary:
	var definition: Dictionary = towers[tower_id]
	var stats: Dictionary = (definition.stats as Dictionary).duplicate(true)
	for upgrade in definition.upgrades:
		if upgrades.has(upgrade.id):
			for key in upgrade.patch:
				stats[key] = upgrade.patch[key]
	stats.damage = int(stats.damage)
	stats.pierce = int(stats.pierce)
	stats.range = float(stats.range)
	stats.cooldown = float(stats.cooldown)
	stats.projectile_speed = float(stats.projectile_speed)
	stats.splash = float(stats.splash)
	stats.slow_duration = float(stats.get("slow_duration", 0.0))
	stats.slow_factor = float(stats.get("slow_factor", 1.0))
	return stats


func upgrade_def(tower_id: String, upgrade_id: String) -> Dictionary:
	for upgrade in towers[tower_id].upgrades:
		if str(upgrade.id) == upgrade_id:
			return upgrade
	return {}


static func _read(path: String) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("No se pudo leer %s" % path)
		return null
	var data = JSON.parse_string(text)
	if data == null:
		push_error("JSON inválido: %s" % path)
	return data
