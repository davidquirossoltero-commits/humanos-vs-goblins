extends Node2D


func _ready() -> void:
	z_index = 2


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var world := get_parent() as GameWorld
	if world:
		world.draw_dynamic(self)
