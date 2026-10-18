extends Node2D

@export var player: CharacterBody2D
@export var follow_smoothing := 3.0

@onready var camera: Camera2D = $Camera2D

var _rects: Array[Rect2] = []
var current_rect := Rect2()


func _ready() -> void:
	for area in find_children("*","RoomArea",true,false):
		var rect: Rect2 = area.get_rect()
		if rect.size != Vector2.ZERO:
			_rects.append(rect)
	if _rects.is_empty():
		print("NO AREA FOUND")
	update_camera(true)

func _physics_process(_delta: float) -> void:
	var shape := get_node("RoomBounds/Room1/CollisionShape2D") as CollisionShape2D
	update_camera(false)

func snap_camera():
	update_camera(true)

func update_camera(instant: bool) -> void:
	if player == null:
		return
	var rect: Rect2 = room_at(player.global_position)
	if rect.size == Vector2.ZERO:
		return

	var half: Vector2 = camera.screen_size / 2.0
	var target: Vector2 = player.global_position

	if rect.size.x >= camera.screen_size.x:
		target.x = clampf(target.x, rect.position.x + half.x, rect.end.x - half.x)
	else:
		target.x = rect.position.x + rect.size.x / 2.0
	if rect.size.y >= camera.screen_size.y:
		target.y = clampf(target.y, rect.position.y + half.y, rect.end.y - half.y)
	else:
		target.y = rect.position.y + rect.size.y / 2.0

	if instant:
		camera.snap_to(target)
	elif rect != current_rect:
		
		current_rect = rect
		camera.slide_to(target)
	elif not camera.is_moving:
		
		camera.global_position = target

func room_at(point:Vector2) -> Rect2:
	for r in _rects:
		if r.has_point(point):
			return r
	return Rect2()
