extends Node3D

# DungeonManager.gd - Handles DK-style grid management
# Tiles are 2x2 units.

enum TileType { WALL, EMPTY, CLAIMED, TREASURY, LIBRARY, BARRACKS, REINFORCED_WALL }

var grid_width = 20
var grid_depth = 20
var tile_size = 2.0

# Dictionary keyed by Vector2i(x, z) storing TileType
var dungeon_grid = {}
var wall_health = {} # Stores HP for WALL tiles

const MAX_WALL_HEALTH = 100.0
const REINFORCED_HEALTH = 500.0

# Marked for digging
var digging_queue = []

signal grid_updated
signal stats_updated(stats)

var room_counts = {
	TileType.TREASURY: 0,
	TileType.LIBRARY: 0,
	TileType.BARRACKS: 0,
	TileType.REINFORCED_WALL: 0
}

var resource_timer: float = 0.0
var payment_timer: float = 0.0
var minions_happy: bool = true

@onready var nav_region: NavigationRegion3D = get_parent()

var bake_timer: float = 0.0
var needs_bake: bool = false

func _process(delta):
	resource_timer += delta
	if resource_timer >= 5.0:
		generate_resources()
		resource_timer = 0.0
	
	payment_timer += delta
	if payment_timer >= 30.0:
		process_payroll()
		payment_timer = 0.0
	
	if needs_bake:
		bake_timer += delta
		if bake_timer >= 0.2: # Wait for batch changes
			nav_region.bake_navigation_mesh()
			needs_bake = false
			bake_timer = 0.0

func generate_resources():
	if room_counts[TileType.TREASURY] > 0:
		GameManager.add_resource("gold", room_counts[TileType.TREASURY] * 10)
	
	if room_counts[TileType.LIBRARY] > 0:
		GameManager.player_state.mp = min(GameManager.player_state.mp + room_counts[TileType.LIBRARY], 1000)

func process_payroll():
	var workers = get_tree().get_nodes_in_group("workers").size()
	var liches = get_tree().get_nodes_in_group("liches").size()
	
	var total_cost = (workers * 10) + (liches * 50)
	
	if GameManager.spend_resource("gold", total_cost):
		minions_happy = true
		print("Payroll processed. Minions are satisfied.")
	else:
		minions_happy = false
		print("Nazarick is broke! Minions are unhappy!")

func _ready():
	setup_initial_grid()

func setup_initial_grid():
	for x in range(grid_width):
		for z in range(grid_depth):
			var pos = Vector2i(x, z)
			if x > 8 and x < 12 and z > 8 and z < 12:
				dungeon_grid[pos] = TileType.CLAIMED
			else:
				dungeon_grid[pos] = TileType.WALL
				wall_health[pos] = MAX_WALL_HEALTH
	
	refresh_visuals()

func trigger_rebake():
	needs_bake = true
	bake_timer = 0.0

func mark_for_digging(grid_pos: Vector2i):
	if dungeon_grid.get(grid_pos) == TileType.WALL or dungeon_grid.get(grid_pos) == TileType.REINFORCED_WALL:
		set_digging_mark(grid_pos, !digging_queue.has(grid_pos))

func set_digging_mark(grid_pos: Vector2i, state: bool):
	var type = dungeon_grid.get(grid_pos)
	if type != TileType.WALL and type != TileType.REINFORCED_WALL: return
	
	if state and not digging_queue.has(grid_pos):
		digging_queue.append(grid_pos)
		refresh_visuals()
	elif not state and digging_queue.has(grid_pos):
		digging_queue.erase(grid_pos)
		refresh_visuals()

func damage_wall(grid_pos: Vector2i, amount: float):
	if wall_health.has(grid_pos):
		wall_health[grid_pos] -= amount
		
		# Spawn Mining Particles
		var particle_scene = load("res://resources/effects/MiningParticles.tscn")
		if particle_scene:
			var p = particle_scene.instantiate()
			add_child(p)
			p.global_transform.origin = Vector3(grid_pos.x * tile_size, 1.0, grid_pos.y * tile_size)
			p.emitting = true
			get_tree().create_timer(1.0).timeout.connect(p.queue_free)

		if wall_health[grid_pos] <= 0:
			dig_tile(grid_pos)

func is_adjacent_to_open_space(grid_pos: Vector2i) -> bool:
	var neighbors = [
		Vector2i(grid_pos.x + 1, grid_pos.y),
		Vector2i(grid_pos.x - 1, grid_pos.y),
		Vector2i(grid_pos.x, grid_pos.y + 1),
		Vector2i(grid_pos.x, grid_pos.y - 1)
	]
	for n in neighbors:
		if dungeon_grid.has(n) and dungeon_grid[n] != TileType.WALL and dungeon_grid[n] != TileType.REINFORCED_WALL:
			return true
	return false

