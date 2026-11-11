class_name GameWorld
extends Node2D

signal changed

const MAP_SIZE := Vector2(1280, 720)

var catalog: Catalog
var route: PathRoute
var sfx: SfxBank

var gold := 0
var lives := 0
var phase := "menu"
var wave_number := 0
var speed := 1
var now := 0.0
var placing := ""
var selected_id := -1

var towers: Array = []
var enemies: Array = []
var shots: Array = []
var floaters: Array = []
var pops: Array = []

var schedule: Array = []
var spawn_i := 0
var wave_time := 0.0
var gate_flash := 0.0
var shake := 0.0
var pointer := Vector2.ZERO
var pointer_inside := false

var base_position := Vector2.ZERO
var base_scale := Vector2.ONE
var toast_text := ""
var toast_until := 0
var banner_text := ""
var banner_until := 0
var auto_next_at := -1.0

const WAVE_BREATHER := 2.5
const FIRST_WAVE_DELAY := 3.0

var _next := 1
var _pending_dead: Array = []
var _pending_spawns: Array = []


func _ready() -> void:
	catalog = Catalog.new()
	route = PathRoute.new(catalog.map.waypoints)
	gold = int(catalog.balance.start_gold)
	lives = int(catalog.balance.start_lives)
	sfx = SfxBank.new()
	add_child(sfx)
	add_child(preload("res://scripts/map_view.gd").new())
	add_child(preload("res://scripts/fx_view.gd").new())


func _process(delta: float) -> void:
	_update_pointer()
	var scale := float(speed) if phase == "combat" else 1.0
	advance(minf(delta * scale, 0.15))
	_apply_xform()


func advance(seconds: float) -> void:
	var left := seconds
	while left > 0.00001:
		var step := minf(left, 1.0 / 30.0)
		_tick(step)
		left -= step
	changed.emit()


func apply_layout(pos: Vector2, map_scale: float) -> void:
	base_position = pos
	base_scale = Vector2.ONE * map_scale
	_apply_xform()


func play() -> void:
	if phase != "menu":
		return
	phase = "ready"
	auto_next_at = now + FIRST_WAVE_DELAY
	sfx.unlock()
	changed.emit()


func restart() -> void:
	gold = int(catalog.balance.start_gold)
	lives = int(catalog.balance.start_lives)
	wave_number = 0
	phase = "ready"
	speed = 1
	now = 0.0
	towers.clear()
	enemies.clear()
	shots.clear()
	floaters.clear()
	pops.clear()
	schedule.clear()
	spawn_i = 0
	wave_time = 0.0
	gate_flash = 0.0
	shake = 0.0
	placing = ""
	selected_id = -1
	toast_text = ""
	banner_text = ""
	auto_next_at = FIRST_WAVE_DELAY
	_pending_dead.clear()
	_pending_spawns.clear()
	sfx.unlock()
	changed.emit()


func toggle_speed() -> void:
	speed = 1 if speed == 2 else 2
	changed.emit()


func toggle_sound() -> void:
	sfx.enabled = not sfx.enabled
	if sfx.enabled:
		sfx.unlock()
	changed.emit()


func pick_tower(id: String) -> void:
	if phase == "menu" or phase == "won" or phase == "lost":
		return
	if placing == id:
		placing = ""
	else:
		placing = id
		selected_id = -1
	changed.emit()


func cancel_place() -> void:
	if placing == "":
		return
	placing = ""
	changed.emit()


func clear_selection() -> void:
	if selected_id == -1:
		return
	selected_id = -1
	changed.emit()


func try_place(x: float, y: float) -> String:
	if placing == "":
		return "Elige una torre de la tienda."
	if phase == "menu" or phase == "won" or phase == "lost":
		return "Ahora no puedes construir."
	var definition := catalog.tower(placing)
	var cost := int(definition.cost)
	if not Economy.can_afford(gold, cost):
		_toast("No hay oro suficiente.")
		sfx.play("error")
		return "No hay oro suficiente."
	var reason := Placement.block_reason(catalog.map, _tower_points(), x, y, float(catalog.balance.tower_gap))
	if reason != "":
		var msg := Placement.message(reason)
		_toast(msg)
		sfx.play("error")
		return msg
	gold -= cost
	towers.append({
		"id": _alloc(),
		"def_id": placing,
		"x": x,
		"y": y,
		"upgrades": [],
		"invested": cost,
		"cooldown": 0.0,
		"target_mode": "first",
		"aim": 0.0,
	})
	sfx.play("buy")
	changed.emit()
	return ""


