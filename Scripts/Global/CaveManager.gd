extends Node
var current_floor: int = 0
var in_cave = false

func return_to_surface():
	print("died on: " + str(current_floor))
	get_tree().change_scene_to_file("res://Scenes/Enviorment/world_map.tscn")
