extends Resource

class_name GuardianAbility

# GuardianAbility.gd - Custom Resource for Guardian-specific powers

@export var ability_name: String
@export var cooldown: float = 5.0
@export var range: float = 5.0
@export var damage: int = 0
@export var is_buff: bool = false
@export var visual_scene: PackedScene # e.g. Shield bubble, or Lance strike

func execute(caster: Node3D, target: Node3D):
	print(caster.name, " uses ", ability_name)
	if visual_scene:
		var visual = visual_scene.instantiate()
		caster.add_child(visual)
		if not is_buff:
			visual.global_transform.origin = target.global_transform.origin
		else:
			visual.global_transform.origin = caster.global_transform.origin
