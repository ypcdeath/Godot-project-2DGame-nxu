extends Camera2D



func _ready() -> void:
	call_deferred("reset_smoothing")
	# 这样可以防止物理差值在直接过渡中插入过渡帧 就是等其他的初始化完了再reseting
	world.camera_should_shake.connect(func(amount :float):
		shake_strength += amount
		)
	
@export var shake_strength := 0.0
@export var recovery_speed := 16.0
@onready var world: Node2D = $"../.."

func _process(delta: float) -> void:
	offset = Vector2(
		randf_range(-shake_strength,+shake_strength),
		randf_range(-shake_strength,+shake_strength)
	)
	shake_strength = move_toward(shake_strength,0,recovery_speed * delta)
	

	
