extends CharacterBody3D

# GuardianAI.gd - Combat AI for Floor Guardians (Albedo, Shalltear)
# Automatically follows Ainz and attacks enemies in range.

@export var speed = 7.0
@export var attack_damage = 40
@export var attack_range = 2.0
@export var follow_distance = 4.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
var player: Node3D
var target_enemy: CharacterBody3D

func _ready():
	add_to_group("allies")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	find_target()
	
	if target_enemy:
		combat_behavior(_delta)
	else:
		follow_behavior(_delta)

func find_target():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_dist = 20.0 # Aggro range
	var best_enemy = null
	
	for enemy in enemies:
		var dist = global_transform.origin.distance_to(enemy.global_transform.origin)
		if dist < closest_dist:
			closest_dist = dist
			best_enemy = enemy
	
	target_enemy = best_enemy

func combat_behavior(_delta):
	var target_pos = target_enemy.global_transform.origin
	var dist = global_transform.origin.distance_to(target_pos)
	
	if dist <= attack_range:
		# Attack
		velocity = Vector3.ZERO
		perform_attack()
	else:
		# Move to enemy
		move_to(target_pos)

func follow_behavior(_delta):
	var dist = global_transform.origin.distance_to(player.global_transform.origin)
	if dist > follow_distance:
		move_to(player.global_transform.origin)
	else:
		velocity = Vector3.ZERO
		move_and_slide()

func move_to(target_pos):
	nav_agent.target_position = target_pos
	if nav_agent.is_navigation_finished(): return
	
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = (next_path_pos - global_transform.origin).normalized()
	dir.y = 0
	
	velocity = dir * speed
	move_and_slide()
	
	# Look at movement direction
	if dir.length() > 0.1:
		var look_target = global_transform.origin + dir
		look_at(look_target, Vector3.UP)

func perform_attack():
	# Simple cooldown-based attack
	if not has_node("AttackTimer"):
		var timer = Timer.new()
		timer.name = "AttackTimer"
		timer.wait_time = 1.0
		timer.one_shot = true
		add_child(timer)
		timer.start()
		
		if target_enemy.has_method("take_damage"):
			target_enemy.take_damage(attack_damage)
			print(name, " attacked ", target_enemy.name)
	
	if get_node("AttackTimer").is_stopped():
		get_node("AttackTimer").start()
		if target_enemy.has_method("take_damage"):
			target_enemy.take_damage(attack_damage)
			print(name, " attacked ", target_enemy.name)

func take_damage(amount: int):
	# Guardians are very tanky
	print(name, " took ", amount, " damage. (Supreme Defense)")
