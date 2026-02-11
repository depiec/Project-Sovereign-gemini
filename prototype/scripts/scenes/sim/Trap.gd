extends Area3D

# Trap.gd - Simple Trap Placeholder

@export var damage: int = 20

func _on_body_entered(body):
	if body.has_method("take_damage"):
		print("Trap triggered by ", body.name)
		body.take_damage(damage)
		# Visual effect here
		queue_free()
