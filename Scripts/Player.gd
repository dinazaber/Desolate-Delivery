extends CharacterBody3D

var cameraDistance = 15

# --- NODES ---
@onready var playerCollision = $PlayerCollision
var screenEffect: ColorRect
@onready var playerRay = $shakeable_camera/PlayerRay
var grabbedObject: RigidBody3D = null
@onready var hold_pos = $shakeable_camera/holdPos
@onready var vaultCheck: ShapeCast3D = $VaultCheck
@onready var enemyBounceCheck = $Feet/EnemyBounceCheck
@onready var speedParticles = $SpeedParticles
@onready var wallrun_timer: Timer = $WallrunTimer
var current_room = null


# --- WEAPONS ---
@onready var destabilizer = $shakeable_camera/Hands/RightHand/Destabilizer
@onready var beggarsShotgun = $shakeable_camera/Hands/RightHand/BeggarsShotgun
@onready var devestator = $shakeable_camera/Hands/RightHand/Devestator
@onready var steamer = $shakeable_camera/Hands/LeftHand/Steamer
@onready var drill = $shakeable_camera/Hands/LeftHand/Drill
@onready var current_gun_R = destabilizer
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
var vaulting: bool = false
var airborne: bool = false
var dead: bool = false
var canShoot: bool = true

var isInInterior = false
var currentRoof = null

var yaw = 0.0
var pitch = 0.0
var direction: Vector3 = Vector3.ZERO
var pullTarget
var mouse_input: Vector2
var grenadeCool: float = 100.0
var dashCool: float = 100.0
var landVel: float = 0.0
var fireDelay: float = 15.0 # Delay between object throwing and shooting


# --- PLAYER STATS ---
@export_category("DEBUG")
@export var DEBUG_deathBypass: bool = false
@export_range(0.0, 2.0, 0.01) var DEBUG_engineTimeScale: float = 1.0 

@export_category("PLAYER STATS")
const PLAYER_MAX_HEALTH = 100.0
@export var player_health: float = PLAYER_MAX_HEALTH
@export var coolOnKill: float = 15.0
@export var grenadeCoolTime: float = 8.0 # cooldown time (s)
@export var walk_speed: float = 6.0
@export var crouch_speed: float = 3.0
@export var dash_speed: float = 22.5
@export var dashCoolTime: float = 1.5 # cooldown time (s)
@export var jump_speed: float = 7.0

@export_category("PLAYER MODIFIERS") # maybe an upgrade system in the future?
@export_range(1.0, 1.5, 0.1) var weapon_draw_mod: float = 1.0


# --- INSTANCES ---
var spear = load("res://Scenes/Weapons/Spear.tscn")
var instance_spear
var grenade = preload("res://Scenes/Weapons/Grenade.tscn")
var instance_grenade



# --- UI ---
@onready var hudAnim = $hudAnimation
@onready var crosshair = $HUD/crosshair
@onready var healthBar = $HUD/HealthBar
var healthbar_def_pos
var healthbar_def_color
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

# --- EFFECTS ---
@onready var hands = $shakeable_camera/Hands
var def_gun_pos: Vector3
@export_category("GUN SWAY")
@export var gun_sway_amount: float = 5.0
@export var gun_rot_amount: float = 0.01

# --- GAMEPLAY SETTINGS ---
@export_category("GAMEPLAY")
var autoOpenDoors: bool = true
var autoCloseDoors: bool = true

# --- SIGNALS ---
signal playerDead
signal restoreCool(coolOnKill)

func save():
	var data = {
		"level_scene": get_tree().current_scene.scene_file_path,
		"filename": get_scene_file_path(),
		"parent": get_parent().get_path(),
		"transform": global_transform,
		"player_health": player_health,
		"current_room": current_room
	}
	return data
	


func _ready() -> void:
	#platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
	
	screenEffect = get_tree().get_first_node_in_group("Effects")
	
	camAnim.play("breath")
	
	healthbar_def_pos = healthBar.position
	healthbar_def_color = healthBar.self_modulate
	
	weapons_set_up()
	
	SettingsManager.player = self
	SettingsManager.apply_settings()
	
	def_gun_pos = hands.position
	
	instance_grenade = grenade.instantiate()
	instance_grenade.queue_free()
	
	healthBar.max_value = PLAYER_MAX_HEALTH
	current_gun_R.draw(1.0)
	
	Engine.time_scale = DEBUG_engineTimeScale

