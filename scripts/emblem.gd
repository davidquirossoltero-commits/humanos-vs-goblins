extends Node2D

var mode := "menu"


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if mode == "lost":
		DrawArt.draw_enemy(self, Vector2(0, 6), "trol", 0.72, 0.0, false)
	elif mode == "won":
		DrawArt.draw_tower(self, "mago", Vector2(0, 12), -0.4, 1.0)
	else:
		DrawArt.draw_tower(self, "arquero", Vector2(-42, 12), 0.35, 1.0)
		DrawArt.draw_enemy(self, Vector2(44, 8), "goblin", 1.0, 0.0, false)