func upgrade(upgrade_id: String) -> void:
	var tower := _tower_by_id(selected_id)
	if tower.is_empty():
		return
	if (tower.upgrades as Array).has(upgrade_id):
		return
	var up := catalog.upgrade_def(str(tower.def_id), upgrade_id)
	if up.is_empty():
		return
	var cost := int(up.cost)
	if not Economy.can_afford(gold, cost):
		_toast("No hay oro suficiente.")
		sfx.play("error")
		changed.emit()
		return
	gold -= cost
	(tower.upgrades as Array).append(upgrade_id)
	tower.invested = int(tower.invested) + cost
	sfx.play("buy")
	changed.emit()


func sell() -> void:
	var index := -1
	for i in towers.size():
		if int(towers[i].id) == selected_id:
			index = i
			break
	if index < 0:
		return
	var refund := Economy.sell_refund(int(towers[index].invested), float(catalog.balance.sell_ratio))
	gold += refund
	towers.remove_at(index)
	selected_id = -1
	sfx.play("buy")
	_toast("Torre vendida por %d de oro." % refund)
	changed.emit()


func cycle_target() -> void:
	var tower := _tower_by_id(selected_id)
	if tower.is_empty():
		return
	tower.target_mode = Targeting.next_mode(str(tower.target_mode))
	changed.emit()


func start_wave() -> void:
	if phase != "ready":
		return
	if wave_number >= catalog.waves.size():
		return
	wave_number += 1
	schedule = WaveLogic.build_schedule(catalog.waves[wave_number - 1], float(catalog.balance.group_gap))
	spawn_i = 0
	wave_time = 0.0
	phase = "combat"
	auto_next_at = -1.0
	banner_text = ""
	sfx.play("wave")
	changed.emit()


func wave_label() -> String:
	var total := catalog.waves.size()
	if phase == "menu" or (phase == "ready" and wave_number == 0):
		return "Oleada 1/%d" % total
	if phase == "ready":
		return "Oleada %d/%d" % [mini(wave_number + 1, total), total]
	return "Oleada %d/%d" % [clampi(wave_number, 1, total), total]


func preview_text() -> String:
	if phase == "won":
		return "La aldea está a salvo"
	if phase == "lost":
		return "La puerta ha caído"
	if placing != "":
		var definition := catalog.tower(placing)
		return "Coloca: %s. Toca el prado. Clic derecho cancela." % definition.name
	var index := wave_number if phase != "combat" else wave_number - 1
	if index < 0 or index >= catalog.waves.size():
		return ""
	var wait := seconds_until_next()
	if wait >= 0:
		return "La oleada %d empieza en %d s" % [mini(wave_number + 1, catalog.waves.size()), wait]
	var prefix := "En curso: " if phase == "combat" else "Siguiente: "
	return prefix + WaveLogic.describe(catalog.waves[index], catalog.enemies)


func seconds_until_next() -> int:
	if phase != "ready" or auto_next_at < 0.0:
		return -1
	return maxi(int(ceil(auto_next_at - now)), 0)


func current_toast() -> String:
	if Time.get_ticks_msec() > toast_until:
		return ""
	return toast_text


func current_banner() -> String:
	if Time.get_ticks_msec() > banner_until:
		return ""
	return banner_text


func selected_tower() -> Dictionary:
	return _tower_by_id(selected_id)


func draw_dynamic(c: CanvasItem) -> void:
	_draw_ranges(c)
	var items: Array = []
	for tower in towers:
		items.append({"y": float(tower.y), "kind": "tower", "data": tower})
	for enemy in enemies:
		items.append({"y": _enemy_pos(enemy).y, "kind": "enemy", "data": enemy})
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.y) < float(b.y)
	)
	for item in items:
		if item.kind == "tower":
			_draw_tower(c, item.data)
		else:
			_draw_enemy(c, item.data)
	for shot in shots:
		_draw_shot(c, shot)
	for enemy in enemies:
		_draw_bar(c, enemy)
	_draw_fx(c)


