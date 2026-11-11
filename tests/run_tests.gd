extends SceneTree

var failures: Array[String] = []

const PLAN_SRC := [
	{"id": "arquero", "x": 180.0, "y": 170.0},
	{"id": "arquero", "x": 170.0, "y": 370.0},
	{"id": "mago", "x": 430.0, "y": 380.0},
	{"id": "canon", "x": 450.0, "y": 610.0},
	{"id": "arquero", "x": 760.0, "y": 310.0},
	{"id": "canon", "x": 990.0, "y": 380.0},
	{"id": "arquero", "x": 800.0, "y": 400.0},
	{"id": "arquero", "x": 530.0, "y": 300.0},
]

const UPGRADES := {
	"arquero": ["rapido", "perfora"],
	"mago": ["estallido", "escarcha"],
	"canon": ["metralla", "alcance"],
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_economy()
	_test_layers()
	_test_waves()
	_test_placement()
	_test_targeting()
	_test_smoke_and_match()
	if failures.is_empty():
		print("ALL TESTS PASSED")
		quit(0)
	else:
		for failure in failures:
			print("FAIL: ", failure)
		print("%d TESTS FAILED" % failures.size())
		quit(1)


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)
		print("FAIL: ", msg)


func _test_economy() -> void:
	var cat := Catalog.new()
	check(not Economy.can_afford(100, 120), "oro insuficiente")
	var spent := Economy.try_spend(200, 120)
	check(bool(spent.ok) and int(spent.gold) == 80, "el gasto resta el coste")
	var blocked := Economy.try_spend(50, 120)
	check(not bool(blocked.ok) and int(blocked.gold) == 50, "sin oro no se gasta")
	check(Economy.sell_refund(100, 0.7) == 70, "la venta devuelve el 70%")
	check(Economy.sell_refund(0, 0.7) == 0, "vender cero")
	check(Economy.wave_clear_bonus(1, 60, 15) == 75, "bono de la oleada 1")
	check(Economy.wave_clear_bonus(10, 60, 15) == 210, "bono de la oleada 10")
	check(Economy.can_afford(int(cat.balance.start_gold), int(cat.towers.arquero.cost)), "el oro inicial alcanza para un arquero")
	var trio := int(cat.towers.arquero.cost) + int(cat.towers.canon.cost) + int(cat.towers.mago.cost)
	check(not Economy.can_afford(int(cat.balance.start_gold), trio), "las tres torres no caben en el oro inicial")
	check(cat.tower_order.size() == 3, "hay 3 torres")
	for id in cat.tower_order:
		check((cat.towers[id].upgrades as Array).size() == 2, "%s tiene 2 mejoras" % id)


func _test_layers() -> void:
	var enemies: Dictionary = Catalog.new().enemies
	var hob := LayerLogic.create_enemy("hobgoblin", 40.0, enemies)
	var hp_before := int(hob.hp)
	var nick := LayerLogic.damage_enemy(hob, 1, enemies)
	check(int(hob.hp) == hp_before, "el daño no muta el original")
	check(nick.enemy != null and int(nick.enemy.hp) == hp_before - 1, "un golpe no rompe al hobgoblin")
	check((nick.spawned as Array).is_empty(), "no hay crías con vida restante")
	var dead_hob := LayerLogic.damage_enemy(LayerLogic.create_enemy("hobgoblin", 80.0, enemies), 99, enemies)
	check(dead_hob.enemy == null, "el hobgoblin muere")
	check((dead_hob.spawned as Array).size() == 2, "el hobgoblin suelta 2 goblins")
	check(str(dead_hob.spawned[0].def_id) == "goblin" and str(dead_hob.spawned[1].def_id) == "goblin", "las crías son goblins")
	check(float(dead_hob.spawned[0].distance) > float(dead_hob.spawned[1].distance), "las crías se separan")
	check(float(dead_hob.spawned[0].distance) < 80.0, "salen detrás del padre")
	check(int(dead_hob.spawned[0].hp) == int(enemies.goblin.layers[0].hp), "la cría sale con toda su vida")
	var rider := LayerLogic.damage_enemy(LayerLogic.create_enemy("jinete", 10.0, enemies), 99, enemies)
	check(int(rider.gold) == int(enemies.jinete.layers[0].reward), "el oro es solo de la capa rota")
	check((rider.spawned as Array).size() == 1 and str(rider.spawned[0].def_id) == "goblin", "el jinete deja un goblin a pie")
	var armor_hp := int(enemies.ogro.layers[0].hp)
	var ogre := LayerLogic.create_enemy("ogro", 100.0, enemies)
	var grazed := LayerLogic.damage_enemy(ogre, armor_hp - 1, enemies)
	check(grazed.enemy != null and int(grazed.enemy.layer_index) == 0, "la armadura aguanta")
	var peeled := LayerLogic.damage_enemy(grazed.enemy, 1, enemies)
	check(peeled.enemy != null and int(peeled.enemy.layer_index) == 1, "al romperse la armadura queda el ogro")
	check((peeled.spawned as Array).is_empty(), "la armadura no invoca crías")
	var body_hp := int(enemies.ogro.layers[1].hp)
	var fallen := LayerLogic.damage_enemy(peeled.enemy, body_hp, enemies)
	check(fallen.enemy == null, "el cuerpo del ogro muere")
	check((fallen.spawned as Array).size() == 2, "el ogro suelta 2 hobgoblins")
	check(str(fallen.spawned[0].def_id) == "hobgoblin", "son hobgoblins")
	var burst := LayerLogic.damage_enemy(LayerLogic.create_enemy("ogro", 50.0, enemies), 999, enemies)
	check(int(burst.layers_broken) == 2, "un golpe enorme rompe las dos capas")
	check((burst.spawned as Array).size() == 2, "el exceso no mata a las crías en el mismo golpe")
	var troll := LayerLogic.create_enemy("trol", 0.0, enemies)
	var hide := LayerLogic.damage_enemy(troll, int(enemies.trol.layers[0].hp), enemies)
	check(hide.enemy != null and int(hide.enemy.layer_index) == 1, "el trol entra en furia")
	check((hide.spawned as Array).is_empty(), "la piel del trol no suelta crías")
	var rage := LayerLogic.damage_enemy(hide.enemy, int(enemies.trol.layers[1].hp), enemies)
	check(rage.enemy == null, "el trol cae")
	var kinds := PackedStringArray()
	for child in rage.spawned:
		kinds.append(str(child.def_id))
	check(kinds.count("hobgoblin") == 1 and kinds.count("goblin") == 2, "el trol suelta un hobgoblin y dos goblins")
	check(LayerLogic.rbe("trol", 0, enemies) > LayerLogic.rbe("ogro", 0, enemies), "el trol cuesta más vidas que el ogro")
	check(LayerLogic.rbe("ogro", 0, enemies) > LayerLogic.rbe("goblin", 0, enemies), "el ogro cuesta más vidas que un goblin")


