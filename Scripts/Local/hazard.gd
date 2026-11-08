extends Area2D

@export var damage = 1
@export var knockback = Vector2(0,-400)

func _ready() -> void:
	body_entered.connect(on_body_entered)
	
func on_body_entered(body: Node2D):
	if body.is_in_group("player") and body.has_method("take_damage"):
		var dir: Vector2 = (body.global_position - global_position).normalized()
		body.take_damage(damage, dir * knockback.length())
