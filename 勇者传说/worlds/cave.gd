extends World
@onready var baor: CharacterBody2D = $Baor


func _on_baor_died() -> void:
	await get_tree().create_timer(1).timeout
	Game.change_scene("res://game_end_screen.tscn",{
		duration = 1,
	})
