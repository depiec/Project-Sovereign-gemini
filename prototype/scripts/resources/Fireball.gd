extends RigidBody3D

# Fireball.gd - Simple Projectile

@export var damage: int = 50
@export var speed: float = 20.0
var caster: Node3D

func _ready():
	get_tree().create_timer(5.0).timeout.connect(queue_free)

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage, caster)
	queue_free()