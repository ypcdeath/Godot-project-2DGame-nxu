extends Control

@onready var v: VBoxContainer = $V
@onready var new_game: Button = $V/NewGame
@onready var load_game: Button = $V/LoadGame
@export var bgm: AudioStream

func _ready() -> void:
	load_game.disabled = not Game.has_save()
	new_game.grab_focus()
	
	
	SoundManager.setup_ui_sounds(self)
	if bgm:
		SoundManager.play_bgm(bgm)


func _on_new_game_pressed() -> void:
	Game.new_game()
	Game.reset_save()


func _on_load_game_pressed() -> void:
	Game.load_game()


func _on_exit_game_pressed() -> void:
	get_tree().quit()
