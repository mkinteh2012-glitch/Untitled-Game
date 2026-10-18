extends CharacterBody2D

# Movement var
@export_group("Movement")
@export var speed: float = 250.0
@export var jump_velocity = -420.0
@export var acceleration = 1000.0
@export var friction = 1000.0

@export_group("Arial Movement and Gravity")
@export var air_acceleration =  800.0
@export var air_friction =  200
@export var fall_gravity_mult = 0.85

@export_group("Juice and Feel")
var coyote_time =  0.1
var coyote_timer = 0.0

@export var jump_buffer_time = 0.15
var jump_buffer_timer = 0.0

@export_group("Wall Slide & Jump")
@export var wall_slide_gravity = 80.0
@export var wall_jump_velocity_x = 250.0
@export var wall_jump_velocity_y = -300.0
@export var wall_climb_speed = -150.0
@export var wall_climb_duration = 1.5
var wall_climb_timer = 0.0

@export_group("Dash")
@export var dash_speed = 700
@export var dash_duration = 0.2
@export var dash_cooldown = 0.5
@export var ghost_spawn = 0.05

var is_dashing = false
var dash_cooldown_timer = 0.0
var dash_timer = 0.0
var ghost_timer = 0.0
var dash_direction = Vector2.RIGHT
var used_recoil_boost = false
var squash_tween: Tween
#Getting scene refrence
@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $CollisionShape2D
@onready var jump_dust = $JumpDust
@onready var wall_jump_dust = $WallJumpDust
@onready var run_dust = $RunDust
@onready var wall_check_l = $RayCastL
@onready var wall_check_r = $RayCastR

#getting some defaults
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var was_in_air: bool = false
var original_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	if sprite:
		original_scale = sprite.scale
	coyote_timer = 0.0
		
func _physics_process(delta: float) -> void:
	# dash check
	if is_on_floor():
		used_recoil_boost = false
		
	if jump_buffer_timer >= 0:
		jump_buffer_timer -= delta
	
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta	
		
	if is_dashing:
		dash_timer -= delta
		ghost_timer -= delta
		
		if dash_timer <= 0.0:
			is_dashing = false
			velocity.x *= 0.1
			
		if ghost_timer <= 0.0:
			ghost_timer = ghost_spawn
			create_dash_ghost()
	
		
	if is_dashing:
		if Input.is_action_pressed("ui_accept"):
			is_dashing = false
			velocity.x *= 0.2
			velocity.y *= 0.5
			jump_buffer_time = jump_buffer_timer
		elif dash_timer <= 0.0 or is_on_wall():
			is_dashing = false
			velocity.x *= 0.2
			velocity.y *= 0.5
		else:
			
			velocity = dash_direction * dash_speed
			move_and_slide()
			return  
	if was_in_air and is_on_floor():
		apply_squash_n_strech(Vector2(1.2,0.8))
		
	was_in_air = not is_on_floor()
	# do gravity in the air + coyote timer
	if is_on_floor():
		coyote_timer = coyote_time
		wall_climb_timer =  wall_climb_duration
	else:
		coyote_timer -= delta
		
		var applied_gravity = gravity
		
		if is_against_wall():
			if Input.is_action_pressed("ui_up") and wall_climb_timer > 0.0:
				velocity.y = wall_climb_speed
				wall_climb_timer -= delta
				applied_gravity = 0.0
			elif Input.is_action_pressed("ui_down"):
				applied_gravity = wall_slide_gravity * 2.5
			else:	
				velocity.y = 0.0
				applied_gravity = 0.0
		elif velocity.y > 0:
			applied_gravity *= fall_gravity_mult
		velocity.y += applied_gravity * delta
	
	

	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	
	# handle jump input
	
	if Input.is_action_just_pressed("ui_accept") and can_wall_jump():
		var wall_normal = get_wall_normal()
		velocity.x = wall_normal.x * wall_jump_velocity_x
		velocity.y = wall_jump_velocity_y
		
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		
		wall_jump_dust.rotation = 0.0 if wall_normal.x > 0 else PI
		wall_jump_dust.restart()
		
	
	if jump_buffer_timer > 0.0 and (coyote_timer > 0.0 or is_on_floor()):
		velocity.y = jump_velocity
		apply_squash_n_strech(Vector2(0.9,1.1))
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		jump_dust.restart()

		
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5
		
	
	if Input.is_action_just_pressed("Dash") and dash_cooldown_timer <= 0.0 and not is_dashing:
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		
		var h_dir = Input.get_axis("ui_left","ui_right")
		var is_up = Input.is_action_pressed("ui_up")
		
		if is_up:
			
			var x_input = sign(h_dir) if h_dir != 0 else (-1.0 if sprite.flip_h else 1.0)
			dash_direction = Vector2(x_input, -1.0).normalized()
		else:
			
			if h_dir != 0:
				dash_direction = Vector2(sign(h_dir), 0.0)
			else:
				dash_direction = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	#Horizontal direction stuff
	var direction := Input.get_axis("ui_left","ui_right")
	var accel = acceleration if is_on_floor() else air_acceleration
	var frict = friction if is_on_floor() else air_friction
	
	if direction != 0.0:
		velocity.x = move_toward(velocity.x,direction * speed,accel * delta)
		sprite.flip_h = direction < 0
	else:
			velocity.x = move_toward(velocity.x,0,frict * delta)
	
	if is_on_floor() and direction != 0.0 and not is_dashing :
		run_dust.emitting = true
		run_dust.process_material.direction = Vector3(1.0 if sprite.flip_h else -1.0, 0, 0)
	else:
		run_dust.emitting = false
		
	#do the movement
	move_and_slide() 
	
func is_against_wall () -> bool:
	var direction := Input.get_axis("ui_left","ui_right")
	if not is_on_floor():
		if direction < 0 and wall_check_l.is_colliding():
			return true
		elif direction > 0 and wall_check_r.is_colliding():
			return true
			
	return false

func can_wall_jump() -> bool:
	return not is_on_floor() and (wall_check_l.is_colliding() or wall_check_r.is_colliding())

func create_dash_ghost():
	var ghost = sprite.duplicate()
	get_tree().current_scene.add_child(ghost)
	
	ghost.global_position = global_position
	ghost.scale = sprite.scale
	ghost.flip_h = sprite.flip_h
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(ghost,"modulate:a", 0.0 , 0.2)
	tween.chain().tween_callback(ghost.queue_free)

func apply_recoil_boost():
	if used_recoil_boost:
		return
		
	velocity.y = -350.0
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	used_recoil_boost = true

func apply_squash_n_strech(target_scale: Vector2, duration: float = 0.15) -> void:
	# Kill any active tween so they don't stack
	if squash_tween and squash_tween.is_valid():
		squash_tween.kill()
		
	# Check current horizontal facing sign (-1 for left, 1 for right)
	var current_sign_x = sign(sprite.scale.x) if sprite.scale.x != 0 else 1.0
	
	# Apply the stretch/squash multiplier relative to your original inspector size
	sprite.scale = Vector2(original_scale.x * target_scale.x * current_sign_x, original_scale.y * target_scale.y)
	
	# Tween back to your exact original scale, preserving the flip direction
	squash_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	squash_tween.tween_property(sprite, "scale", Vector2(original_scale.x * current_sign_x, original_scale.y), duration)
