extends CharacterBody3D

# AinzPlayer.gd - Player Logic (Combat Layer)
# Handles movement and spell casting.

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var current_mp: int = 100
var current_hp: int = 100

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var visuals: MeshInstance3D = $MeshInstance3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

@onready var hp_label: Label = %HPLabel
@onready var mp_label: Label = %MPLabel

var is_casting: bool = false
var cast_timer: float = 0.0
var current_spell: SpellResource

func _ready():
	# Sync initial stats from GameManager
	current_mp = GameManager.player_state.mp
	current_hp = GameManager.player_state.hp
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	update_hud()

func _physics_process(delta):
	if is_casting:
		handle_casting(delta)
		return

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if input_dir:
		# Get the camera's horizontal rotation (Y-axis)
		var camera_rot_y = spring_arm.global_transform.basis.get_euler().y
		
		# Create a direction vector based on input and camera rotation
		var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_rot_y).normalized()
		
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Rotate Character (Mesh) to face movement direction smoothly
		var target_rotation = atan2(velocity.x, velocity.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_rotation, delta * 10.0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func handle_casting(delta):
	cast_timer -= delta
	# Update HUD with casting progress
	mp_label.text = "CASTING: %.1fs" % cast_timer
	
	if cast_timer <= 0:
		complete_cast()

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		spring_arm.rotation.y -= event.relative.x * 0.005
		spring_arm.rotation.x -= event.relative.y * 0.005
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)
		
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event is InputEventMouseButton and event.pressed:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			return

		if event.button_index == MOUSE_BUTTON_LEFT and GameManager.player_state.known_spells.size() > 0:
			start_cast(GameManager.player_state.known_spells[0])
		elif event.button_index == MOUSE_BUTTON_RIGHT and GameManager.player_state.known_spells.size() > 1:
			start_cast(GameManager.player_state.known_spells[1])

func start_cast(spell: SpellResource):
	if current_mp >= spell.mana_cost:
		current_spell = spell
		if spell.cast_time > 0:
			is_casting = true
			cast_timer = spell.cast_time
			print("Channeling: ", spell.spell_name)
		else:
			complete_cast()
	else:
		print("Not enough MP!")

func complete_cast():
	is_casting = false
	current_mp -= current_spell.mana_cost
	update_hud()
	
	print("Cast Complete: ", current_spell.spell_name)
	
	# Snap Character Rotation to Camera Direction instantly for aiming (Horizontal only)
	var camera_rot_y = spring_arm.global_transform.basis.get_euler().y
	visuals.rotation.y = camera_rot_y
	
	# Calculate the full 3D aim direction from the SpringArm/Camera
	var aim_dir = -spring_arm.global_transform.basis.z.normalized()
	
	if current_spell.projectile_scene:
		var projectile = current_spell.projectile_scene.instantiate()
		get_parent().add_child(projectile)
		
		# Position slightly in front of Ainz (using visual horizontal facing)
		var spawn_pos = visuals.global_transform.origin + (-visuals.global_transform.basis.z * 1.5) + Vector3(0, 1.5, 0)
		projectile.global_transform.origin = spawn_pos
		
		# Launch logic
		if projectile is RigidBody3D:
			projectile.linear_velocity = aim_dir * 20.0
		elif current_spell.is_super_tier:
			# For Super Tier, we spawn it on the ground at the aim point
			projectile.global_transform.origin = global_transform.origin + (aim_dir * 10.0)
			projectile.global_transform.origin.y = 0.5

func update_hud():
	if hp_label:
		hp_label.text = "HP: %d" % current_hp
	if mp_label:
		mp_label.text = "MP: %d" % current_mp