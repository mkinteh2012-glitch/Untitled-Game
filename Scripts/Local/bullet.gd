extends Area2D

var speed = 600.0
var direction = Vector2.RIGHT

func _physics_process(delta: float) -> void:
		global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	queue_free()