func _input(event):
	if dead: return
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Throwable objects
	if Input.is_action_just_pressed("E"):
		if grabbedObject: leave_grabbed_object()
		
		else: 
			if playerRay.is_colliding():
				var collider = playerRay.get_collider()
				var distance = global_position.distance_to(collider.global_position) #Distance to interactionable object from the player
				
				#Object that can be grabbed
				if collider is RigidBody3D and distance < 3: grab_object(collider)
				
				#Other interactionable objects(doors currently)
				elif collider.owner:
					if collider.owner.has_method("getType"):
						var object = collider.owner
						match object.getType():
							"Door": door_interaction(collider, distance)
				
	
	# Weapon Switch
	handle_weapon_switch()
	
	
	if Input.is_action_just_pressed("Wheel"): throw_grenade()
	
	if Input.is_action_pressed("Space"):
		drillJump = false
		#vault()
	else: drillJump = true
	
	handle_camera_rotations(event)


func _process(delta: float) -> void: # adaptive fps
	gun_rot_amount = 0.6/(delta*14400)

func _physics_process(delta) -> void: # fixed 60 fps
	updateScreenEffect()
	
	#neg vals are for recharge delay i.e -5 is 0.5 sec rechare delay VLAD
	grenadeCool = clamp(grenadeCool + (100 * delta) / grenadeCoolTime, -10.0, 100.0)
	if !slide:
		dashCool = clamp(dashCool + (100 * delta) / dashCoolTime, -10.0, 100.0)
	
	fireDelay = clamp(fireDelay + (100 * delta), 0, 15.0)
	
	if !dead:
		rotation.y = lerp_angle(rotation.y, yaw, delta * 30.0) # left/right
		camera.rotation.x = lerp_angle(camera.rotation.x, -pitch, delta * 30.0)
	
	if !is_on_wall(): wallrun_timer.stop()
	
	check_player_feet()
	
	# ******* a mockup, dont bother shoving it into a function, will finish later with it's own model & scene
	if Input.is_action_just_pressed("SideUpMouse") and !dead:
		if playerRay.is_colliding():
			if playerRay.get_collider().is_in_group("Pull"):
				pullTarget = playerRay.get_collider()
			else: pullTarget = null
		else: pullTarget = null
	
	if Input.is_action_pressed("SideUpMouse") and pullTarget and !dead:
		var dir: Vector3 = (pullTarget.global_position - global_position).normalized()
		if (pullTarget.global_position - global_position).length() < 1.5:
			pullTarget = null
		if velocity.length() < 20:
			knockBack(dir, 40 * delta, false, 0.0)
	else: pullTarget = null
	# *******
	
	handle_grabbed_object(delta)
	
	var speed = crouch_speed if crouch else walk_speed
	SPEED = move_toward(SPEED, speed, delta * 15.0)
	
	# Get direction
	var currentInput = Input.get_vector("A", "D", "W", "S")
	if dead: currentInput = Vector3.ZERO
	direction = (transform.basis * Vector3(currentInput.x, 0, currentInput.y)).normalized()
	
	#if direction: $Feet.look_at($Feet.global_position + direction, Vector3.UP) #Avoids errors with look_at trying to look at the same target
	#if direction and is_on_floor() and $Feet/StairsMin.is_colliding() and !$Feet/StairsMax.is_colliding() and is_on_wall():
	#	velocity.y = 4
	
	# dash
	if Input.is_action_just_pressed("Shift"): handle_dash()
	
	#Basic movement
	if is_on_floor(): # Grounded speed
		if airborne:
			airborne = false
			vaulting = false
			camera.add_trauma(clamp(0.7 * landVel/10, 0.0, 5.0))
			landVel = 0.0
		
		# Jumping
		if Input.is_action_just_pressed("Space") and !dead:
			velocity.y += jump_speed * (0.75 if crouch else 1.0)
			$VaultBuffer.start()
		
		if dead: camera.rotation.x = lerp_angle(camera.rotation.x, 0.0, delta * 10.0)
		
		ground_movement(delta)
		
	
	elif is_on_wall() and $WallCheckUp.is_colliding() and $WallCheckDown.is_colliding(): wall_movement(delta)
	
	else: air_movement(delta) # Airborne speed
	
	
	if !dead:
		cam_gun_tilt_sway(currentInput.x, currentInput.y, delta)
		gun_bob(velocity.length(), currentInput, delta)
	
	handle_healthBar()
	handle_heatBars()
	
	handle_firing()
	
	check_player_feet()
	push_object()
	handle_grabbed_object(delta)
	handle_crouch(delta)
	move_and_slide()
	speed_lines()
	

# --- WEAPONS ---

