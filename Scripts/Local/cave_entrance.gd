extends Area2D

@export var target_cave_scene: PackedScene
var player_in_range: bool = false

func _ready() -> void:
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)

func on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true
		print("press down to enter the cave")

func on_body_exited(body : Node2D):
	if body.is_in_group("player"):
		player_in_range = false

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("ui_down"):
		enter_cave()

func enter_cave():
	print("entering cave")
	CaveManager.current_floor += 1
	CaveManager.in_cave = true
	
	CaveManager.current_floor = 1
	
	if target_cave_scene:
		get_tree().change_scene_to_packed(target_cave_scene)
	
	
