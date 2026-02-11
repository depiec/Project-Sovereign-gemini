extends CharacterBody3D

# AinzPlayer.gd - Player Logic (Combat Layer)
# Handles movement, spell casting, persona swapping, and ally control.

const OVERLORD_SPEED = 5.0
const MOMON_SPEED = 8.0
var SPEED = OVERLORD_SPEED
const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_mp: int = 100
var current_hp: int = 100
var is_possessed = true

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var visuals: MeshInstance3D = $MeshInstance3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var hp_label: Label = %HPLabel
@onready var mp_label: Label = %MPLabel
@onready var guardian_label: Label = %GuardianStatus

var is_casting: bool = false
var cast_timer: float = 0.0
var current_spell: SpellResource

func _ready():
	current_mp = GameManager.player_state.mp
	current_hp = GameManager.player_state.hp
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	update_hud()
	apply_persona_visuals()

func _physics_process(delta):
	if not is_possessed: return
	if is_casting:
		handle_casting(delta)
		return
	if not is_on_floor(): velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor(): velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed("swap_persona"): toggle_persona()
	if Input.is_action_just_pressed("swap_control"): try_swap_control()
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir:
		var camera_rot_y = spring_arm.global_transform.basis.get_euler().y
		var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_rot_y).normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		var target_rotation = atan2(velocity.x, velocity.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_rotation, delta * 10.0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()

func try_swap_control():
	var guardians = get_tree().get_nodes_in_group("guardians")
	if guardians.size() > 0:
		var g = guardians[0]
		be_unpossessed()
		g.be_possessed()

func be_possessed():
	is_possessed = true
	camera.current = true

func be_unpossessed():
	is_possessed = false
	velocity = Vector3.ZERO
	camera.current = false

func toggle_persona():
	if GameManager.player_state.current_persona == GameManager.Persona.OVERLORD:
		GameManager.player_state.current_persona = GameManager.Persona.MOMON
		SPEED = MOMON_SPEED
	else:
		GameManager.player_state.current_persona = GameManager.Persona.OVERLORD
		SPEED = OVERLORD_SPEED
	apply_persona_visuals()

func apply_persona_visuals():
	var mat = visuals.get_surface_override_material(0)
	if not mat:
		mat = StandardMaterial3D.new()
		visuals.set_surface_override_material(0, mat)
	if GameManager.player_state.current_persona == GameManager.Persona.OVERLORD:
		mat.albedo_color = Color(0.12, 0, 0.23)
		mat.emission = Color(0.18, 0, 0.36)
	else:
		mat.albedo_color = Color(0.05, 0.05, 0.05)
		mat.emission = Color(0.2, 0.2, 0.2)
	mat.emission_enabled = true

func handle_casting(delta):
	cast_timer -= delta
	mp_label.text = "CASTING: %.1fs" % cast_timer
	if cast_timer <= 0: complete_cast()

func _unhandled_input(event):
	if not is_possessed:
		if event.is_action_pressed("swap_control"):
			var guardians = get_tree().get_nodes_in_group("guardians")
			for g in guardians:
				if g.is_possessed:
					g.be_unpossessed()
					be_possessed()
					return
		return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		spring_arm.rotation.y -= event.relative.x * 0.005
		spring_arm.rotation.x -= event.relative.y * 0.005
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)
	if event.is_action_pressed("ui_cancel"): Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseButton and event.pressed:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			return
		if GameManager.player_state.current_persona == GameManager.Persona.OVERLORD:
			if event.button_index == MOUSE_BUTTON_LEFT and GameManager.player_state.known_spells.size() > 0:
				start_cast(GameManager.player_state.known_spells[0])
			elif event.button_index == MOUSE_BUTTON_RIGHT and GameManager.player_state.known_spells.size() > 1:
				start_cast(GameManager.player_state.known_spells[1])
		else:
			if event.button_index == MOUSE_BUTTON_LEFT: perform_melee_attack()

func perform_melee_attack():
	print("Momon: Twin Blade Strike!")

func start_cast(spell: SpellResource):
	if current_mp >= spell.mana_cost:
		current_spell = spell
		if spell.cast_time > 0:
			is_casting = true
			cast_timer = spell.cast_time
		else: complete_cast()
	else: print("Not enough MP!")

func complete_cast():
	is_casting = false
	current_mp -= current_spell.mana_cost
	update_hud()
	var camera_rot_y = spring_arm.global_transform.basis.get_euler().y
	visuals.rotation.y = camera_rot_y
	var aim_dir = -spring_arm.global_transform.basis.z.normalized()
	if current_spell.projectile_scene:
		var projectile = current_spell.projectile_scene.instantiate()
		get_parent().add_child(projectile)
		var spawn_pos = visuals.global_transform.origin + (-visuals.global_transform.basis.z * 1.5) + Vector3(0, 1.5, 0)
		projectile.global_transform.origin = spawn_pos
		if projectile is RigidBody3D:
			projectile.linear_velocity = aim_dir * 20.0
			if "caster" in projectile: projectile.caster = self
		elif current_spell.is_super_tier:
			projectile.global_transform.origin = global_transform.origin + (aim_dir * 10.0)
			projectile.global_transform.origin.y = 0.5

func gain_xp(amount): print("Ainz gained ", amount, " XP.")

func update_hud():
	if hp_label: hp_label.text = "HP: %d" % current_hp
	if mp_label: mp_label.text = "MP: %d" % current_mp
	if guardian_label: guardian_label.text = "Guardian: %s" % GameManager.player_state.active_guardian
