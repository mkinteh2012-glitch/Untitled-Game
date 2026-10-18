# RoomArea.gd
extends Area2D
class_name RoomArea

func _enter_tree() -> void:
	add_to_group("rooms")

func get_rect() -> Rect2:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or not (shape_node.shape is RectangleShape2D):
		print("ERROR: ", name, " needs a CollisionShape2D with a RectangleShape2D")
		return Rect2()
	var rect_shape := shape_node.shape as RectangleShape2D
	var size: Vector2 = rect_shape.size * shape_node.global_scale.abs()
	var center: Vector2 = shape_node.global_position
	return Rect2(center - size / 2.0, size)
