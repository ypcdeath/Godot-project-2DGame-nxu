extends Interactbale

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func interact() -> void:
	super()
	
	animation_player.play("activited")
	Game.save_game()
	SoundManager.play_sfx("Save_Stone")