func weapons_set_up():
	var weaponList = $shakeable_camera/Hands/RightHand.get_children() + $shakeable_camera/Hands/LeftHand.get_children()
	for child in weaponList:
		if "camera" in child: child.camera = $shakeable_camera
		if "playerRay" in child: child.playerRay = $shakeable_camera/PlayerRay
		if "playerRayEnd" in child: child.playerRayEnd = $shakeable_camera/PlayerRay/PlayerRayEnd
		
		if "knockBack" in child: child.knockBack.connect(knockBack)
		
		if "player" in child: child.player = self

func handle_firing():
	if Input.is_action_pressed("LeftMouse") and !drill.in_action and !dead:
		if !grabbedObject and fireDelay==15.0:
			match current_gun_R:
				destabilizer: current_gun_R.spinup(true)
				beggarsShotgun: current_gun_R.charge()
				devestator: current_gun_R.shoot()
		elif grabbedObject: throw_grabbed_object()
	else:
		match current_gun_R:
			destabilizer: current_gun_R.spinup(false)
	
	if Input.is_action_just_released("LeftMouse") and !drill.in_action and !dead:
		if !grabbedObject and fireDelay==15.0:
			match current_gun_R:
				beggarsShotgun: current_gun_R.shoot()
	
	if Input.is_action_just_pressed("RightMouse") and !drill.in_action and !dead:
		current_gun_L.shoot()
	
	if Input.is_action_just_pressed("F") and !dead:
		if drill.can_swing and !drill.in_action and !current_gun_L.in_action:
			current_gun_R.undraw(1.5, true)
			drill.show()
			await drill.punch(velocity.length() if velocity.length() >= 15.0 else 0.0)
			current_gun_R.draw(1.2)
			drill.hide()

func handle_weapon_switch():
	if Input.is_action_just_pressed("1"): switch_weapon(destabilizer)
	elif Input.is_action_just_pressed("2"): switch_weapon(beggarsShotgun)
	elif Input.is_action_just_pressed("3"): switch_weapon(devestator)

func switch_weapon(weapon):
	if current_gun_R != weapon and !drill.in_action:
		if current_gun_R.anim.is_playing(): await current_gun_R.anim.animation_finished
		await current_gun_R.undraw(1.0 * weapon_draw_mod, false)
		hideWeapons()
		current_gun_R = weapon
		current_gun_R.show()
		current_gun_R.draw(1.0 * weapon_draw_mod)

func hideWeapons(): #We will add here check for left/right side later I guess
	for i in $shakeable_camera/Hands/RightHand.get_children():
		if i is Node3D: i.visible = false		

# --- EFFECTS ---

func handle_camera_rotations(event):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			yaw-=event.relative.x * cam_speed
			pitch+=event.relative.y * cam_speed
			pitch = clamp(pitch, deg_to_rad(-90), deg_to_rad(90))
			mouse_input = event.relative

func cam_gun_tilt_sway(input_x, input_y, delta):
	if camera:
		camera.rotation.z = lerp(camera.rotation.z, -input_x * cam_rot_amount, delta * 5.0)
	if hands:
		hands.rotation.z = lerp(hands.rotation.z, -input_x * gun_rot_amount * 10, delta * 3.0)
		hands.rotation.x = lerp(hands.rotation.x, input_y * gun_rot_amount * 20, delta * 1.5)
		
	mouse_input = lerp(mouse_input, Vector2.ZERO, delta * 10.0)
	hands.rotation.x = clamp(lerp(hands.rotation.x, mouse_input.y * gun_rot_amount, delta * 15.0), deg_to_rad(-15), deg_to_rad(15))
	hands.rotation.y = clamp(lerp(hands.rotation.y, mouse_input.x * gun_rot_amount, delta * 15.0), deg_to_rad(-30), deg_to_rad(30))

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
				bob_y = clamp(-velocity.y * 0.1, -4.0, 4.0)
				bob_x = 0
			hands.position.y = lerp(hands.position.y, def_gun_pos.y + bob_y * bob_amount, delta * 10.0)
			hands.position.x = lerp(hands.position.x, def_gun_pos.x + bob_x * bob_amount, delta * 10.0)
		else:
			hands.position.y = lerp(hands.position.y, def_gun_pos.y, delta * 10.0)
			hands.position.x = lerp(hands.position.x, def_gun_pos.x, delta * 10.0)

func speed_lines():
	speedParticles.amount_ratio = (velocity.length() - 15.0) / 5.0 + 0.2
	speedParticles.look_at(global_position + velocity + Vector3(0.001, 0.0, 0.0)) # last bit is to prevent colinear warnings

