extends Node

@onready var sfx: Node = $SFX
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

var current_bgm :AudioStream
enum Bus { MASTER, SFX , BGM }
func play_sfx(name: String) -> void:
	# 2. 优先检查父节点是否存在
	if not sfx:
		push_error("SFX节点未找到！")
		return
	
	# 3. 安全获取子节点并检查类型
	var player := sfx.get_node_or_null(name) as AudioStreamPlayer
	if not player:
		push_error("音效播放器 %s 未找到或不是AudioStreamPlayer类型" % name)
		return
	
	# 4. 播放前确认资源已加载
	if player.stream == null:
		push_error("音效 %s 没有设置AudioStream资源" % name)
		return
	
	player.play()

func setup_ui_sounds(node: Node) -> void:
	var button := node as Button
	if button:
		button.pressed.connect(play_sfx.bind("UIPress"))
		button.focus_entered.connect(play_sfx.bind("UIFocus"))
		button.mouse_entered.connect(button.grab_focus)
		
	var slider := node as Slider
	if slider:
		slider.value_changed.connect(play_sfx.bind("UIPress").unbind(1))
		slider.focus_entered.connect(play_sfx.bind("UIFocus"))
		slider.mouse_entered.connect(slider.grab_focus)
		
	for child in node.get_children():
		setup_ui_sounds(child)
		
	
		
func play_bgm(stream: AudioStream) -> void:
	if bgm_player.stream == stream and bgm_player.playing:
		return
	bgm_player.stream = stream
	current_bgm = stream
	bgm_player.play()
	

func stop_bgm() -> void:
	bgm_player.stop()


func fade_out_bgm(duration: float = 1.0) -> void:
	if !bgm_player or !bgm_player.playing:
		return
	
	# 创建 Tween 动画
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -80.0, duration)  # 从当前音量渐变到静音
	
	# 播放完毕后停止播放器（可选）
	await tween.finished
	bgm_player.stop()
	bgm_player.volume_db = 0.0  # 重置音量

func get_volume(bus_index: int) -> float:
	var db := AudioServer.get_bus_volume_db(bus_index)
	return db_to_linear(db)
	
func set_volume(bus_index: int, v : float) -> void:
	var db := linear_to_db(v)
	AudioServer.set_bus_volume_db(bus_index,db)
