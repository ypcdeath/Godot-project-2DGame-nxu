class_name Player
extends CharacterBody2D

enum Direction {
	LEFT = +1,
	RIGHT = -1,
}

enum State{
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALL_SLIDING,
	WALL_JUMP,
	ATTACK_1,
	ATTACK_2,
	ATTACK_3,
	HURT,
	DIE,
	SLIDING_START,
	SLIDING_LOOP,
	SLIDING_END,
}

var state_names = {
	State.IDLE: "IDLE",
	State.RUNNING: "RUNNING",
	State.JUMP: "JUMP",
	State.FALL: "FALL",
	State.LANDING:"LANDING",
	State.WALL_SLIDING:"WALL_SLIDING",
	State.WALL_JUMP:"WALL_JUMP",
}

const GROUND_STATES := [State.IDLE, State.RUNNING, State.LANDING,
State.WALL_SLIDING,State.ATTACK_1,State.ATTACK_2,State.ATTACK_3,
State.SLIDING_START,State.SLIDING_LOOP,State.SLIDING_END,]
const RUN_SPEED := 160.0
const SLIDING_SPEED := 260.0
const JUMP_VELOCITY := -320.0
const FLOOR_ACCELERATION := RUN_SPEED / 0.15
const AIR_ACCELERATION := RUN_SPEED / 0.1
const WALL_JUMP_VELOCITY := Vector2(320.0,-320.0)
const KNOCKBACK_AMOUNT := 512.0
const SLIDING_DURATION := 0.3
const SLIDE_ENERGY := 3.0

var is_combo_requested := false
var is_first_tick := false
var last_vy:float
var default_g := ProjectSettings.get("physics/2d/default_gravity") as float #表示是浮点数
var pending_damage: Damage
var interacting_with: Array[Interactbale]

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_timer: Timer = $Jump_Timer
@onready var hand_checker: RayCast2D = $Graphics/HandChecker
@onready var foot_checker: RayCast2D = $Graphics/FootChecker
@onready var state_machine: StateMachine = $StateMachine
@onready var coyote_timer_wall: Timer = $CoyoteTimer_Wall
@onready var attack_timer: Timer = $Attack_Timer
@onready var stats: Stats = Game.player_stats
@onready var invincible_timer: Timer = $invincibleTimer
@onready var world: Node2D = $".."
@onready var slide_timer: Timer = $SLIDE_Timer
@onready var interactionicon: AnimatedSprite2D = $Interactionicon
@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var game_over_screen: Control = $CanvasLayer/GameOverScreen
@onready var attack: AudioStreamPlayer = $attack
@onready var jump: AudioStreamPlayer = $jump
@onready var pause_screen: Control = $CanvasLayer/PauseScreen

@export var can_combo := false
@export var direction := Direction.RIGHT:
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		graphics.scale.x = direction
		
func _ready() -> void:
	if stats.health == 0:
		stats.health = stats.max_health
	var tween = create_tween()
	tween.tween_property(Game.color_rect,"color:a",0,0.2)
	stand(default_g,0.01)
	if get_tree().current_scene.scene_file_path.ends_with("cave.tscn"):
		point_light_2d.energy = 0.7
	else: point_light_2d.energy = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_timer.start()
	if event.is_action_released("jump"):
		jump_timer.stop()
		if velocity.y < JUMP_VELOCITY / 2:
			velocity.y = JUMP_VELOCITY / 2
	if event.is_action_pressed("attack"):
		attack_timer.start()
		if can_combo:
			is_combo_requested = true
	if event.is_action_pressed("slide"):
		slide_timer.start()
	if event.is_action_pressed("interact") and interacting_with:
		interacting_with.back().interact()
	if event.is_action_pressed("pause"):
		pause_screen.show_pause()
		
		