func head_bob(delta):
	var vel = velocity.length()
	var bob_amount: float = 0.05 * clamp(vel/5, 0, 2)
	var bob_freq: float = 0.005
	var bob_y = sin(Time.get_ticks_msec() * 2 * bob_freq)
	camera.position.y = lerp(camera.position.y, camDefHeight + bob_y * bob_amount, delta * 10.0)

func updateScreenEffect(): #Function for current and future screen effects
	if screenEffect!=null: 
		var forward = -camera.global_transform.basis.z
		var horizontal_forward = Vector3(forward.x, 0, forward.z).normalized()
		var dot = forward.dot(horizontal_forward)
		var factor = clamp(dot, 0.0, 1.0)
		screenEffect.material.set("shader_parameter/look_angle_factor", factor)

# --- MOVEMENT ---

func ground_movement(delta):
	if direction:
		# Head bob
		if !slide: head_bob(delta)
			
		# Walk speed
		if !knocked:
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 12.5 * accel_mod)
			velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 12.5 * accel_mod)
		
	else: # No input speed
		if !knocked:
			velocity.x = lerp(velocity.x, 0.0, delta * 8.0 * accel_mod)
			velocity.z = lerp(velocity.z, 0.0, delta * 8.0 * accel_mod)

func wall_movement(delta):
	if wallrun_timer.is_stopped(): 
		wallrun_timer.start()
	
	var pull = -20 * ((wallrun_timer.wait_time - wallrun_timer.time_left) / wallrun_timer.wait_time)**2.5
	velocity.y = lerp(velocity.y, pull , delta * 4.0)
		
	if Input.is_action_just_pressed("Space") and !dead:
		velocity.y = 0.0
		knockBack(0.6 * get_wall_normal() + 0.4 * direction + 0.8 * Vector3.UP, jump_speed, false, 0.2)
		$VaultBuffer.start()
		
	if !knocked:
		var desired_speed: Vector2 = Vector2(direction.x - get_wall_normal().x, direction.z - get_wall_normal().z) * SPEED * 1.2
		velocity.x = lerp(velocity.x, desired_speed.x, delta * (4.0 if abs(desired_speed.x) > abs(velocity.x) * sign(desired_speed.x * velocity.x) else 0.3) * accel_mod)
		velocity.z = lerp(velocity.z, desired_speed.y, delta * (4.0 if abs(desired_speed.y) > abs(velocity.z) * sign(desired_speed.y * velocity.z) else 0.3) * accel_mod)

func air_movement(delta):
	airborne = true
	landVel = abs(velocity.y)
	
	var down_force: float = clamp(15.0 - (velocity.y if velocity.y <= 0.0 else 0.0), 0.0, 25.0)
	if dash and velocity.y < 0:
		down_force = 0.0
		velocity.y = 0.0
	velocity.y = clamp(velocity.y - delta * down_force, -80.0, 80.0)  # Gravity
	
	if !knocked:
		var desired_speed: Vector2 = Vector2(direction.x * SPEED, direction.z * SPEED)
		velocity.x = lerp(velocity.x, desired_speed.x, delta * (1.25 if abs(desired_speed.x) > abs(velocity.x) else 0.2) * accel_mod)
		velocity.z = lerp(velocity.z, desired_speed.y, delta * (1.25 if abs(desired_speed.y) > abs(velocity.z) else 0.2) * accel_mod)

func handle_dash():
	if dashCool == 100.0 and !crouch and !dead:
		dash = true
		dashCool = -10.0
		var dashDir: Vector3 = Vector3.ZERO
		if direction: dashDir = direction
		else:
			dashDir = -global_transform.basis.z.normalized()
			dashDir.y = 0.0
		knockBack(dashDir, dash_speed, false, 0.2)
		await get_tree().create_timer(0.2).timeout
		dash = false
		if !is_on_floor() or !slide:
			knockBack(-dashDir, 15 * Vector3(velocity.x, 0.0, velocity.z).length() / dash_speed, false, 0.0)

func handle_crouch(delta):
	if Input.is_action_pressed("Ctrl") and !dead: # crouch/slide
		crouch = true
		playerCollision.shape.height = lerp(playerCollision.shape.height, 1.0, delta * 15.0)
		$Feet.position.y = lerp($Feet.position.y, 0.5, delta * 15.0)
		if is_on_floor() and velocity.length() > crouch_speed + 0.1: # 0.1 is epsilon for numerical error
			slide = true
			floor_stop_on_slope = false
			accel_mod = 0.05
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
		playerCollision.shape.height = lerp(playerCollision.shape.height, 2.0, delta * 15.0)
		$Feet.position.y = lerp($Feet.position.y, 0.0, delta * 15.0)
		accel_mod = 1.0

