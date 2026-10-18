extends Camera2D
#Camera system
class_name CameraRig
#setting for our class
@export var screen_size:= Vector2(576,324) # Base viewport
@export var slide_time := 0.4
@export var slide_trans :Tween.TransitionType = Tween.TRANS_SINE
@export var slide_ease: Tween.EaseType = Tween.EASE_IN_OUT

var is_moving := false
var move_tween: Tween
var shake_tween : Tween

func _ready() -> void:
	make_current()
	position_smoothing_enabled = false

func clamped_screen_center(origin: Vector2,roomsize: Vector2, cell:Vector2i):
	var half := screen_size / 2.0
	var center := origin + Vector2(cell) * screen_size + half
	center.x = clamp_axis(center.x,origin.x,roomsize.x,half.x)
	center.y = clamp_axis(center.y,origin.y,roomsize.y,half.y)
	return center

func clamp_axis(c: float,origin: float, size:float, half:float) -> float:
	if size >= half * 2:
		return clampf(c,origin + half,origin + size - half)
	return origin + size/2.0 # if room smaller than screen we need to center it

# snapping to a postion without sliding
func snap_to(target: Vector2) -> void:
	stop_slide()
	global_position = target

#sliding to a positon we want to
func slide_to (target:Vector2) -> void :
	stop_slide()
	is_moving = true
	move_tween = create_tween()
	move_tween.tween_property(self,"global_position",target,slide_time) \
		.set_trans(slide_trans).set_ease(slide_ease)
	move_tween.finished.connect(func(): is_moving = false)

func shake(strength := 4.0, duration := 0.3):
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
	shake_tween = create_tween()
	var steps = 6
	for i in steps:
		var off := Vector2(randf_range(-strength,strength),randf_range(-strength,strength))
		shake_tween.tween_property(self,"offset",off,duration/steps)
	shake_tween.tween_property(self,"offset",Vector2.ZERO,duration/steps)	
	
		
		
#stopping the side
func stop_slide():
	if move_tween and move_tween.is_valid():
		move_tween.kill()
	is_moving = false
