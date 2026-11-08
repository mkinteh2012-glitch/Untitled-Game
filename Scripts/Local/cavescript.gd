extends Node2D

@export var player: CharacterBody2D
@export var follow_smoothing := 3.0
@export var generator: CaveGenerator
@export var debug_key: Key = KEY_TAB
@onready var camera: CameraRig = $Camera2D

var _rects: Array[Rect2] = []
var current_rect := Rect2()
var debug_view := false
var _was_in_room := true
var _debug_outline: Node2D


func _ready() -> void:
	print("=== CAVESCRIPT START ===")
	print("Generator assigned: ", generator != null)
	print("Player assigned: ", player != null)
	print("Camera found: ", camera != null)

	if generator:
		generator.generate_cave()
		_draw_debug_outlines()
		if player:
			player.global_position = generator.get_start_position()
			print("Player moved to: ", player.global_position)
	else:
		push_error("No generator assigned in the Inspector!")

	refresh_room_bounds()
	print("=== CAVESCRIPT READY - press ", OS.get_keycode_string(debug_key), " for debug view ===")


# ---------- DEBUG DRAWING ----------
func _draw_debug_outlines() -> void:
	var grid_size: Vector2 = Vector2(CaveGenerator.GRID_SIZE)

	_debug_outline = Node2D.new()
	_debug_outline.name = "DebugOutlines"
	_debug_outline.z_index = 100
	_debug_outline.visible = false # only shows in debug view
	generator.add_child(_debug_outline) # same coordinates as the rooms

	_debug_outline.draw.connect(func():
		for cell in generator.spawned_grid:
			# Red box = where the room SHOULD be
			var r = Rect2(Vector2(cell) * grid_size, grid_size)
			_debug_outline.draw_rect(r, Color.RED, false, -1.0)

			# Green cross = where the room's origin ACTUALLY is
			var o: Vector2 = generator.spawned_grid[cell].position
			_debug_outline.draw_line(o + Vector2(-60, 0), o + Vector2(60, 0), Color.GREEN, -1.0)
			_debug_outline.draw_line(o + Vector2(0, -60), o + Vector2(0, 60), Color.GREEN, -1.0)

			# Yellow label = grid position
			_debug_outline.draw_string(ThemeDB.fallback_font, r.position + Vector2(20, 120),
				str(cell), HORIZONTAL_ALIGNMENT_LEFT, -1, 100, Color.YELLOW)

		# Blue boxes = the RoomArea rects the camera is using
		for rect in _rects:
			var local_rect = Rect2(rect.position - generator.global_position, rect.size)
			_debug_outline.draw_rect(local_rect, Color.CYAN, false, -1.0)
	)
	_debug_outline.queue_redraw()


func _physics_process(_delta: float) -> void:
	if debug_view:
		return
	_check_player_room()
	update_camera(false)


# Prints only when the player enters/leaves rooms (no spam)
func _check_player_room() -> void:
	if player == null:
		return
	var rect = room_at(player.global_position)
	var in_room = rect.size != Vector2.ZERO
	if in_room and rect != current_rect:
		print("Player entered room: ", rect)
	if not in_room and _was_in_room:
		print("WARNING: player at ", player.global_position, " is NOT inside any RoomArea")
	_was_in_room = in_room


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == debug_key:
		debug_view = not debug_view
		if _debug_outline:
			_debug_outline.visible = debug_view
			_debug_outline.queue_redraw()
		if debug_view:
			camera.stop_slide()
			camera.zoom = Vector2(0.25, 0.25)
			print("DEBUG VIEW ON")
		else:
			camera.zoom = Vector2.ONE
			current_rect = Rect2()
			snap_camera()
			print("DEBUG VIEW OFF")
		get_viewport().set_input_as_handled()
		return

	if not debug_view:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(1.2)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(1.0 / 1.2)

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			zoom_camera(1.2)
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			zoom_camera(1.0 / 1.2)

	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		camera.global_position -= event.relative / camera.zoom


func zoom_camera(amount: float) -> void:
	camera.zoom = (camera.zoom * amount).clamp(Vector2(0.02, 0.02), Vector2(4, 4))


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


func room_at(point: Vector2) -> Rect2:
	for r in _rects:
		if r.has_point(point):
			return r
	return Rect2()


func slide_cam_to_player():
	current_rect = Rect2()
	update_camera(false)


func refresh_room_bounds():
	_rects.clear()
	var areas = get_tree().root.find_children("*", "RoomArea", true, false)
	print("RoomArea nodes found: ", areas.size())
	for area in areas:
		var rect: Rect2 = area.get_rect()
		print("  ", area.get_path(), " -> rect ", rect)
		if rect.size != Vector2.ZERO:
			_rects.append(rect)
		else:
			print("    ^ SKIPPED (size is zero)")
	print("Usable room rects: ", _rects.size())
	if _rects.is_empty():
		push_error("No usable RoomArea rects - camera won't move!")
	update_camera(true)