#func vault():
#	if !is_on_floor() and !vaulting and $VaultBuffer.is_stopped() and vaultCheck.is_colliding():
#		var canVault = false
#		for i in range(vaultCheck.get_collision_count()):
#			if vaultCheck.get_collision_normal(i).y > 0.7: canVault = true
#		
#		if canVault:
#			print("ADA")
#			vaulting = true
#			velocity.y = jump_speed * 0.7

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

func knockBack(dir, force, slowOnGround, time):
	if slowOnGround and is_on_floor():
		force /= 2
	knocked = true
	velocity += dir * force
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
			if is_on_floor() and !knocked:
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

func throw_grabbed_object():
	if grabbedObject.can_let_go():
		grabbedObject.is_held = false
		grabbedObject.gravity_scale = 1
		grabbedObject.linear_damp = 0.0
		remove_collision_exception_with(grabbedObject)
		grabbedObject = null
		fireDelay = 0.0

func leave_grabbed_object():
	if grabbedObject.can_let_go():
		grabbedObject.is_held = false
		grabbedObject.gravity_scale = 1.0
		grabbedObject.linear_damp = 0.0
		remove_collision_exception_with(grabbedObject)
		grabbedObject = null

func grab_object(collider):
	grabbedObject = collider
	grabbedObject.is_held = true
	grabbedObject.gravity_scale = 0.0
	grabbedObject.linear_damp = 0.0
	add_collision_exception_with(grabbedObject)

func door_interaction(collider, distance):
	var object = collider.owner
	collider = collider as StaticBody3D
	var metadata = collider.get_meta("Dir")
	if object.getOpenStatus() < 0 and distance < 2: object.open(metadata)
	else: object.close(1.0)

# --- HEALTH AND DAMAGE ---
func checkLifeLine():
	if player_health <= 0 and dead == false:
		if !DEBUG_deathBypass:
			dead = true
			await get_tree().create_timer(0.3).timeout
			camAnim.speed_scale = 1.0
			camAnim.play("death")
			playerDead.emit()
			await current_gun_R.undraw(1.5, true)
			hideWeapons()
	else:
		camAnim.speed_scale = lerp(1.0, 2.5, 1 - player_health / PLAYER_MAX_HEALTH)

func enemy_killed():
	restoreCool.emit(coolOnKill)

func damage_taken(recieved_damage, isPlayer):
	if isPlayer: recieved_damage /= 3
	player_health -= recieved_damage
	camera.add_trauma(recieved_damage)
	checkLifeLine()

func heal(heal_amount):
	player_health = clamp(player_health + heal_amount, 0.0, PLAYER_MAX_HEALTH)
	checkLifeLine()

# --- UI ---
func handle_healthBar():
	var health_dif = abs(healthBar.value - player_health)
	healthBar.value = move_toward(healthBar.value, player_health, health_dif/5)
	
	if healthBar.value < PLAYER_MAX_HEALTH / 2 and !dead:
		var coef = PLAYER_MAX_HEALTH / (8*healthBar.value + PLAYER_MAX_HEALTH)
		healthBar.position = healthbar_def_pos + Vector2(randf_range(-3.0, 3.0),randf_range(-3.0, 3.0)) * coef
		healthBar.self_modulate = healthbar_def_color + Color(1.0, -0.5, 0.0, 0.0) * (70 * abs(cos(Time.get_ticks_msec() * 0.02 * coef)) / 255)
	else:
		healthBar.position = healthbar_def_pos
		healthBar.self_modulate = healthbar_def_color

func handle_heatBars():
	var heat_dif_R = abs(heatBar_R.value - current_gun_R.get_heat())
	heatBar_R.value = move_toward(heatBar_R.value, current_gun_R.get_heat(), heat_dif_R/5)
	var heat_dif_L = abs(heatBar_L.value - current_gun_L.get_heat())
	heatBar_L.value = move_toward(heatBar_L.value, current_gun_L.get_heat(), heat_dif_L/5)
	
	var grenade_dif = abs(grenadeBar.value - grenadeCool)
	grenadeBar.value = move_toward(grenadeBar.value, grenadeCool, grenade_dif/5)
	if grenadeCool == 100.0 and ceilf(grenadeBar.value * 10) / 10 < 100.0:
		hudAnim.play("grenadeBeep")
	
	var dash_dif = abs(dashBar.value - dashCool)
	dashBar.value = move_toward(dashBar.value, dashCool, dash_dif/3)
	if dashCool == 100.0 and ceilf(dashBar.value * 10) / 10 < 100.0:
		hudAnim.play("dashBeep")


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
