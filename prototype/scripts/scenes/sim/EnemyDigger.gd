extends CharacterBody3D

# EnemyDigger.gd - Hero/Worker AI that tunnels into the dungeon.

@export var speed = 3.0
@export var dig_damage = 15.0 # Slower than Imps
@onready var dungeon_manager = get_parent()
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var current_target_grid: Vector2i = Vector2i(-1, -1)
var is_digging = false
var health = 50

func _ready():
	add_to_group("enemies")
	add_to_group("diggers")
	set_physics_process(false)
	call_deferred("setup_nav")

func setup_nav():
	await get_tree().physics_frame
	set_physics_process(true)

func _physics_process(delta):
	if is_digging:
		handle_digging(delta)
		return

	if current_target_grid == Vector2i(-1, -1):
		find_target_wall()
	
	if current_target_grid != Vector2i(-1, -1):
		move_to_wall(delta)

func find_target_wall():
	# Target the closest wall that is adjacent to Nazarick's open space
	# This simulates tunneling in from the outside.
	var closest_dist = 9999.0
	var best_wall = Vector2i(-1, -1)
	
	for pos in dungeon_manager.dungeon_grid.keys():
		if dungeon_manager.dungeon_grid[pos] == dungeon_manager.TileType.WALL:
			# Enemies can dig any wall, but prioritize those near the center
			var dist = global_transform.origin.distance_to(Vector3(pos.x * 2.0, 1.0, pos.y * 2.0))
			if dist < closest_dist:
				closest_dist = dist
				best_wall = pos
	
	current_target_grid = best_wall

func move_to_wall(_delta):
	var target_world_pos = Vector3(current_target_grid.x * 2.0, 1.0, current_target_grid.y * 2.0)
	nav_agent.target_position = target_world_pos
	
	var dist = global_transform.origin.distance_to(target_world_pos)
	if dist < 1.5 or is_on_wall():
		start_digging()
		return
		
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = (next_path_pos - global_transform.origin).normalized()
	dir.y = 0
	
	velocity = dir * speed
	move_and_slide()

func start_digging():
	is_digging = true
	velocity = Vector3.ZERO
	print("Enemy is tunneling into Nazarick at: ", current_target_grid)

func handle_digging(delta):
	if dungeon_manager.dungeon_grid.get(current_target_grid) != dungeon_manager.TileType.WALL:
		# Wall is already gone
		is_digging = false
		current_target_grid = Vector2i(-1, -1)
		return

	dungeon_manager.damage_wall(current_target_grid, dig_damage * delta)
	
	# If wall collapses
	if dungeon_manager.dungeon_grid.get(current_target_grid) == dungeon_manager.TileType.EMPTY:
		is_digging = false
		current_target_grid = Vector2i(-1, -1)

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		queue_free()