func tick_physics(state:State,delta: float) -> void:
	interactionicon.visible = not interacting_with.is_empty()
	
	if invincible_timer.time_left > 0:
		graphics.modulate.a = sin(Time.get_ticks_msec()/20) * 0.5 + 0.5
	else:
		graphics.modulate.a = 1
	match state:
		State.IDLE:
			move(default_g,delta)
			
		State.RUNNING:
			move(default_g,delta)
			
		State.JUMP:
			move(0.00 if is_first_tick else default_g,delta)
	
		State.FALL:
			move(default_g,delta)
			
		State.LANDING:
			stand(default_g,delta)
		State.WALL_SLIDING:
			direction = Direction.LEFT if get_wall_normal().x > 0 else Direction.RIGHT
			move(default_g*0.1,delta)
		State.WALL_JUMP:
			if state_machine.state_time < 0.1:
				stand(0.00 if is_first_tick else default_g,delta)
				direction = Direction.LEFT if get_wall_normal().x < 0 else Direction.RIGHT
			else:
				move(default_g,delta)
		State.ATTACK_1,State.ATTACK_2,State.ATTACK_3:
			stand(default_g,delta)
		State.HURT,State.DIE:
			stand(default_g,delta)
			
		State.SLIDING_END:
			stand(default_g,delta)
			
		State.SLIDING_LOOP,State.SLIDING_START:
			slide(delta)
	is_first_tick = false
	
func should_slide() -> bool:
	if slide_timer.time_left > 0 and stats.energy > SLIDE_ENERGY:
		return true
	else: return false
	
func die() -> void:
	game_over_screen.show_game_over()
	
	
func register_interactalbe(v: Interactbale) -> void:
	if state_machine.current_state == State.DIE:
		return
	if v in interacting_with:
		return
	interacting_with.append(v)
	
func unregister_interactalbe(v: Interactbale) -> void:
	interacting_with.erase(v)

func slide(delta: float) -> void:
	velocity.x = direction * SLIDING_SPEED * -1
	velocity.y += default_g * delta
	move_and_slide()
	
func move(g:float,delta: float) -> void:
	var movement := Input.get_axis("move_left","move_right")
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION 
	velocity.y += g * delta
	velocity.x = move_toward(velocity.x , movement * RUN_SPEED , acceleration * delta)
	
	if not is_zero_approx(movement):
		pass
		direction = 1 if movement < 0 else -1
	#移动的函数
	last_vy = velocity.y #记录上一帧的速度 用来判断要不要强制landing
	move_and_slide()
	#print(velocity.y)
	
func stand(gravity:float,delta:float) -> void:
	@warning_ignore("unused_variable")
	var movement := Input.get_axis("move_left","move_right")
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION 
	velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x , 0.0 , acceleration * delta)
	#移动的函数
	move_and_slide()
	
	
func can_wall_slide() -> bool:
	return is_on_wall() and hand_checker.is_colliding() and foot_checker.is_colliding()
	
func get_next_state(state: State) -> int:
	
	var can_jump := is_on_floor() or coyote_timer.time_left > 0
	var should_jump := can_jump and jump_timer.time_left > 0
	var movement := Input.get_axis("move_left","move_right")
	var is_still := is_zero_approx(movement) and is_zero_approx(velocity.x)
	if stats.health == 0:
		return StateMachine.KEEP_CURRENT if state == State.DIE else State.DIE
		
	if pending_damage:
		return State.HURT
	
	if should_jump:
		return State.JUMP
	
	if state in GROUND_STATES and not is_on_floor():
		if state != State.WALL_SLIDING:
			return State.FALL
	match state:
		State.IDLE:
			if attack_timer.time_left > 0:
				return State.ATTACK_1
			if not is_still:
				return State.RUNNING 
			if should_slide():
				return State.SLIDING_START
			
		State.RUNNING:
			if attack_timer.time_left > 0:
				return State.ATTACK_1
			if is_still:
				return State.IDLE
			if should_slide():
				return State.SLIDING_START
			
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
			
		State.FALL:
			#print(last_vy)
			if is_on_floor():
				if last_vy >= 550.0:
					return State.LANDING
				elif is_still:
					return State.IDLE
				else: return State.RUNNING
			if can_wall_slide():
				return State.WALL_SLIDING
			
		
		State.LANDING:
			if not animation_player.is_playing():
				return State.IDLE
				
		State.WALL_SLIDING:
			if jump_timer.time_left > 0:
				return State.WALL_JUMP
			if is_on_floor():
				return State.IDLE
			if not is_on_wall() and (not hand_checker.is_colliding() or not foot_checker.is_colliding()):
				return State.FALL
			
		State.WALL_JUMP:
			if velocity.y >= 0:
				return State.FALL
			if can_wall_slide() and not is_first_tick:
				return State.WALL_SLIDING
		
		State.ATTACK_1:
			if not animation_player.is_playing():
				return State.ATTACK_2 if is_combo_requested else State.IDLE
		
		State.ATTACK_2:
			if not animation_player.is_playing():
				return State.ATTACK_3 if is_combo_requested else State.IDLE
				
		State.ATTACK_3:
			if not animation_player.is_playing():
				return State.IDLE
				
		State.HURT:
			if not animation_player.is_playing():
				return State.IDLE
				
		State.SLIDING_START:
			if not animation_player.is_playing():
				return State.SLIDING_LOOP
				
		State.SLIDING_END:
			if not animation_player.is_playing():
				return State.IDLE
				
		State.SLIDING_LOOP:
			if state_machine.state_time > SLIDING_DURATION or is_on_wall():
				return State.SLIDING_END
			
	return StateMachine.KEEP_CURRENT
	