func _tick(dt: float) -> void:
	now += dt
	if phase == "ready" and auto_next_at >= 0.0 and now >= auto_next_at:
		start_wave()
	if phase == "combat":
		_spawn_due()
		wave_time += dt
		_move_enemies(dt)
		if phase == "combat":
			_fire_towers(dt)
			_move_shots(dt)
		if phase == "combat":
			_check_clear()
	_decay_fx(dt)


func _spawn_due() -> void:
	while spawn_i < schedule.size() and float(schedule[spawn_i].time) <= wave_time:
		_add_enemy(str(schedule[spawn_i].enemy_id), 0.0)
		spawn_i += 1


func _add_enemy(def_id: String, distance: float) -> void:
	var state := LayerLogic.create_enemy(def_id, distance, catalog.enemies)
	var id := _alloc()
	var entry := {
		"id": id,
		"state": state,
		"lateral": float((id % 5) - 2) * 8.0,
		"bob": float(id) * 0.73,
		"flash": 0.0,
		"age": 0.0,
	}
	_pending_spawns.append(entry)


func _move_enemies(dt: float) -> void:
	_flush_enemies()
	var doomed := false
	for enemy in enemies:
		var state: Dictionary = enemy.state
		var spd := LayerLogic.speed_of(state, catalog.enemies, now)
		state.distance = float(state.distance) + spd * dt
		enemy.age = float(enemy.age) + dt
		enemy.flash = maxf(float(enemy.flash) - dt, 0.0)
		if route.reached(float(state.distance)):
			var lost := LayerLogic.rbe(str(state.def_id), int(state.layer_index), catalog.enemies)
			lives = maxi(0, lives - lost)
			var gate: Vector2 = route.pose(route.total).pos
			_floater(gate + Vector2(-8, -20), "-%d" % lost, Color("ff6a5a"))
			sfx.play("leak")
			gate_flash = 0.45
			_pending_dead.append(int(enemy.id))
			if lives <= 0 and phase != "lost":
				phase = "lost"
				doomed = true
	if doomed:
		sfx.play("lose")
		changed.emit()
	_flush_enemies()


func _fire_towers(dt: float) -> void:
	var targets := _targetables()
	for tower in towers:
		tower.cooldown = float(tower.cooldown) - dt
		var stats := catalog.stats_for(str(tower.def_id), tower.upgrades)
		var origin := Vector2(float(tower.x), float(tower.y))
		var pick := Targeting.pick(targets, origin, float(stats.range), str(tower.target_mode))
		if not pick.is_empty():
			tower.aim = origin.angle_to_point(Vector2(float(pick.x), float(pick.y)))
		if float(tower.cooldown) <= 0.0 and not pick.is_empty():
			tower.cooldown = float(stats.cooldown)
			_spawn_shot(tower, stats, pick)
			var kind := str(catalog.tower(str(tower.def_id)).kind)
			sfx.shoot(kind)
			if kind == "shell":
				shake = maxf(shake, 0.12)


func _spawn_shot(tower: Dictionary, stats: Dictionary, target: Dictionary) -> void:
	var origin := Vector2(float(tower.x), float(tower.y))
	var aim := float(tower.aim)
	var kind := str(catalog.tower(str(tower.def_id)).kind)
	var shot_speed := float(stats.projectile_speed)
	var from := origin + Vector2(30, -6) if kind == "shell" else origin + Vector2.RIGHT.rotated(aim) * 18.0
	var dest := Vector2(float(target.x), float(target.y))
	if kind == "shell":
		dest = _lead(origin, int(target.id), shot_speed)
	var dir := dest - from
	if dir.length() < 1.0:
		dir = Vector2.RIGHT.rotated(aim)
	dir = dir.normalized()
	shots.append({
		"kind": kind,
		"x": from.x,
		"y": from.y,
		"vx": dir.x * shot_speed,
		"vy": dir.y * shot_speed,
		"damage": int(stats.damage),
		"splash": float(stats.splash),
		"pierce": int(stats.pierce),
		"hits": [],
		"slow_duration": float(stats.slow_duration),
		"slow_factor": float(stats.slow_factor),
		"dest_x": dest.x,
		"dest_y": dest.y,
		"homing_id": int(target.id) if kind != "shell" else -1,
		"age": 0.0,
	})


