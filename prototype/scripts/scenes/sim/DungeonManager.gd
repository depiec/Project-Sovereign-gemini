extends Node3D

# DungeonManager.gd - Handles DK-style grid management
# Tiles are 2x2 units.

enum TileType { WALL, EMPTY, CLAIMED, TREASURY, LIBRARY, BARRACKS }

var grid_width = 20
var grid_depth = 20
var tile_size = 2.0

# Dictionary keyed by Vector2i(x, z) storing TileType
var dungeon_grid = {}
var wall_health = {} # Stores HP for WALL tiles

const MAX_WALL_HEALTH = 100.0

# Marked for digging
var digging_queue = []

signal grid_updated
signal stats_updated(stats)

var room_counts = {
	TileType.TREASURY: 0,
	TileType.LIBRARY: 0,
	TileType.BARRACKS: 0
}

var resource_timer: float = 0.0

@onready var nav_region: NavigationRegion3D = get_parent()

var bake_timer: float = 0.0
var needs_bake: bool = false

func _process(delta):
	resource_timer += delta
	if resource_timer >= 5.0:
		generate_resources()
		resource_timer = 0.0
	
	if needs_bake:
		bake_timer += delta
		if bake_timer >= 0.2: # Wait for batch changes
			nav_region.bake_navigation_mesh()
			needs_bake = false
			bake_timer = 0.0

func trigger_rebake():
	needs_bake = true
	bake_timer = 0.0

func dig_tile(grid_pos: Vector2i):
	if dungeon_grid.get(grid_pos) == TileType.WALL:
		dungeon_grid[grid_pos] = TileType.EMPTY
		digging_queue.erase(grid_pos)
		refresh_visuals()
		trigger_rebake()

func claim_tile(grid_pos: Vector2i):
	if dungeon_grid.get(grid_pos) == TileType.EMPTY:
		dungeon_grid[grid_pos] = TileType.CLAIMED
		refresh_visuals()
		trigger_rebake()

func build_room(grid_pos: Vector2i, type: TileType):
	if dungeon_grid.get(grid_pos) == TileType.CLAIMED:
		dungeon_grid[grid_pos] = type
		update_room_counts()
		refresh_visuals()
		trigger_rebake()

func refresh_visuals():
	# In a real game, this would update a GridMap. 
	# For prototype, we'll use simple MeshInstances.
	for child in get_children():
		if child is MeshInstance3D or child is StaticBody3D: # Don't delete Imps!
			child.queue_free()
	
	# Add a base floor for the NavMesh to bake on
	var base_floor = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(grid_width * tile_size, grid_depth * tile_size)
	base_floor.mesh = plane
	base_floor.position = Vector3(grid_width * tile_size / 2.0, 0, grid_depth * tile_size / 2.0)
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0,0,0) # Hidden base
	floor_mat.transparency = 1
	floor_mat.albedo_color.a = 0
	base_floor.material_override = floor_mat
	add_child(base_floor)
	
	for pos in dungeon_grid.keys():
		var type = dungeon_grid[pos]
		var mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(tile_size, 0.2, tile_size)
		mesh.mesh = box
		
		# Set visual based on type
		var mat = StandardMaterial3D.new()
		match type:
			TileType.WALL:
				box.size.y = 2.0
				mat.albedo_color = Color(0.2, 0.1, 0.05) # Earth
				
				if digging_queue.has(pos):
					mat.emission_enabled = true
					mat.emission = Color(1.0, 0.5, 0)
					mat.emission_energy_multiplier = 2.0
				
				# Add Collision for Walls
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
				mesh.position = Vector3(0, 0, 0) # Mesh is relative to static body
			TileType.EMPTY, TileType.CLAIMED, TileType.TREASURY, TileType.LIBRARY, TileType.BARRACKS:
				match type:
					TileType.EMPTY: mat.albedo_color = Color(0.1, 0.1, 0.1)
					TileType.CLAIMED: mat.albedo_color = Color(0.3, 0.0, 0.5)
					TileType.TREASURY: mat.albedo_color = Color(0.8, 0.7, 0.0)
					TileType.LIBRARY: mat.albedo_color = Color(0.0, 0.4, 0.8)
				
				mesh.material_override = mat
				add_child(mesh)
				mesh.position = Vector3(pos.x * tile_size, box.size.y / 2.0, pos.y * tile_size)
	
	grid_updated.emit()