extends CharacterBody2D

@export var speed = 120.0
@export var health = 2.0
@export var float_speed = 6.0
@export var float_height = 80.0 

var direction = -1
var time_passed = 0.0
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
	velocity.y = cos(time_passed * float_speed) * float_speed
	if is_on_wall():
		direction *= -1
		if sprite:
			sprite.flip_h
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
		var push_dir := signf(body.global_postion.x - global_position.x)
		if push_dir == 0.0 :
			push_dir = 1
		body.take_damage(1,Vector2(push_dir * 120, -150))
	
	
	
	
	
	
	
	
	
		
func on_hurtbox_area_enter():
	pass
