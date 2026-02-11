extends Node3D

# FallenDownEffect.gd - Massive AOE Visual

func _ready():
	# In a real game, this would play a massive animation
	# and use a large Area3D to kill everything.
	print("FALLEN DOWN: Judgment has descended!")
	
	# Scale up rapidly to simulate explosion
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(15, 15, 15), 1.0)
	tween.parallel().tween_property($MeshInstance3D.get_surface_override_material(0), "albedo_color:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

	# Damage logic
	var area = $Area3D
	for body in area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(9999) # Supreme power
