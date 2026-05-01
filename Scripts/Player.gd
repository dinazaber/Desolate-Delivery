extends CharacterBody3D

var cameraDistance = 15

# --- NODES ---
@onready var playerCollision = $PlayerCollision
var screenEffect: ColorRect
@onready var playerRay = $shakeable_camera/PlayerRay
var grabbedObject: RigidBody3D = null
@onready var hold_pos = $shakeable_camera/holdPos
@onready var enemyBounceCheck = $EnemyBounceCheck
@onready var speedParticles = $SpeedParticles


# --- WEAPONS ---
@onready var SMG = $shakeable_camera/Hands/RightHand/SMG
@onready var beggarsShotgun = $shakeable_camera/Hands/RightHand/BeggarsShotgun
@onready var steamer = $shakeable_camera/Hands/LeftHand/Steamer
@onready var drill = $shakeable_camera/Hands/LeftHand/Drill
@onready var current_gun_R = SMG
@onready var current_gun_L = steamer


# --- VARIABLES ---
var SPEED: float
var accel_mod: float = 1.0 #acceleration modifier
var dash: bool = false
var canDash: bool = true
var knocked: bool = false
var crouch: bool = false
var slide: bool = false
var drillJump: bool = true
var airborne: bool = false
var dead: bool = false
var canShoot: bool = true

var isInInterior = false
var currentRoof = null

var yaw = 0.0
var pitch = 0.0
var mouse_input: Vector2
var grenadeCool: float = 100.0
var dashCool: float = 100.0
var landVel: float = 0.0
var fireDelay: float = 15.0 # Delay between object throwing and shooting


# --- PLAYER STATS ---
@export_category("DEBUG")
@export var DEBUG_deathBypass: bool = false

@export_category("PLAYER STATS")
const PLAYER_MAX_HEALTH = 100.0
@export var player_health: float = PLAYER_MAX_HEALTH
@export var coolOnKill: float = 15.0
@export var grenadeCoolTime: float = 8.0 # cooldown time (s)
@export var walk_speed: float = 5.0
@export var crouch_speed: float = 2.5
@export var dash_speed: float = 22.5
@export var dashCoolTime: float = 1.75 # cooldown time (s)
@export var jump_speed: float = 8.0


# --- INSTANCES ---
var spear = load("res://Scenes/Weapons/Spear.tscn")
var instance_spear
var grenade = load("res://Scenes/Weapons/Grenade.tscn")
var instance_grenade




@onready var spearSpawn = $shakeable_camera/Hands/RightHand/SpeargunPlaceholder/Barrel #What to do with this???


# --- UI ---
@onready var crosshair = $HUD/crosshair
@onready var healthBar = $HUD/HealthBar
@onready var grenadeBar = $HUD/GrenadeBar
@onready var dashBar = $HUD/DashBar
@onready var heatBar_R = $HUD/HeatRight
@onready var heatBar_L = $HUD/HeatLeft

# --- CAMERA ---
@onready var camera = $shakeable_camera
@onready var camAnim = $cameraAnimation
@onready var camDefHeight = camera.position.y
@export_category("CAMERA")
@export var cam_speed: float = 0.005 #mouse sens
@export var cam_rot_amount: float = 0.03 #camera tilt

# --- Effects ---
@onready var hands = $shakeable_camera/Hands
var def_gun_pos: Vector3
@export_category("GUN SWAY")
@export var gun_sway_amount: float = 5.0
@export var gun_rot_amount: float = 0.01

# --- SIGNALS ---
signal playerDead
signal restoreCool(coolOnKill)

func save():
	var data = {
		"level_scene": get_tree().current_scene.scene_file_path,
		"filename": get_scene_file_path(),
		"parent": get_parent().get_path(),
		"transform": global_transform,
		"player_health": player_health
	}
	return data


# not used - delete ?
func SuperTimerTimeOut() -> void:
	if !canDash:
		canDash = true


func updateScreenEffect(): #Function for current and future screen effects
	var forward = -camera.global_transform.basis.z
	var horizontal_forward = Vector3(forward.x, 0, forward.z).normalized()
	var dot = forward.dot(horizontal_forward)
	var factor = clamp(dot, 0.0, 1.0)
	screenEffect.material.set("shader_parameter/look_angle_factor", factor)
	


