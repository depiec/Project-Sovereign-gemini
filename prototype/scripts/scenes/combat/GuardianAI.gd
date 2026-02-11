extends CharacterBody3D

# GuardianAI.gd - Combat AI for Floor Guardians (Albedo, Shalltear)
# Supports special abilities and player possession.

@export var speed = 7.0
@export var attack_damage = 40
@export var attack_range = 2.0
@export var follow_distance = 4.0
@export var special_ability: Resource # GuardianAbility

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
var player: Node3D
var target_enemy: CharacterBody3D
var ability_timer = 0.0
var is_possessed = false

# Buffs
var damage_mult = 1.0
var speed_mult = 1.0

func _ready():
	add_to_group("allies")
	add_to_group("guardians")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if is_possessed:
		handle_possessed_movement(delta)
		return
	if ability_timer > 0: ability_timer -= delta
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return
	find_target()
	if target_enemy: combat_behavior(delta)
	else: follow_behavior(delta)

func handle_possessed_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir = Vector3(input_dir.x, 0, input_dir.y).normalized()
	velocity = dir * speed * 1.5 * speed_mult
	if not is_on_floor(): velocity.y -= 9.8 * delta
	move_and_slide()
	if dir.length() > 0.1: look_at(global_transform.origin + dir, Vector3.UP)
	if Input.is_action_just_pressed("mouse_left"): perform_attack()

func be_possessed():
	is_possessed = true
	velocity = Vector3.ZERO
	if has_node("PossessionCamera"): get_node("PossessionCamera").current = true

func be_unpossessed():
	is_possessed = false
	if has_node("PossessionCamera"): get_node("PossessionCamera").current = false

func apply_buff(d_mult, s_mult, duration):
	damage_mult = d_mult
	speed_mult = s_mult
	await get_tree().create_timer(duration).timeout
	damage_mult = 1.0
	speed_mult = 1.0

func find_target():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_dist = 20.0
	var best_enemy = null
	for enemy in enemies:
		var dist = global_transform.origin.distance_to(enemy.global_transform.origin)
		if dist < closest_dist:
			closest_dist = dist
			best_enemy = enemy
	target_enemy = best_enemy

func combat_behavior(delta):
	var dist = global_transform.origin.distance_to(target_enemy.global_transform.origin)
	if special_ability and ability_timer <= 0:
		if dist <= special_ability.range:
			use_ability()
			return
	if dist <= attack_range:
		velocity = Vector3.ZERO
		perform_attack()
	else:
		move_to(target_enemy.global_transform.origin)

func use_ability():
	special_ability.execute(self, target_enemy)
	ability_timer = special_ability.cooldown

func follow_behavior(_delta):
	var dist = global_transform.origin.distance_to(player.global_transform.origin)
	if dist > follow_distance: move_to(player.global_transform.origin)
	else:
		velocity = Vector3.ZERO
		move_and_slide()

func move_to(target_pos):
	nav_agent.target_position = target_pos
	if nav_agent.is_navigation_finished(): return
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = (next_path_pos - global_transform.origin).normalized()
	dir.y = 0
	velocity = dir * speed * speed_mult
	move_and_slide()
	if dir.length() > 0.1: look_at(global_transform.origin + dir, Vector3.UP)

func perform_attack():
	if not has_node("AttackTimer"):
		var timer = Timer.new()
		timer.name = "AttackTimer"
		timer.wait_time = 1.0 / speed_mult
		timer.one_shot = true
		add_child(timer)
		timer.start()
		if target_enemy.has_method("take_damage"): target_enemy.take_damage(int(attack_damage * damage_mult), self)
	
	if get_node("AttackTimer").is_stopped():
		get_node("AttackTimer").wait_time = 1.0 / speed_mult
		get_node("AttackTimer").start()
		if target_enemy.has_method("take_damage"): target_enemy.take_damage(int(attack_damage * damage_mult), self)

func take_damage(amount: int): print(name, " took ", amount, " damage.")