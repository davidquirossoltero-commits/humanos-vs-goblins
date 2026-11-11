extends Node2D

var mode := "menu"


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if mode == "lost":
		DrawArt.draw_enemy(self, Vector2(0, 4), "trol", 78.0, 0.0, false)
	elif mode == "won":
		DrawArt.draw_tower(self, "mago", Vector2(0, 2), -0.3, 1.0, 76.0)
	else:
		DrawArt.draw_tower(self, "arquero", Vector2(-52, 2), 0.2, 1.0, 74.0)
		DrawArt.draw_enemy(self, Vector2(52, 4), "goblin", 70.0, 0.0, false)