func _ready() -> void:
	#platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
	
	screenEffect = get_tree().get_first_node_in_group("Effects")
	
	cam_speed = SettingsManager.settings.controls.mouse_sensitivity
	SettingsManager.player = self
	def_gun_pos = hands.position
	
	healthBar.max_value = PLAYER_MAX_HEALTH
	current_gun_R.draw(1.0)

func _input(event):
	if dead: return
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Throwable objects
	if Input.is_action_just_pressed("E"):
		if grabbedObject:
			if grabbedObject.can_let_go():
				grabbedObject.is_held = false
				grabbedObject.gravity_scale = 1.0
				grabbedObject.linear_damp = 0.0
				remove_collision_exception_with(grabbedObject)
				grabbedObject = null
		else: 
			if playerRay.is_colliding():
				var collider = playerRay.get_collider()
				var distance = global_position.distance_to(collider.global_position)
				if collider is RigidBody3D and distance < 3:
					grabbedObject = collider
					grabbedObject.is_held = true
					grabbedObject.gravity_scale = 0.0
					grabbedObject.linear_damp = 0.0
					add_collision_exception_with(grabbedObject)
	
	# Weapon Switch
	if Input.is_action_just_pressed("1") and !drill.in_action: # smg
		if current_gun_R != SMG:
			await current_gun_R.undraw(1.0, false)
			hideWeapons()
			current_gun_R = SMG
			current_gun_R.show()
			current_gun_R.draw(1.0)
	
	elif Input.is_action_just_pressed("2") and !drill.in_action: # beggars shotgun
		if current_gun_R != beggarsShotgun:
			await current_gun_R.undraw(1.0, false)
			hideWeapons()
			current_gun_R = beggarsShotgun
			current_gun_R.show()
			current_gun_R.draw(1.0)
	
	
	if Input.is_action_just_pressed("Wheel"):
		throw_grenade()
	
	if Input.is_action_pressed("Space"): drillJump = false
	else: drillJump = true
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			yaw-=event.relative.x * cam_speed
			pitch+=event.relative.y * cam_speed
			pitch = clamp(pitch, deg_to_rad(-90), deg_to_rad(90))
			mouse_input = event.relative
			
		#if event is InputEventMouseButton: #UNUSED
			#if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				#cameraDistance+=1.5
			#elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				#cameraDistance-=1.5
				

