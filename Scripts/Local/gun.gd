extends Node2D

@export var bullet_scene: PackedScene
@onready var muzzle = $Muzzle
@onready var sprite = $AnimatedSprite2D

func _process(delta: float) -> void:
	var h_dir = Input.get_axis("ui_left", "ui_right")
	var v_dir = Input.get_axis("ui_up", "ui_down")
	
	
	var aim_direction = Vector2.RIGHT if not sprite.flip_h else Vector2.LEFT
	
	
	if h_dir != 0 or v_dir != 0:
		aim_direction = Vector2(h_dir, v_dir).normalized()
	

	rotation = aim_direction.angle()
	
	if abs(rotation) > PI / 2:
		scale.y = -1
	else:
		scale.y = 1

	if Input.is_action_just_pressed("shoot"):
		fire(aim_direction)

func fire(dir: Vector2) -> void:
	if not bullet_scene:
		print("ERROR")
		return
		

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.direction = dir
	bullet.rotation = dir.angle()
	

	if dir == Vector2(0, 1) and not owner.is_on_floor():
		if owner.has_method("apply_recoil_boost"):
			owner.apply_recoil_boost()
