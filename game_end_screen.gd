extends Control

const LINES := [
	"大魔王终于被打败了",
	"森林又恢复了以往的平静",
	"但是这一切就是对的吗？",
]


var current_line := -1

var tween: Tween

@onready var label: Label = $Label
@export var bgm: AudioStream

func _ready() -> void:
	SoundManager.fade_out_bgm(1.0)
	show_line(0)
	var timer = get_tree().create_timer(1.01)
	await timer.timeout
	if bgm:
		SoundManager.play_bgm(bgm)

func _input(event: InputEvent) -> void:
	get_window().set_input_as_handled()

	if (
		event is InputEventKey or 
		event is InputEventMouse
	):
		if event.is_pressed() and not event.is_echo():
			if current_line + 1 < LINES.size():
				show_line(current_line+1)
			else:
				Game.back_to_tile()

func show_line(line: int) -> void:
	current_line = line
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	if line > 0:
		tween.tween_property(label,"modulate:a",0,1)
	else:
		label.modulate.a = 0
		
	tween.tween_callback(label.set_text.bind(LINES[line]))
	tween.tween_property(label,"modulate:a",1,1)
