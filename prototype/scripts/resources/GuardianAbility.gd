extends Resource

class_name GuardianAbility

# GuardianAbility.gd - Custom Resource for Guardian-specific powers

@export var ability_name: String
@export var cooldown: float = 5.0
@export var range: float = 5.0
@export var damage: int = 0
@export var is_buff: bool = false
@export var buff_damage_mult: float = 1.0
@export var buff_speed_mult: float = 1.0
@export var buff_duration: float = 5.0
@export var visual_scene: PackedScene # e.g. Shield bubble, or Lance strike

func execute(caster: Node3D, target: Node3D):
	print(caster.name, " uses ", ability_name)
	
	if is_buff and caster.has_method("apply_buff"):
		caster.apply_buff(buff_damage_mult, buff_speed_mult, buff_duration)

	if visual_scene:
		var visual = visual_scene.instantiate()
		caster.add_child(visual)
		if not is_buff:
			visual.global_transform.origin = target.global_transform.origin
		else:
			# Attach to caster for buffs
			visual.position = Vector3.ZERO