func _move_shots(dt: float) -> void:
	var kept: Array = []
	for shot in shots:
		var x0 := float(shot.x)
		var y0 := float(shot.y)
		if str(shot.kind) != "shell" and int(shot.homing_id) != -1 and (shot.hits as Array).is_empty():
			var tgt := _enemy_by_id(int(shot.homing_id))
			if not tgt.is_empty():
				var tp := _enemy_pos(tgt)
				var spd := Vector2(float(shot.vx), float(shot.vy)).length()
				var dir := (tp - Vector2(x0, y0)).normalized()
				if dir.length() > 0.1:
					shot.vx = dir.x * spd
					shot.vy = dir.y * spd
		var x1 := x0 + float(shot.vx) * dt
		var y1 := y0 + float(shot.vy) * dt
		shot.x = x1
		shot.y = y1
		shot.age = float(shot.age) + dt
		var alive := true
		if str(shot.kind) == "shell":
			var dest := Vector2(float(shot.dest_x), float(shot.dest_y))
			var d0 := Vector2(x0, y0).distance_to(dest)
			var d1 := Vector2(x1, y1).distance_to(dest)
			if d1 < 16.0 or d1 > d0:
				_explode(shot, dest)
				alive = false
		else:
			alive = _bolt_hit(shot, x0, y0, x1, y1)
		if alive and (float(shot.age) > 3.2 or x1 < -120.0 or y1 < -120.0 or x1 > 1400.0 or y1 > 860.0):
			alive = false
		if alive:
			kept.append(shot)
		_flush_enemies()
	shots = kept


func _bolt_hit(shot: Dictionary, x0: float, y0: float, x1: float, y1: float) -> bool:
	var found: Array = []
	for enemy in enemies:
		if _pending_dead.has(int(enemy.id)) or (shot.hits as Array).has(int(enemy.id)):
			continue
		var pos := _enemy_pos(enemy)
		var layer := LayerLogic.layer_of(enemy.state, catalog.enemies)
		var reach := 12.0 + float(layer.radius) * 0.55
		if Placement.dist_to_segment(pos.x, pos.y, x0, y0, x1, y1) <= reach:
			found.append({
				"enemy": enemy,
				"t": Placement.segment_t(pos.x, pos.y, x0, y0, x1, y1),
				"pos": pos,
			})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.t) < float(b.t)
	)
	for hit in found:
		if (shot.hits as Array).size() >= int(shot.pierce):
			break
		var enemy: Dictionary = hit.enemy
		(shot.hits as Array).append(int(enemy.id))
		if str(shot.kind) == "orb":
			_hurt(enemy, int(shot.damage), float(shot.slow_duration), float(shot.slow_factor))
			_splash_others(shot, hit.pos, int(enemy.id))
			return false
		_hurt(enemy, int(shot.damage), 0.0, 1.0)
	return (shot.hits as Array).size() < int(shot.pierce)


func _splash_others(shot: Dictionary, at: Vector2, ignore_id: int) -> void:
	var radius := float(shot.splash)
	for enemy in enemies:
		if int(enemy.id) == ignore_id or _pending_dead.has(int(enemy.id)):
			continue
		var pos := _enemy_pos(enemy)
		var layer := LayerLogic.layer_of(enemy.state, catalog.enemies)
		if pos.distance_to(at) <= radius + float(layer.radius):
			_hurt(enemy, int(shot.damage), float(shot.slow_duration), float(shot.slow_factor))


func _explode(shot: Dictionary, at: Vector2) -> void:
	var snapshot: Array = enemies.duplicate()
	for enemy in snapshot:
		if _pending_dead.has(int(enemy.id)):
			continue
		var pos := _enemy_pos(enemy)
		var layer := LayerLogic.layer_of(enemy.state, catalog.enemies)
		if pos.distance_to(at) <= float(shot.splash) + float(layer.radius):
			_hurt(enemy, int(shot.damage), float(shot.slow_duration), float(shot.slow_factor))
	pops.append({"x": at.x, "y": at.y, "age": 0.0, "color": Color("ffb45a")})
	sfx.play("pop")


