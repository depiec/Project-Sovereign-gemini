extends RigidBody3D

# Fireball.gd - Simple Projectile

@export var damage: int = 50
@export var speed: float = 20.0

func _ready():
	# Automatically destroy after 5 seconds to prevent clutter
	get_tree().create_timer(5.0).timeout.connect(queue_free)
	
	# Initial velocity is set by the caster, but we can ensure it's high
	# This script assumes AinzPlayer sets the linear_velocity

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	# Visual effect (Niagara/GPUParticles placeholder)
	print("Fireball hit: ", body.name)
	queue_free()