func _physics_process(delta):
	if screenEffect!=null: updateScreenEffect()
	
	#cameraDistance = clamp(cameraDistance,15, 45)
	
	#neg vals are for recharge delay i.e -5 is 0.5 sec rechare delay VLAD
	grenadeCool = clamp(grenadeCool + (100 * delta) / grenadeCoolTime, -5.0, 100.0)
	dashCool = clamp(dashCool + (100 * delta) / dashCoolTime, -10.0, 100.0)
	
	fireDelay = clamp(fireDelay + (100 * delta), 0, 15.0)
	
	if !dead:
		rotation.y = lerp_angle(rotation.y, yaw, delta * 30.0) # left/right
		camera.rotation.x = lerp_angle(camera.rotation.x, -pitch, delta * 30.0)
		
	
	check_player_feet()

	
	if Input.is_action_pressed("LeftMouse") and !drill.in_action and !dead:
		if !grabbedObject and fireDelay==15.0:
			match current_gun_R:
				SMG: current_gun_R.shoot()
				beggarsShotgun: current_gun_R.charge()
		elif grabbedObject:
			if grabbedObject.can_let_go():
				grabbedObject.is_held = false
				grabbedObject.gravity_scale = 1
				grabbedObject.linear_damp = 0.0
				remove_collision_exception_with(grabbedObject)
				grabbedObject = null
				fireDelay = 0.0
	
	if Input.is_action_just_released("LeftMouse") and !drill.in_action and !dead:
		if !grabbedObject and fireDelay==15.0:
			match current_gun_R:
				beggarsShotgun: current_gun_R.shoot()
	
	
	if Input.is_action_just_pressed("RightMouse") and !drill.in_action and !dead:
		current_gun_L.show()
		await current_gun_L.shoot()
		current_gun_L.hide()
	
	if Input.is_action_just_pressed("F") and !dead:
		if !drill.in_action and !current_gun_L.in_action:
			current_gun_R.undraw(1.5, true)
			drill.show()
			await drill.punch(velocity.length() if velocity.length() >= 15.0 else 0.0)
			current_gun_R.draw(1.5)
			drill.hide()
	
	
	handle_grabbed_object(delta)
	
	if Input.is_action_pressed("Ctrl") and !dead: # crouch/slide
		crouch = true
		playerCollision.shape.height = lerp(playerCollision.shape.height, 1.0, delta * 15.0)
		if velocity.length() > crouch_speed + 0.1: # 0.1 is epsilon for numerical error
			slide = true
			floor_stop_on_slope = false
			accel_mod = 0.05
			if is_on_floor():
				var normal = get_floor_normal()
				normal.y = -normal.y
				velocity += normal * 0.3
		else:
			slide = false
			floor_stop_on_slope = true
			accel_mod = 1.0
	elif !$UncrouchCheck.is_colliding():
		slide = false
		floor_constant_speed = true
		crouch = false
		playerCollision.shape.height = lerp(playerCollision.shape.height, 2.0, delta * 10.0)
		accel_mod = 1.0
	
	if crouch:
		SPEED = move_toward(SPEED, crouch_speed, delta * 15.0)
	else:
		SPEED = move_toward(SPEED, walk_speed, delta * 15.0)
	
	# Get direction
	var currentInput = Input.get_vector("A", "D", "W", "S")
	if dead: currentInput = Vector3.ZERO
	var direction = (transform.basis * Vector3(currentInput.x, 0, currentInput.y)).normalized()
	if direction: $StairBounds.look_at($StairBounds.global_position + direction, Vector3.UP) #Avoids errors with look_at trying to look at the same target
	if direction and is_on_floor() and $StairBounds/StairsMin.is_colliding() and !$StairBounds/StairsMax.is_colliding() and is_on_wall():
		velocity.y = 4
	
	
	# dash
	if Input.is_action_just_pressed("Shift") and direction and dashCool == 100.0 and !crouch and !dead:
		dashCool = -10.0
		var dashDir = direction
		knockBack(dashDir, dash_speed, false, 0.2)
		#canDash = false
		#$SuperTimer.set("wait_time",0.5)
		#$SuperTimer.start()
		await get_tree().create_timer(0.2).timeout
		if !is_on_floor() or !slide:
			knockBack(-dashDir, 15 * Vector3(velocity.x, 0.0, velocity.z).length() / dash_speed, false, 0.0)
	
	#Basic movement
	if is_on_floor(): # grounded speed
		if airborne:
			airborne = false
			camera.add_trauma(clamp(0.7 * landVel/10, 0.0, 5.0))
			landVel = 0.0
		
		if Input.is_action_just_pressed("Space") and !dead:
			velocity.y += jump_speed * (0.75 if crouch else 1.0)
		
		if dead:
			camera.rotation.x = lerp_angle(camera.rotation.x, 0.0, delta * 10.0)
		
		if direction:
			# head bob
			if !slide:
				var vel = velocity.length()
				var bob_amount: float = 0.05 * clamp(vel/5, 0, 2)
				var bob_freq: float = 0.005
				var bob_y = sin(Time.get_ticks_msec() * 2 * bob_freq)
				camera.position.y = lerp(camera.position.y, camDefHeight + bob_y * bob_amount, delta * 10.0)
			
			# walk speed
			if !knocked:
				velocity = lerp(velocity, direction * SPEED, delta * 10.0 * accel_mod)
		
		else: # no input speed
			velocity.x = lerp(velocity.x, 0.0, delta * 7.0 * accel_mod)
			velocity.z = lerp(velocity.z, 0.0, delta * 7.0 * accel_mod)
		
	else: # airborne speed
		airborne = true
		landVel = abs(velocity.y)
		velocity.y -= delta * 15.0 # Gravity
		
		if !knocked:
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 1.5 * accel_mod)
			velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 1.5 * accel_mod)
	
	if !dead:
		cam_gun_tilt_sway(currentInput.x, currentInput.y, delta)
		gun_bob(velocity.length(), currentInput, delta)
	
	handle_healthBar()
	handle_heatBars()
	
	push_object()
	move_and_slide()
	speed_lines()



