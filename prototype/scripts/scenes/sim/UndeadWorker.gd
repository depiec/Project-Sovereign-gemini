extends CharacterBody3D

# UndeadWorker.gd - The "Imp" of Nazarick
# Automatically finds tasks in the DungeonManager queue.
# Can be possessed by the player.

@export var speed = 4.0
@export var work_damage = 25.0 # Damage per second
@onready var dungeon_manager = get_parent()
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var current_target_grid: Vector2i = Vector2i(-1, -1)
var is_busy = false
var task_timer = 0.0
var boost_timer = 0.0
var stuck_timer = 0.0
var retarget_cooldown = 0.0
var is_possessed = false

func _ready():
	set_physics_process(false)
	call_deferred("setup_nav")

func setup_nav():
	await get_tree().physics_frame
	set_physics_process(true)

func _physics_process(delta):
	if is_possessed:
		handle_possessed_movement(delta)
		return

	if boost_timer > 0:
		boost_timer -= delta
	if retarget_cooldown > 0:
		retarget_cooldown -= delta
	
	if is_busy:
		handle_task(delta)
		return

	if retarget_cooldown <= 0:
		find_work()
	
	if current_target_grid != Vector2i(-1, -1):
		move_to_target(delta)

func handle_possessed_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	velocity = dir * speed * 1.5
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	move_and_slide()
	
	if dir.length() > 0.1:
		look_at(global_transform.origin + dir, Vector3.UP)

func be_possessed():
	is_possessed = true
	is_busy = false
	current_target_grid = Vector2i(-1, -1)
	if has_node("PossessionCamera"):
		get_node("PossessionCamera").current = true

func be_unpossessed():
	is_possessed = false
	if has_node("PossessionCamera"):
		get_node("PossessionCamera").current = false

func find_work():
	var current_type = dungeon_manager.dungeon_grid.get(current_target_grid)
	if is_busy and current_type == dungeon_manager.TileType.WALL:
		return
	elif is_busy and current_type != dungeon_manager.TileType.WALL:
		is_busy = false
		current_target_grid = Vector2i(-1, -1)

	var closest_dist = 9999.0
	var best_target = Vector2i(-1, -1)
	for i in range(dungeon_manager.digging_queue.size()):
		var target = dungeon_manager.digging_queue[i]
		if dungeon_manager.is_adjacent_to_open_space(target):
			var dist = global_transform.origin.distance_to(Vector3(target.x * 2.0, 1.0, target.y * 2.0))
			if dist < closest_dist:
				closest_dist = dist
				best_target = target
	
	if best_target != Vector2i(-1, -1):
		current_target_grid = best_target
		return
	
	closest_dist = 9999.0
	best_target = Vector2i(-1, -1)
	for pos in dungeon_manager.dungeon_grid.keys():
		if dungeon_manager.dungeon_grid[pos] == dungeon_manager.TileType.EMPTY:
			var dist = global_transform.origin.distance_to(Vector3(pos.x * 2.0, 1.0, pos.y * 2.0))
			if dist < closest_dist:
				closest_dist = dist
				best_target = pos
	
	if best_target != Vector2i(-1, -1):
		current_target_grid = best_target
		return
			
	current_target_grid = Vector2i(-1, -1)

func move_to_target(delta):
	var target_world_pos = Vector3(current_target_grid.x * 2.0, 1.0, current_target_grid.y * 2.0)
	nav_agent.target_position = target_world_pos
	
	if nav_agent.is_navigation_finished():
		start_task()
		return
		
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = (next_path_pos - global_transform.origin).normalized()
	dir.y = 0
	
	var current_speed = speed * 2.0 if boost_timer > 0 else speed
	var type = dungeon_manager.dungeon_grid.get(current_target_grid)
	var dist = global_transform.origin.distance_to(target_world_pos)
	
	if type == dungeon_manager.TileType.WALL:
		if dist < 1.6 or is_on_wall():
			start_task()
		else:
			velocity = dir * current_speed
			move_and_slide()
			check_stuck(delta)
	else:
		if dist < 0.5:
			start_task()
		else:
			velocity = dir * current_speed
			move_and_slide()
			check_stuck(delta)

func check_stuck(delta):
	if velocity.length() < 0.5:
		stuck_timer += delta
	else:
		stuck_timer = 0.0
	
	if stuck_timer > 1.5:
		global_transform.origin += Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
		if stuck_timer > 3.0:
			current_target_grid = Vector2i(-1, -1)
			stuck_timer = 0.0
			retarget_cooldown = 1.0

func start_task():
	is_busy = true
	velocity = Vector3.ZERO
	task_timer = 2.0
	if boost_timer > 0: task_timer /= 2.0

func handle_task(delta):
	var type = dungeon_manager.dungeon_grid.get(current_target_grid)
	if type == dungeon_manager.TileType.WALL or type == dungeon_manager.TileType.REINFORCED_WALL:
		var damage_this_frame = work_damage * delta
		if boost_timer > 0: damage_this_frame *= 2.0
		dungeon_manager.damage_wall(current_target_grid, damage_this_frame)
		if dungeon_manager.dungeon_grid.get(current_target_grid) == dungeon_manager.TileType.EMPTY:
			is_busy = false
			current_target_grid = Vector2i(-1, -1)
	else:
		task_timer -= delta
		if task_timer <= 0:
			is_busy = false
			if type == dungeon_manager.TileType.EMPTY:
				dungeon_manager.claim_tile(current_target_grid)
			current_target_grid = Vector2i(-1, -1)

func be_slapped():
	boost_timer = 10.0
	print(name, " was slapped by Ainz-sama! Working harder!")

func get_grid_pos() -> Vector2i:
	return Vector2i(round(global_transform.origin.x / 2.0), round(global_transform.origin.z / 2.0))