func _hurt(enemy: Dictionary, amount: int, slow_dur: float, slow_factor: float) -> void:
	if _pending_dead.has(int(enemy.id)):
		return
	var result := LayerLogic.damage_enemy(enemy.state, amount, catalog.enemies, float(catalog.balance.split_spacing))
	var gold_gain := int(result.gold)
	if gold_gain > 0:
		gold += gold_gain
		_floater(_enemy_pos(enemy) + Vector2(-6, -16), "+%d" % gold_gain, Color("ffe14a"))
	enemy.flash = 0.09
	if int(result.layers_broken) > 0:
		var pos := _enemy_pos(enemy)
		pops.append({"x": pos.x, "y": pos.y, "age": 0.0, "color": Color("ffe39a")})
		sfx.play("pop")
	if result.enemy == null:
		_pending_dead.append(int(enemy.id))
	else:
		enemy.state = result.enemy
		if slow_dur > 0.0:
			enemy.state = LayerLogic.apply_slow(enemy.state, now, slow_dur, slow_factor)
	for child in result.spawned:
		var state: Dictionary = child
		if slow_dur > 0.0:
			state = LayerLogic.apply_slow(state, now, slow_dur * 0.65, slow_factor)
		var id := _alloc()
		_pending_spawns.append({
			"id": id,
			"state": state,
			"lateral": float((id % 5) - 2) * 8.0,
			"bob": float(id),
			"flash": 0.0,
			"age": 0.0,
		})


func _check_clear() -> void:
	if spawn_i < schedule.size() or not enemies.is_empty():
		return
	var bonus := Economy.wave_clear_bonus(wave_number, int(catalog.balance.bonus_base), int(catalog.balance.bonus_per_wave))
	gold += bonus
	if wave_number >= catalog.waves.size():
		phase = "won"
		banner_text = ""
		sfx.play("win")
	else:
		phase = "ready"
		auto_next_at = now + WAVE_BREATHER
		banner_text = "Oleada %d superada. +%d de oro. La siguiente sale sola." % [wave_number, bonus]
		banner_until = Time.get_ticks_msec() + 3200
		sfx.play("wave")
		changed.emit()


func _flush_enemies() -> void:
	if not _pending_dead.is_empty():
		var dead := {}
		for id in _pending_dead:
			dead[id] = true
		var kept: Array = []
		for enemy in enemies:
			if not dead.has(int(enemy.id)):
				kept.append(enemy)
		enemies = kept
		_pending_dead.clear()
	for entry in _pending_spawns:
		enemies.append(entry)
	_pending_spawns.clear()


func _decay_fx(dt: float) -> void:
	var next_floaters: Array = []
	for floater in floaters:
		floater.age = float(floater.age) + dt
		if float(floater.age) < float(floater.life):
			next_floaters.append(floater)
	floaters = next_floaters
	var next_pops: Array = []
	for pop in pops:
		pop.age = float(pop.age) + dt
		if float(pop.age) < 0.35:
			next_pops.append(pop)
	pops = next_pops
	if floaters.size() > 40:
		floaters = floaters.slice(floaters.size() - 40)
	shake = maxf(shake - dt, 0.0)
	gate_flash = maxf(gate_flash - dt, 0.0)


func _targetables() -> Array:
	var out: Array = []
	for enemy in enemies:
		var pos := _enemy_pos(enemy)
		var layer := LayerLogic.layer_of(enemy.state, catalog.enemies)
		out.append({
			"id": int(enemy.id),
			"x": pos.x,
			"y": pos.y,
			"distance": float(enemy.state.distance),
			"hp": int(enemy.state.hp),
			"radius": float(layer.radius),
		})
	return out


func _enemy_pos(enemy: Dictionary) -> Vector2:
	var pose: Dictionary = route.pose(float(enemy.state.distance))
	var side := Vector2(-sin(pose.angle), cos(pose.angle)) * float(enemy.lateral)
	var bob := sin(now * 6.0 + float(enemy.bob)) * 2.2
	return pose.pos + side + Vector2(0, bob)


func _enemy_by_id(id: int) -> Dictionary:
	if _pending_dead.has(id):
		return {}
	for enemy in enemies:
		if int(enemy.id) == id:
			return enemy
	return {}