func _test_waves() -> void:
	var cat := Catalog.new()
	check(cat.waves.size() == 10, "hay 10 oleadas")
	check(cat.enemies.size() == 5, "hay 5 tipos de enemigo")
	var previous := 0
	for i in cat.waves.size():
		var threat := WaveLogic.wave_rbe(cat.waves[i], cat.enemies)
		check(threat > previous, "la oleada %d sube de amenaza (%d <= %d)" % [i + 1, threat, previous])
		previous = threat
	var gap := float(cat.balance.group_gap)
	var schedule := WaveLogic.build_schedule(cat.waves[0], gap)
	check(schedule.size() == int(cat.waves[0].groups[0].count), "la cola coincide con el grupo")
	check(is_equal_approx(float(schedule[0].time), 0.0), "el primero sale al instante")
	var interval := float(cat.waves[0].groups[0].interval)
	check(is_equal_approx(float(schedule[1].time), interval), "el intervalo separa a los goblins")
	var described := WaveLogic.describe(cat.waves[0], cat.enemies)
	check(described.contains("goblins"), "el resumen nombra a los goblins")


func _test_placement() -> void:
	var map: Dictionary = Catalog.new().map
	check(Placement.block_reason(map, [], 180, 170, 58) == "", "el prado alto es construible")
	check(Placement.block_reason(map, [], 200, 250, 58) == "path", "el camino está bloqueado")
	check(Placement.block_reason(map, [], 10, 10, 58) == "margin", "el margen no se construye")
	check(Placement.block_reason(map, [{"x": 180, "y": 170}], 190, 180, 58) == "gap", "hay que separar las torres")
	check(Placement.block_reason(map, [], 1120, 500, 58) == "blocked", "el castillo está ocupado")
	for spot in PLAN_SRC:
		var reason := Placement.block_reason(map, [], float(spot.x), float(spot.y), 58)
		check(reason == "", "el plan %s está libre (%s)" % [spot, reason])


