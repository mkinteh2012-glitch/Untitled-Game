extends CharacterBody2D

@export var speed: float = 120.0
@export var health = 2.0
@export var float_speed = 6.0
@export var float_height = 80.0 

var direction: int = -1
var time_passed = 0.0
var can_turn = true
@onready var sprite = $AnimatedSprite2D
@onready var hurtbox = $Hurtbox
@onready var death_particles = $GPUParticles2D


func _ready() -> void:
	await get_tree().process_frame
	if hurtbox:
		hurtbox.area_entered.connect(on_hurtbox_area_enter)


func _physics_process(delta: float) -> void:
	time_passed += delta
	velocity.x = speed * direction
	velocity.y = cos(time_passed * float_speed) * float_height

	if is_on_wall() and can_turn:
		direction *= -1
		if sprite:
			sprite.flip_h = (direction == 1)
		can_turn = false
		get_tree().create_timer(0.2).timeout.connect(func(): can_turn = true)
	
	move_and_slide()
	check_hurt()

		
func is_player(body):
	return body.is_in_group("player") or body.name == "Player"

func check_hurt():
	if hurtbox == null:
		return
	for body in hurtbox.get_overlapping_bodies():
		if not is_player(body):
			continue
		var push_dir := signf(body.global_position.x - global_position.x)
		if push_dir == 0.0 :
			push_dir = 1
		body.take_damage(1,Vector2(push_dir * 120, -150))
	
			
func on_hurtbox_area_enter(area: Area2D):
	if area.is_in_group("bullet") or "bullet" in area.name.to_lower():
		take_damage(1.0)
		area.queue_free()
		
func take_damage(amount):
	health -= amount
	flash_sprite()
	if health <= 0:
		die()

func flash_sprite():
	if sprite == null:
		return
	sprite.modulate = Color(10,10,10)
	await get_tree().create_timer(0.08).timeout
	if sprite and is_inside_tree():
		sprite.modulate = Color(1,1,1)
func die():
	spawn_fx()
	queue_free()

func spawn_fx():
	if death_particles == null:
		return
	var fx: GPUParticles2D = death_particles.duplicate()
	fx.global_position = death_particles.global_position
	fx.emitting = true
	var root := get_tree().current_scene
	root.call_deferred("add_child",fx)
	get_tree().create_timer(fx.lifetime + 0.3).timeout.connect(fx.queue_free)
	
	
	
	
	
	
