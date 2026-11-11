extends Node2D


func _ready() -> void:
	z_index = 0
	var world := get_parent() as GameWorld
	if world and not world.changed.is_connected(queue_redraw):
		world.changed.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var world := get_parent() as GameWorld
	if world == null or world.catalog == null:
		return
	DrawMap.render(self, world.catalog.map)
