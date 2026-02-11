extends CharacterBody3D

# Enemy.gd - Basic Worker Enemy AI

@export var health: int = 100
@export var speed: float = 3.0
@export var level: int = 1
@export var xp_value: int = 50

@onready var player = get_tree().get_first_node_in_group("player")
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var last_attacker: Node3D

func _physics_process(delta):
	if not is_on_floor(): velocity.y -= gravity * delta
	if not player: player = get_tree().get_first_node_in_group("player")
	if player:
		var direction = (player.global_transform.origin - global_transform.origin).normalized()
		direction.y = 0
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if direction.length() > 0.1:
			var target_look = player.global_transform.origin
			target_look.y = global_transform.origin.y
			look_at(target_look, Vector3.UP)
	move_and_slide()

func take_damage(amount: int, attacker: Node3D = null):
	health -= amount
	last_attacker = attacker
	print(name, " took ", amount, " damage.")
	if health <= 0: die()

func die():
	print(name, " eliminated.")
	if last_attacker and last_attacker.has_method("gain_xp"):
		last_attacker.gain_xp(xp_value)
	var soul_scene = load("res://resources/effects/SoulEffect.tscn")
	if soul_scene:
		var soul = soul_scene.instantiate()
		get_parent().add_child(soul)
		soul.global_transform.origin = global_transform.origin + Vector3(0, 1.0, 0)
	GameManager.add_resource("souls", 1)
	queue_free()