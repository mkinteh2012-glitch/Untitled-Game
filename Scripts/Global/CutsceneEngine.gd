extends CanvasLayer
#Cutscene Engine
#These are Callable commands like the camera system

var fade: ColorRect
var playing:= false
var cam_start_zoom := Vector2.ONE

func _ready() -> void:
	layer = 100
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	
#freezes the player
func start():
	pass
