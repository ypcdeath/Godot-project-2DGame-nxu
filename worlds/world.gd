class_name World
extends Node2D
@onready var tile_map: TileMap = $TileMap
@onready var camera_2d: Camera2D = $Player/Camera2D
@onready var player: Player = $Player

@export var bgm: AudioStream
signal  camera_should_shake(amount: float)

func _ready() -> void:
	#Engine.time_scale = 0.1
	print("当前BGM: ", SoundManager.current_bgm)
	var used := tile_map.get_used_rect().grow(-1)
	var tile_size := tile_map.tile_set.tile_size
	camera_2d.limit_top = used.position.y * tile_size.y
	camera_2d.limit_right = used.end.x * tile_size.x
	camera_2d.limit_bottom = used.end.y * tile_size.y
	camera_2d.limit_left = used.position.x * tile_size.x
	if bgm:
		if bgm != SoundManager.current_bgm:
			SoundManager.play_bgm(bgm)

func shake_camera(amount: float) -> void:
	camera_should_shake.emit(amount)
	
func update_player(pos: Vector2, direction: Player.Direction) -> void:
	player.global_position = pos
	player.direction = direction
	#camera_2d.position_smoothing_enabled = false  # 关闭平滑
	camera_2d.reset_smoothing()                   # 立即重置
	#camera_2d.position_smoothing_enabled = true   # 可选：重新开启（未来移动继续平滑
	
func to_dict() -> Dictionary:
	var enemies_alive := []
	for node in get_tree().get_nodes_in_group("enemies"):
		var path := get_path_to(node) as String
		print("Saved enemy path: ", path)
		enemies_alive.append(path)
		
	return {
		enemies_alive = enemies_alive
	}
	
func from_dict(dict :Dictionary) -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		var path := get_path_to(node) as String
		print("Current enemy path: ", path, ", In alive list? ", path in dict["enemies_alive"])
		if path not in dict.enemies_alive:
			print("Deleting: ", path)
			node.queue_free()
	
	