func _test_targeting() -> void:
	var units := [
		{"id": 1, "x": 0.0, "y": 0.0, "distance": 100.0, "hp": 5, "radius": 10.0},
		{"id": 2, "x": 30.0, "y": 0.0, "distance": 400.0, "hp": 1, "radius": 10.0},
	]
	var origin := Vector2(0, 40)
	check(int(Targeting.pick(units, origin, 500, "first").id) == 2, "primero es el más avanzado")
	check(int(Targeting.pick(units, origin, 500, "strong").id) == 1, "fuerte es el de más vida")
	check(int(Targeting.pick(units, origin, 500, "last").id) == 1, "último es el de atrás")
	check(int(Targeting.pick(units, origin, 500, "close").id) == 1, "cercano es el más próximo")
	check(Targeting.pick(units, Vector2(9000, 0), 10, "first").is_empty(), "fuera de alcance no hay blanco")
	check(Targeting.next_mode("first") == "strong", "el ciclo pasa a fuerte")
	check(Targeting.next_mode("close") == "first", "el ciclo vuelve a primero")
	check(Targeting.mode_label("first") == "Primero", "etiqueta en español")
	var cat := Catalog.new()
	var base := cat.stats_for("arquero", [])
	var fast := cat.stats_for("arquero", ["rapido"])
	check(float(fast.cooldown) < float(base.cooldown), "disparo rápido acorta la cadencia")
	check(int(cat.stats_for("arquero", ["perfora"]).pierce) == 3, "las flechas perforan a 3")
	check(float(cat.stats_for("mago", ["escarcha"]).slow_duration) > 0.0, "la escarcha ralentiza")
	check(float(cat.stats_for("canon", ["alcance"]).range) > float(cat.stats_for("canon", []).range), "el cañón gana alcance")


func _test_smoke_and_match() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	main.world.set_process(false)
	check(main.world.phase == "menu", "empieza en el menú")
	main.world.play()
	check(main.world.phase == "ready", "jugar deja la aldea en calma")
	main.world.pick_tower("arquero")
	var placed: String = main.world.try_place(180, 170)
	check(placed == "", "se coloca el arquero (%s)" % placed)
	check(main.world.towers.size() == 1, "hay una torre")
	check(main.world.gold == int(main.world.catalog.balance.start_gold) - int(main.world.catalog.tower("arquero").cost), "el oro baja al construir")
	main.world.start_wave()
	check(main.world.phase == "combat", "la oleada está en curso")
	var guard := 0
	while main.world.enemies.is_empty() and guard < 40:
		main.world.advance(0.1)
		guard += 1
	check(not main.world.enemies.is_empty(), "salen goblins al empezar la oleada")
	var guard_clear := 0
	while main.world.phase == "combat" and guard_clear < 500:
		main.world.advance(0.2)
		guard_clear += 1
	check(main.world.phase == "ready", "la primera oleada termina y deja un respiro")
	check(main.world.seconds_until_next() > 0, "la cuenta atrás de la siguiente oleada está activa")
	main.world.advance(5.0)
	check(main.world.phase == "combat" and main.world.wave_number == 2, "la oleada 2 empieza sola")
	main.queue_free()

	var match_scene := packed.instantiate()
	root.add_child(match_scene)
	var game: GameWorld = match_scene.world
	game.set_process(false)
	game.play()
	var plan: Array = []
	for spot in PLAN_SRC:
		var copy: Dictionary = spot.duplicate()
		copy.done = false
		plan.append(copy)
	var seen := 0
	var elapsed := 0.0
	while game.phase != "won" and game.phase != "lost" and elapsed < 900.0:
		if game.phase == "ready":
			for _i in 6:
				_ai(game, plan)
			if game.phase == "ready":
				game.start_wave()
		else:
			_ai(game, plan)
			game.advance(0.25)
			elapsed += 0.25
		if game.phase == "ready" and game.wave_number != seen:
			seen = game.wave_number
			print("oleada %d superada, vidas %d, oro %d, torres %d" % [seen, game.lives, game.gold, game.towers.size()])
	print("fin simulacion fase=%s oleada=%d vidas=%d oro=%d torres=%d t=%.0f" % [game.phase, game.wave_number, game.lives, game.gold, game.towers.size(), elapsed])
	check(game.phase == "won", "una defensa a lo largo del camino gana las 10 oleadas")
	match_scene.queue_free()


func _ai(game: GameWorld, plan: Array) -> void:
	var core_done := true
	for i in 4:
		if not plan[i].done:
			core_done = false
	var limit := plan.size() if core_done else 4
	for i in limit:
		var spot: Dictionary = plan[i]
		if spot.done:
			continue
		var cost := int(game.catalog.tower(str(spot.id)).cost)
		if not Economy.can_afford(game.gold, cost):
			break
		if game.placing != str(spot.id):
			game.pick_tower(str(spot.id))
		var err := game.try_place(float(spot.x), float(spot.y))
		if err == "":
			spot.done = true
			return
		check(false, "sitio ilegal %s: %s" % [spot, err])
		spot.done = true
		return
	if not core_done:
		return
	for tower in game.towers:
		var order: Array = UPGRADES[str(tower.def_id)]
		for upgrade_id in order:
			if (tower.upgrades as Array).has(upgrade_id):
				continue
			var up := game.catalog.upgrade_def(str(tower.def_id), str(upgrade_id))
			if Economy.can_afford(game.gold, int(up.cost)):
				game.selected_id = int(tower.id)
				game.upgrade(str(upgrade_id))
				return