func dig_tile(grid_pos: Vector2i):
	dungeon_grid[grid_pos] = TileType.EMPTY
	digging_queue.erase(grid_pos)
	wall_health.erase(grid_pos)
	refresh_visuals()
	trigger_rebake()

func claim_tile(grid_pos: Vector2i):
	if dungeon_grid.get(grid_pos) == TileType.EMPTY:
		dungeon_grid[grid_pos] = TileType.CLAIMED
		refresh_visuals()
		trigger_rebake()

func slap_at(grid_pos: Vector2i):
	for child in get_children():
		if child.has_method("get_grid_pos") and child.get_grid_pos() == grid_pos:
			if child.has_method("be_slapped"):
				child.be_slapped()

func build_room(grid_pos: Vector2i, type: TileType):
	if dungeon_grid.get(grid_pos) == TileType.CLAIMED:
		dungeon_grid[grid_pos] = type
		if type == TileType.REINFORCED_WALL:
			wall_health[grid_pos] = REINFORCED_HEALTH
		update_room_counts()
		refresh_visuals()
		trigger_rebake()

func build_reinforced_wall(grid_pos: Vector2i):
	build_room(grid_pos, TileType.REINFORCED_WALL)

func update_room_counts():
	for key in room_counts.keys():
		room_counts[key] = 0
	for type in dungeon_grid.values():
		if room_counts.has(type):
			room_counts[type] += 1
	stats_updated.emit(room_counts)
	check_attraction()

func check_attraction():
	var total_built = 0
	for type in dungeon_grid.values():
		if type != TileType.WALL and type != TileType.REINFORCED_WALL: total_built += 1
	var target_imps = 2 + (total_built / 15)
	var current_imps = get_tree().get_nodes_in_group("workers").size()
	if current_imps < target_imps:
		spawn_minion("res://scenes/sim/entities/Imp.tscn", "workers")
	var target_liches = room_counts[TileType.LIBRARY] / 20
	var current_liches = get_tree().get_nodes_in_group("liches").size()
	if current_liches < target_liches:
		spawn_minion("res://scenes/sim/entities/ElderLich.tscn", "liches")

func spawn_minion(scene_path: String, group_name: String):
	var scene = load(scene_path)
	if not scene: return
	var minion = scene.instantiate()
	add_child(minion)
	minion.add_to_group(group_name)
	minion.global_transform.origin = Vector3(10 * tile_size, 1.0, 10 * tile_size)

func refresh_visuals():
	for child in get_children():
		if child is MeshInstance3D or child is StaticBody3D:
			child.queue_free()
	var base_floor = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(grid_width * tile_size, grid_depth * tile_size)
	base_floor.mesh = plane
	base_floor.position = Vector3(grid_width * tile_size / 2.0, 0, grid_depth * tile_size / 2.0)
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0,0,0,0)
	floor_mat.transparency = 1
	base_floor.material_override = floor_mat
	add_child(base_floor)
	for pos in dungeon_grid.keys():
		var type = dungeon_grid[pos]
		var mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(tile_size, 0.2, tile_size)
		mesh.mesh = box
		var mat = StandardMaterial3D.new()
		match type:
			TileType.WALL, TileType.REINFORCED_WALL:
				box.size.y = 2.0
				mat.albedo_color = Color(0.2, 0.1, 0.05) if type == TileType.WALL else Color(0.1, 0.1, 0.15)
				if type == TileType.REINFORCED_WALL:
					mat.metallic = 0.8
					mat.roughness = 0.2
				if digging_queue.has(pos):
					mat.emission_enabled = true
					mat.emission = Color(1.0, 0.5, 0)
					mat.emission_energy_multiplier = 2.0
				var static_body = StaticBody3D.new()
				var collision_shape = CollisionShape3D.new()
				var box_shape = BoxShape3D.new()
				box_shape.size = Vector3(tile_size, 2.0, tile_size)
				collision_shape.shape = box_shape
				static_body.add_child(collision_shape)
				mesh.material_override = mat
				static_body.add_child(mesh)
				add_child(static_body)
				static_body.position = Vector3(pos.x * tile_size, 1.0, pos.y * tile_size)
			TileType.EMPTY, TileType.CLAIMED, TileType.TREASURY, TileType.LIBRARY, TileType.BARRACKS:
				match type:
					TileType.EMPTY: mat.albedo_color = Color(0.1, 0.1, 0.1)
					TileType.CLAIMED: mat.albedo_color = Color(0.3, 0.0, 0.5)
					TileType.TREASURY: mat.albedo_color = Color(0.8, 0.7, 0.0)
					TileType.LIBRARY: mat.albedo_color = Color(0.0, 0.4, 0.8)
					TileType.BARRACKS: mat.albedo_color = Color(0.1, 0.5, 0.1)
				mesh.material_override = mat
				add_child(mesh)
				mesh.position = Vector3(pos.x * tile_size, box.size.y / 2.0, pos.y * tile_size)
	grid_updated.emit()