func _tower_by_id(id: int) -> Dictionary:
	for tower in towers:
		if int(tower.id) == id:
			return tower
	return {}


func _tower_at(point: Vector2) -> int:
	var best := -1
	var best_d := 36.0
	for tower in towers:
		var d := point.distance_to(Vector2(float(tower.x), float(tower.y)))
		if d <= best_d:
			best_d = d
			best = int(tower.id)
	return best


func _tower_points() -> Array:
	var pts: Array = []
	for tower in towers:
		pts.append({"x": tower.x, "y": tower.y})
	return pts


func _lead(origin: Vector2, enemy_id: int, shot_speed: float) -> Vector2:
	var enemy := _enemy_by_id(enemy_id)
	if enemy.is_empty():
		return origin
	var along := float(enemy.state.distance)
	var spd := LayerLogic.speed_of(enemy.state, catalog.enemies, now)
	var pos := _enemy_pos(enemy)
	var t := origin.distance_to(pos) / maxf(shot_speed, 1.0)
	for _i in 3:
		var future := minf(route.total - 1.0, along + spd * t)
		pos = route.pose(future).pos
		t = origin.distance_to(pos) / maxf(shot_speed, 1.0)
	return pos


func _floater(pos: Vector2, text: String, color: Color) -> void:
	floaters.append({"pos": pos, "text": text, "color": color, "age": 0.0, "life": 0.75})


func _toast(msg: String) -> void:
	toast_text = msg
	toast_until = Time.get_ticks_msec() + 1700


func _alloc() -> int:
	var id := _next
	_next += 1
	return id


func _update_pointer() -> void:
	pointer = get_local_mouse_position()
	var hovered := get_viewport().gui_get_hovered_control()
	pointer_inside = hovered == null and pointer.x >= 0.0 and pointer.y >= 0.0 and pointer.x <= MAP_SIZE.x and pointer.y <= MAP_SIZE.y


func _apply_xform() -> void:
	var kick := Vector2.ZERO
	if shake > 0.0:
		kick = Vector2(sin(now * 73.0), cos(now * 61.0)) * shake * 7.0
	position = base_position + kick
	scale = base_scale


func _unhandled_input(event: InputEvent) -> void:
	if phase == "menu" or phase == "won" or phase == "lost":
		return
	if event is InputEventMouseButton and event.pressed:
		var button := event as InputEventMouseButton
		var point := get_local_mouse_position()
		if button.button_index == MOUSE_BUTTON_RIGHT:
			cancel_place()
			clear_selection()
			get_viewport().set_input_as_handled()
			return
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		if point.x < 0.0 or point.y < 0.0 or point.x > MAP_SIZE.x or point.y > MAP_SIZE.y:
			return
		var hit := _tower_at(point)
		if hit != -1:
			selected_id = hit
			placing = ""
			sfx.play("buy")
			changed.emit()
			get_viewport().set_input_as_handled()
			return
		if placing != "":
			try_place(point.x, point.y)
			get_viewport().set_input_as_handled()
			return
		clear_selection()


func _draw_ranges(c: CanvasItem) -> void:
	if placing != "" and pointer_inside:
		var stats := catalog.stats_for(placing, [])
		var reason := Placement.block_reason(catalog.map, _tower_points(), pointer.x, pointer.y, float(catalog.balance.tower_gap))
		var ok := reason == "" and Economy.can_afford(gold, int(catalog.tower(placing).cost))
		var fill := Color(0.45, 1.0, 0.6, 0.16) if ok else Color(1.0, 0.35, 0.28, 0.16)
		var ring := Color(0.9, 1.0, 0.95, 0.9) if ok else Color(1.0, 0.75, 0.7, 0.9)
		c.draw_circle(pointer, float(stats.range), fill)
		c.draw_arc(pointer, float(stats.range), 0.0, TAU, 64, ring, 2.5, true)
		DrawArt.draw_tower(c, placing, pointer, 0.0, 0.55 if ok else 0.35)
	if selected_id != -1:
		var tower := _tower_by_id(selected_id)
		if not tower.is_empty():
			var stats := catalog.stats_for(str(tower.def_id), tower.upgrades)
			var at := Vector2(float(tower.x), float(tower.y))
			c.draw_circle(at, float(stats.range), Color(1.0, 0.86, 0.4, 0.13))
			c.draw_arc(at, float(stats.range), 0.0, TAU, 64, Color(1.0, 0.93, 0.7, 0.95), 2.5, true)
			c.draw_arc(at, 30.0, 0.0, TAU, 32, Color("fff6d0"), 4.0, true)


