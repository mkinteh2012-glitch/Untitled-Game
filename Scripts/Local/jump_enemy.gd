extends CharacterBody2D

@export var speed: int = 200
@export var jump_force = -450
@export var min_jump_delay = 0.01
@export var max_jump_delay = 0.3
@export var health = 2

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = -1 
var jump_timer = 0.0
var is_waiting_jump = false
@onready var sprite = $AnimatedSprite2D
@onready var hurtbox = $Hurtbox
@onready var stompbox = $Stompbox
@onready var death_particle = $GPUParticles2D

func _ready() -> void:
	await get_tree().process_frame
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		is_waiting_jump = false
	else:
		velocity.x = direction * speed
		if not is_waiting_jump:
			is_waiting_jump = true
			jump_timer = randf_range(min_jump_delay, max_jump_delay)
		else:
			jump_timer -= delta
			if jump_timer <= 0:
				is_waiting_jump = false
				velocity.y = jump_force
				velocity.x = direction * speed
	if is_on_wall():
		direction *= -1
		if sprite:
			sprite.flip_h = (direction == 1)
	velocity.x = direction * speed
	move_and_slide()
	if _check_stomp():
		return
	_check_hurt()

func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.name == "Player"

func _check_stomp() -> bool:
	if stompbox == null:
		return false
	for body in stompbox.get_overlapping_bodies():
		if _is_player(body):
			if body.has_method("bounce"):
				body.bounce(-300)
			squish_and_die()
			return true
	return false

func _check_hurt() -> void:
	if hurtbox == null:
		return
	for body in hurtbox.get_overlapping_bodies():
		if not _is_player(body):
			continue
		var push_dir := signf(body.global_position.x - global_position.x)
		if push_dir == 0.0:
			push_dir = 1.0
		body.take_damage(1, Vector2(push_dir * 150.0, -200.0))
		return

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullet") or "bullet" in area.name.to_lower():
		take_damage(1)
		print("bullet hit")
		area.queue_free()

func take_damage(amount) -> void:
	health -= amount
	print(name + " Hit " + str(health))
	sprite.modulate = Color(10,10,10)
	await get_tree().create_timer(0.03).timeout
	sprite.modulate = Color(1,1,1)
	if health <= 0:
		die()

func die() -> void:
	_spawn_death_fx()
	queue_free()

func _spawn_death_fx() -> void:
	if death_particle == null:
		return
	var fx: GPUParticles2D = death_particle.duplicate()
	fx.emitting = true
	var root := get_tree().current_scene
	root.call_deferred("add_child", fx)
	fx.set_deferred("global_position", global_position)
	get_tree().create_timer(fx.lifetime + 0.3).timeout.connect(fx.queue_free)


func squish_and_die():
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
	if stompbox:
		stompbox.set_deferred("monitoring",false)
	
	set_physics_process(false)
	velocity = Vector2.ZERO
	
	if sprite:
		sprite.scale = Vector2(sprite.scale.x * 1.4, sprite.scale.y * 0.15)	
		sprite.global_position.y += 8.0 
		
	await get_tree().create_timer(0.05).timeout
	queue_free()