# --- EFFECTS ---
func cam_gun_tilt_sway(input_x, input_y, delta):
	if camera:
		camera.rotation.z = lerp(camera.rotation.z, -input_x * cam_rot_amount, delta * 5.0)
	if hands:
		hands.rotation.z = lerp(hands.rotation.z, -input_x * gun_rot_amount * 10, delta * 3.0)
		hands.rotation.x = lerp(hands.rotation.x, input_y * gun_rot_amount * 20, delta * 1.5)
		
	mouse_input = lerp(mouse_input, Vector2.ZERO, delta * 10.0)
	hands.rotation.x = lerp(hands.rotation.x, mouse_input.y * gun_rot_amount, delta * 15.0)
	hands.rotation.y = lerp(hands.rotation.y, mouse_input.x * gun_rot_amount, delta * 15.0)

func gun_bob(vel: float, input, delta):
	if hands:
		if vel > 0.5:
			var bob_amount: float = 0.01 * clamp(vel/5, 0, 2)
			var bob_freq: float = 0.005
			var bob_y
			var bob_x
			if is_on_floor() and input and !slide:
				bob_y = sin(Time.get_ticks_msec() * 2 * bob_freq)
				bob_x = sin(Time.get_ticks_msec() * bob_freq)
			else:
				bob_y = -velocity.y * 0.1
				bob_x = 0
			hands.position.y = lerp(hands.position.y, def_gun_pos.y + bob_y * bob_amount, delta * 10.0)
			hands.position.x = lerp(hands.position.x, def_gun_pos.x + bob_x * bob_amount, delta * 10.0)
		else:
			hands.position.y = lerp(hands.position.y, def_gun_pos.y, delta * 10.0)
			hands.position.x = lerp(hands.position.x, def_gun_pos.x, delta * 10.0)

func speed_lines():
	speedParticles.amount_ratio = (velocity.length() - 15.0) / 5.0 + 0.2
	speedParticles.look_at(global_position + velocity + Vector3(0.001, 0.0, 0.0)) # last bit is to prevent colinear warnings

func hideWeapons(): #We will add here check for left/right side later I guess
	for i in $shakeable_camera/Hands/RightHand.get_children():
		if i is Node3D: i.hide()

# --- PHYSICS ---
func throw_grenade():
	if grenadeCool == 100.0:
		instance_grenade = grenade.instantiate()
		instance_grenade.position = global_position
		var throw_dir = -camera.global_transform.basis.z.normalized()
		var forward_force = 10.0
		var upward_force = 5.0
		instance_grenade.apply_central_impulse((throw_dir * forward_force) + Vector3(0, upward_force, 0) + velocity)
		instance_grenade.apply_torque_impulse(Vector3(randf(), randf(), randf()) * instance_grenade.mass)
		get_parent().add_child(instance_grenade)
		grenadeCool = -5.0

func knockBack(direction, force, slowOnGround, time):
	if slowOnGround and is_on_floor():
		force /= 2
	knocked = true
	velocity += direction * force
	await get_tree().create_timer(time).timeout
	knocked = false

func check_player_feet():
	if enemyBounceCheck.has_overlapping_bodies():
		var bodies = enemyBounceCheck.get_overlapping_bodies()
		var enemyCount: int = 0
		var physicsCount: int = 0
		for body in bodies:
			if body.is_in_group("Enemy"):
				enemyCount += 1
			if body.is_in_group("Physics"):
				physicsCount += 1
		if enemyCount: # bounce on enemy head
			if is_on_floor():
				knockBack(get_floor_normal(), 8.0, true, 0.3)
		if physicsCount: # increase slide on phys objects
			floor_max_angle = deg_to_rad(15.0)
		else: floor_max_angle = deg_to_rad(45.0)
	else: floor_max_angle = deg_to_rad(45.0)

