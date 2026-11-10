extends Control

var world: GameWorld
var hud: GameHud


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color("5aa83c")
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)
	world = GameWorld.new()
	add_child(world)
	hud = GameHud.new()
	hud.setup(world)
	add_child(hud)
	world.changed.connect(hud.refresh)
	get_viewport().size_changed.connect(_layout)
	_layout()
	hud.refresh()


func _layout() -> void:
	var vp := get_viewport_rect().size
	var map_scale := minf(vp.x / GameWorld.MAP_SIZE.x, vp.y / GameWorld.MAP_SIZE.y)
	var origin := (vp - GameWorld.MAP_SIZE * map_scale) * 0.5
	world.apply_layout(origin, map_scale)
	hud.layout(vp, origin, map_scale)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_SPACE:
			get_viewport().set_input_as_handled()
			if world.phase == "menu":
				world.play()
			elif world.phase == "ready":
				world.start_wave()
			elif world.phase == "won" or world.phase == "lost":
				world.restart()
		KEY_1, KEY_KP_1:
			world.pick_tower("arquero")
			get_viewport().set_input_as_handled()
		KEY_2, KEY_KP_2:
			world.pick_tower("mago")
			get_viewport().set_input_as_handled()
		KEY_3, KEY_KP_3:
			world.pick_tower("canon")
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			world.cancel_place()
			world.clear_selection()
			get_viewport().set_input_as_handled()
		KEY_F:
			world.toggle_speed()
			get_viewport().set_input_as_handled()
