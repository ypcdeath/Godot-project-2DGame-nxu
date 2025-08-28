class_name Interactbale
extends Area2D

signal interacted

func _init() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(3,true) #设置层数的打开和关闭
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func interact() -> void:
	print("[Interact] %s" % name)	
	interacted.emit()

func _on_body_entered(player: Player) -> void:
	player.register_interactalbe(self)

func _on_body_exited(player: Player) -> void:
	player.unregister_interactalbe(self)