func _draw_tower(c: CanvasItem, tower: Dictionary) -> void:
	DrawArt.draw_tower(c, str(tower.def_id), Vector2(float(tower.x), float(tower.y)), float(tower.aim), 1.0)


func _draw_enemy(c: CanvasItem, enemy: Dictionary) -> void:
	var layer := LayerLogic.layer_of(enemy.state, catalog.enemies)
	var look := str(layer.look)
	var pop := clampf(float(enemy.age) * 5.0, 0.0, 1.0)
	var scale := DrawArt.enemy_scale(look) * lerpf(0.35, 1.0, pop)
	var slowed := now < float(enemy.state.slow_until)
	DrawArt.draw_enemy(c, _enemy_pos(enemy), look, scale, float(enemy.flash), slowed)


func _draw_shot(c: CanvasItem, shot: Dictionary) -> void:
	var pos := Vector2(float(shot.x), float(shot.y))
	var vel := Vector2(float(shot.vx), float(shot.vy))
	var angle := vel.angle()
	match str(shot.kind):
		"orb":
			c.draw_circle(pos, 9.0, Color("5b348f"))
			c.draw_circle(pos, 6.0, Color("c9a6ff"))
			c.draw_circle(pos, 2.5, Color.WHITE)
		"shell":
			c.draw_circle(pos, 7.0, Color("1c140c"))
			c.draw_circle(pos + Vector2(-2, -2), 3.0, Color("9aa3ad"))
		_:
			c.draw_set_transform(pos, angle, Vector2.ONE)
			c.draw_line(Vector2(-12, 0), Vector2(8, 0), Color("f4efe4"), 2.5, true)
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(8, 0), Vector2(2, -3.5), Vector2(2, 3.5),
			]), Color("c4473a"))
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_bar(c: CanvasItem, enemy: Dictionary) -> void:
	var layer := LayerLogic.layer_of(enemy.state, catalog.enemies)
	var max_hp := maxi(int(layer.hp), 1)
	var hp := int(enemy.state.hp)
	var total := (catalog.enemies[str(enemy.state.def_id)].layers as Array).size()
	var remaining := total - int(enemy.state.layer_index)
	if max_hp <= 1 and remaining <= 1:
		return
	var pos := _enemy_pos(enemy)
	var w := 30.0
	var origin := pos + Vector2(-w * 0.5, -28.0 * DrawArt.enemy_scale(str(layer.look)))
	c.draw_rect(Rect2(origin + Vector2(-1, -1), Vector2(w + 2, 7)), Color("1a120c"), true)
	var col := Color("8fd4ff") if now < float(enemy.state.slow_until) else Color("8ee06a")
	c.draw_rect(Rect2(origin, Vector2(w * float(hp) / float(max_hp), 5)), col, true)
	for i in remaining:
		c.draw_circle(origin + Vector2(4 + i * 7, -6), 2.2, Color("ffe08a"))


func _draw_fx(c: CanvasItem) -> void:
	if gate_flash > 0.0:
		var gate: Vector2 = route.pose(route.total).pos
		c.draw_circle(gate, 40.0, Color(1, 0.25, 0.18, gate_flash))
	for pop in pops:
		var t := clampf(float(pop.age) / 0.35, 0.0, 1.0)
		var col: Color = pop.color
		col.a = 1.0 - t
		c.draw_arc(Vector2(float(pop.x), float(pop.y)), lerpf(8.0, 30.0, t), 0.0, TAU, 18, col, 3.0, true)
	var font := ThemeDB.fallback_font
	if font == null:
		return
	for floater in floaters:
		var t := float(floater.age) / float(floater.life)
		var col: Color = floater.color
		col.a = 1.0 - t
		var at: Vector2 = floater.pos + Vector2(0, -t * 28.0)
		c.draw_string(font, at, str(floater.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, col)