func transition_state(from: State, to: State) -> void:
	print("[%s] %s -> %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "START",
		State.keys()[to],
	])
	if from not in GROUND_STATES and to in GROUND_STATES:
		coyote_timer.stop()
		coyote_timer_wall.stop()
	
	match to:
		State.IDLE:
			animation_player.play("idle")
		State.RUNNING:
			animation_player.play("running")
		State.JUMP:
			animation_player.play("jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			jump_timer.stop()
			SoundManager.play_sfx("jump")
		State.FALL:
			animation_player.play("falling")
			if from in GROUND_STATES:
				coyote_timer.start()
		State.LANDING:
			animation_player.play("landing")
		State.WALL_SLIDING:
			velocity.y /= 10
			animation_player.play("wall_sliding")
			
		State.WALL_JUMP:
			coyote_timer_wall.stop()
			animation_player.play("jump")
			velocity.y = WALL_JUMP_VELOCITY.y
			velocity.x = get_wall_normal().x * WALL_JUMP_VELOCITY.x
			jump_timer.stop()
			SoundManager.play_sfx("jump")
		State.ATTACK_1:
			animation_player.play("attack_1")
			is_combo_requested = false
			attack_timer.stop()
			SoundManager.play_sfx("attack")
			
		State.ATTACK_2:
			animation_player.play("attack_2")
			is_combo_requested = false
			SoundManager.play_sfx("attack")
			
		State.ATTACK_3:
			animation_player.play("attack_3")
			is_combo_requested = false
			SoundManager.play_sfx("attack")
			
			
		State.HURT:
			world.shake_camera(4)
			animation_player.play("hurt")
			stats.health -= pending_damage.amount
			var dir := pending_damage.source.global_position.direction_to(global_position)
			velocity = dir * KNOCKBACK_AMOUNT
			pending_damage = null
			invincible_timer.start()
			SoundManager.play_sfx("Boar_Hit")
			
		State.DIE:
			animation_player.play("die")
			invincible_timer.stop()
			interacting_with.clear()
			
		State.SLIDING_START:
			animation_player.play("sliding_start")
			slide_timer.stop()
			stats.energy -= SLIDE_ENERGY
			SoundManager.play_sfx("jump")
			
			
		State.SLIDING_LOOP:
			animation_player.play("sliding_loop")
			
		State.SLIDING_END:
			animation_player.play("sliding_end")
			
			
	'if to == State.WALL_JUMP:
		Engine.time_scale = 0.3
	if from == State.WALL_JUMP:
		Engine.time_scale = 1.0'
	is_first_tick = true
				
func get_state_name(state:State):
	return state_names.get(state)


func _on_hurtbox_hurt(hitbox: Variant) -> void:
	if invincible_timer.time_left > 0:
		return
	pending_damage = Damage.new()
	pending_damage.amount = 1
	pending_damage.source = hitbox.owner
	


func _on_hitbox_hit(hurtbox: Variant) -> void:
	world.shake_camera(2)
	
	Engine.time_scale = 0.01
	await get_tree().create_timer(0.1,true,false,true).timeout
	Engine.time_scale = 1.0
