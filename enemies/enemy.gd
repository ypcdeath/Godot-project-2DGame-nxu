class_name Enemy
extends CharacterBody2D

enum Direction {
	LEFT = -1,
	RIGHT = +1,
}

signal died

@export var direction := Direction.LEFT: #不然初始值是0 @export 可以把这个变量导出
	set(v): #v就是当这个变量改变时，新赋的值，当改变时执行下面的逻辑
		direction = v
		if not is_node_ready():
			await ready
		graphics.scale.x = -direction
@export var max_speed: float = 180.0
@export var acceleration: float = 2000.0

var default_g := ProjectSettings.get("physics/2d/default_gravity") as float #表示是浮点数

@onready var graphics: Node2D = $Graphics
@onready var state_machine: StateMachine = $StateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var stats: Stats = $Stats


func _ready() -> void:
	add_to_group("enemies")

func move(speed: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x , direction * speed , acceleration * delta)
	velocity.y += default_g * delta
	move_and_slide()
	
func die() -> void:
	died.emit()
	queue_free()