func handle_grabbed_object(delta):
	if grabbedObject:
		var holdPos = hold_pos
		var distance = grabbedObject.global_position.distance_to(holdPos.global_position)
		var dir = holdPos.global_position - grabbedObject.global_position
		if (distance > 1.5 or !grabbedObject.is_held) and grabbedObject.can_let_go():
			grabbedObject.is_held = false
			grabbedObject.gravity_scale = 1.0
			grabbedObject.linear_damp = 0.0
			remove_collision_exception_with(grabbedObject)
			grabbedObject = null
			return
		
		grabbedObject.linear_damp = 16/(grabbedObject.mass**0.67)
		
		var force = dir * distance**0.25 * 5000/(10 + grabbedObject.mass)
		force = clamp(force, Vector3.ZERO, dir * distance**0.25 * 357) # limit force
		grabbedObject.apply_central_force(force)
		grabbedObject.angular_velocity = Vector3.ZERO
		grabbedObject.global_rotation.x = lerp_angle(grabbedObject.global_rotation.x, holdPos.global_rotation.x, delta * 100/(10 + grabbedObject.mass))
		grabbedObject.global_rotation.y = lerp_angle(grabbedObject.global_rotation.y, holdPos.global_rotation.y, delta * 100/(10 + grabbedObject.mass))
		grabbedObject.global_rotation.z = lerp_angle(grabbedObject.global_rotation.z, holdPos.global_rotation.z, delta * 100/(10 + grabbedObject.mass))

func push_object():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
			
		if collider is RigidBody3D and collider != grabbedObject:
			var push_dir = -collision.get_normal()
			var push_dir_vel_dif = (get_real_velocity().normalized()).dot(push_dir) - collider.linear_velocity.dot(push_dir)
			push_dir_vel_dif = max(0.0, push_dir_vel_dif)
			
			const PLAYER_MASS = 50.0
			var mass_ratio = min(1.0, PLAYER_MASS / collider.mass)
			
			push_dir.y = 0.0
			var push_force = mass_ratio * 30.0
			collider.apply_impulse(push_dir * push_dir_vel_dif * push_force, collision.get_position() - collider.global_position)


# --- HEALTH AND DAMAGE
func checkLifeLine():
	if player_health <= 0 and dead == false:
		if !DEBUG_deathBypass:
			dead = true
			current_gun_R.undraw(1.0, true)
			await get_tree().create_timer(0.3).timeout
			camAnim.play("death")
			playerDead.emit()

func enemy_killed():
	restoreCool.emit(coolOnKill)

func damage_taken(recieved_damage, isPlayer):
	if isPlayer: recieved_damage /= 3
	player_health -= recieved_damage
	camera.add_trauma(recieved_damage/20)
	checkLifeLine()

func heal(heal_amount):
	player_health = clamp(player_health + heal_amount, 0.0, PLAYER_MAX_HEALTH)

# --- UI ---
func handle_healthBar():
	var health_dif = abs(healthBar.value - player_health)
	healthBar.value = move_toward(healthBar.value, player_health, health_dif/5)

func handle_heatBars():
	var heat_dif_R = abs(heatBar_R.value - current_gun_R.get_heat())
	heatBar_R.value = move_toward(heatBar_R.value, current_gun_R.get_heat(), heat_dif_R/5)
	var heat_dif_L = abs(heatBar_L.value - current_gun_L.get_heat())
	heatBar_L.value = move_toward(heatBar_L.value, current_gun_L.get_heat(), heat_dif_L/5)
	
	var grenade_dif = abs(grenadeBar.value - grenadeCool)
	grenadeBar.value = move_toward(grenadeBar.value, grenadeCool, grenade_dif/5)
	var dash_dif = abs(dashBar.value - dashCool)
	dashBar.value = move_toward(dashBar.value, dashCool, dash_dif/3)


# --- "LATER" DUMP ---
#func shoot_speargun():
	#if !rightWeaponAnim.is_playing() and canShoot:
		#rightWeaponAnim.play("ShootSpeargun")
		#instance_spear = spear.instantiate()
		#instance_spear.position = spearSpawn.global_position
		#instance_spear.transform.basis = spearSpawn.global_transform.basis
		#get_parent().add_child(instance_spear)
		#if playerRay.is_colliding():
			#instance_spear.set_velocity(playerRay.get_collision_point())
		#else:
			#instance_spear.set_velocity(playerRay_end.global_position)
