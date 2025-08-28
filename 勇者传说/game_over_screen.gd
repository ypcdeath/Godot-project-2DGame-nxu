extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var bgm: AudioStream

func _ready() -> void:
	hide()
	set_process_input(false)
	if bgm:
		SoundManager.play_bgm(bgm)

func _input(event: InputEvent) -> void:
	get_window().set_input_as_handled()

	if (
		event is InputEventKey or 
		event is InputEventMouse
	):
		if event.is_pressed() and not event.is_echo():
			if Game.has_save():
				Game.load_game()
			else:
				Game.back_to_tile()
				
func show_game_over() -> void:
	show()
	set_process_input(true)
	animation_player.play("enter")
