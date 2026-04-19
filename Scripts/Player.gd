extends CharacterBody3D

var cameraDistance = 15

const headFreq = 2.4
const headAmp = 0.04
var headTime = 0.0

# --- NODES ---
@onready var playerCollision = $PlayerCollision
@export var screenEffect: ColorRect
@onready var playerRay = $shakeable_camera/PlayerRay
var grabbedObject: RigidBody3D = null
@onready var slam_area = $GroundSlam



# --- WEAPONS ---
@onready var SMG = $shakeable_camera/Hands/RightHand/SMG
@onready var beggarsShotgun = $shakeable_camera/Hands/RightHand/BeggarsShotgun
@onready var steamer = $shakeable_camera/Hands/LeftHand/Steamer
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
var slam: bool = false
var airborne: bool = false
var dead: bool = false
var canShoot: bool = true

var isInInterior = false
var currentRoof = null

var yaw = 0.0
var pitch = 0.0
var mouse_input: Vector2
var grenadeCool: float = 100.0
var landVel: float = 0.0
var fireDelay = 10 # Delay between object throwing and shooting


# --- PLAYER STATS ---
@export var DEBUG_deathBypass: bool = false
const PLAYER_MAX_HEALTH = 100
@export var player_health: float = PLAYER_MAX_HEALTH
@export var coolOnKill: float = 15.0
@export var grenadeCoolTime: float = 10.0 # cooldown time
@export var walk_speed: float = 5
@export var crouch_speed: float = 2.5
@export var dash_speed: float = 15
@export var jump_speed: float = 10
@export var slam_speed: float = -30
@export var slam_damage = 40


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
@onready var heatBar_R = $HUD/HeatRight
@onready var heatBar_L = $HUD/HeatLeft

# --- CAMERA ---
@onready var camera = $shakeable_camera
@onready var camAnim = $cameraAnimation
@onready var camDefHeight = camera.position.y
@export var cam_speed: float = 0.005 #mouse sens
@export var cam_rot_amount: float = 0.03 #camera tilt

# --- Effects ---
@onready var hands = $shakeable_camera/Hands
var def_gun_pos: Vector3
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
	def_gun_pos = hands.position
	
	healthBar.max_value = PLAYER_MAX_HEALTH
	current_gun_R.draw()

func _input(event):
	if dead: return
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
	# Throwable objects
	if Input.is_action_just_pressed("E"):
		if grabbedObject: 
			grabbedObject.gravity_scale = 1
			remove_collision_exception_with(grabbedObject)
			grabbedObject = null
		else: 
			if playerRay.is_colliding():
				var collider = playerRay.get_collider()
				var distance = global_position.distance_to(collider.global_position)
				if collider is RigidBody3D and distance < 3:
					grabbedObject = collider
					grabbedObject.gravity_scale = 0
					add_collision_exception_with(grabbedObject)
		
	
	if Input.is_action_just_pressed("1"): # smg
		if current_gun_R != SMG:
			await current_gun_R.undraw()
			hideWeapons()
			current_gun_R = SMG
			current_gun_R.show()
			current_gun_R.draw()
	
	elif Input.is_action_just_pressed("2"): # beggars shotgun
		if current_gun_R != beggarsShotgun:
			await current_gun_R.undraw()
			hideWeapons()
			current_gun_R = beggarsShotgun
			current_gun_R.show()
			current_gun_R.draw()
	
	
	if Input.is_action_just_pressed("R"):
		throw_grenade()
		
			
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
	
	grenadeCool = clamp(grenadeCool + (100 * delta) / grenadeCoolTime, 0, 100.0)
	
	fireDelay = clamp(fireDelay + (100 * delta), 0, 10.0)
	
	if !dead:
		rotation.y = lerp_angle(rotation.y, yaw, delta * 30.0) # left/right
		camera.rotation.x = lerp_angle(camera.rotation.x, -pitch, delta * 30.0)
		
	
	if Input.is_action_pressed("LeftMouse") and !dead:
		if !grabbedObject and fireDelay==10:
			match current_gun_R:
				SMG: current_gun_R.shoot()
				beggarsShotgun: current_gun_R.charge()
		elif grabbedObject:
			var dir = -camera.global_basis.z
			grabbedObject.gravity_scale = 1
			grabbedObject.apply_central_impulse(dir * 100)
			remove_collision_exception_with(grabbedObject)
			grabbedObject = null
			fireDelay = 0
	
	if Input.is_action_just_released("LeftMouse") and !dead:
		match current_gun_R:
			beggarsShotgun: current_gun_R.shoot()
	
	
	if Input.is_action_just_pressed("RightMouse") and !dead:
		current_gun_L.shoot()
		
	
	if grabbedObject: # Grabbed Object
		var holdPos = $shakeable_camera/throwableSpawn
		var distance = grabbedObject.global_position.distance_to(holdPos.global_position)
		if distance > 1.5:
			grabbedObject.gravity_scale = 1
			grabbedObject = null
			return
		
		grabbedObject.global_position = holdPos.global_position
		grabbedObject.global_rotation = holdPos.global_rotation
	
	
	for i in get_slide_collision_count(): # Rigid bodies pushing
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
			
		if collider is RigidBody3D:
			var pushDir = -collision.get_normal()
			collider.apply_impulse(pushDir * 4, collision.get_position() - collider.global_position)
	
	
	if Input.is_action_pressed("Ctrl") and !dead: # crouch/slide
		crouch = true
		playerCollision.shape.height = lerp(playerCollision.shape.height, 1.0, delta * 15.0)
		if velocity.length() > crouch_speed + 0.1: # 0.1 is epsilon for numerical error
			slide = true
			floor_stop_on_slope = false
			accel_mod = 0.1
			if is_on_floor():
				var normal = get_floor_normal()
				normal.y = -normal.y
				velocity += normal * 0.3
		else:
			slide = false
			floor_stop_on_slope = true
			accel_mod = 1.0
	else:
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
	if dead:
		currentInput = Vector3.ZERO
	var direction = (transform.basis * Vector3(currentInput.x, 0, currentInput.y)).normalized()
	
	if direction and !knocked:
		velocity.x = move_toward(velocity.x, direction.x * SPEED, delta * 20.0 * accel_mod)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, delta * 20.0 * accel_mod)
	
	#Basic movement & dash
	if is_on_floor(): # grounded speed
		if slam == true:
			slam = false
			slam_ground()
		
		if airborne:
			airborne = false
			camera.add_trauma(clamp(0.7 * landVel/10, 0.0, 5.0))
			landVel = 0.0
		
		if Input.is_action_just_pressed("Space") and !dead:
			velocity.y += jump_speed
		
		if !dead:
		# without this line the camera does some goofy stuff when walking into an object. keep it.
			camera.position.y = lerp(camera.position.y, camDefHeight, delta * 10.0)
		else:
			camera.rotation.x = lerp_angle(camera.rotation.x, 0.0, delta * 10.0)
		
		if direction:
			if Input.is_action_just_pressed("Shift") and canDash and !crouch and !dead:
				SPEED = dash_speed
				velocity = direction * SPEED
				canDash = false
				$SuperTimer.set("wait_time",0.5)
				$SuperTimer.start()
			
			
			# head bob
			if !slide:
				headTime += delta * velocity.length() * float(is_on_floor())
				var pos = Vector3.ZERO
				pos.y = camera.position.y + sin(headTime*headFreq) * headAmp
				camera.position.y = lerp(camera.position.y, pos.y, 20 * delta)
		
		
		else: # no input speed
			headTime = 0.0
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 5.0 * accel_mod)
			velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 5.0 * accel_mod)
			
	else: # airborne speed
		airborne = true
		landVel = abs(velocity.y)
		velocity.y -= 20 * delta # Gravity
		
		#if Input.is_action_just_pressed("Ctrl") and !$GroundSlamCheck.is_colliding(): # Groundslam
		#	slam = true
		#	velocity.y += slam_speed
		
		
		velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 0.5)
		velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 0.5)
	
	if !dead:
		cam_gun_tilt_sway(currentInput.x,currentInput.y, delta)
		gun_bob(velocity.length(), currentInput, delta)
	
	handle_healthBar()
	handle_heatBars()
	move_and_slide()



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
			
			

func hideWeapons(): #We will add here check for left/right side later I guess
	for i in $shakeable_camera/Hands/RightHand.get_children():
		if i is Node3D: i.hide()

func hit(recieved_damage, type):
	if type == "player":
		recieved_damage /= 5
	player_health -= recieved_damage
	camera.add_trauma(recieved_damage/20)
	checkLifeLine()

func throw_grenade():
	if grenadeCool == 100.0:
		instance_grenade = grenade.instantiate()
		instance_grenade.position = $shakeable_camera/throwableSpawn.global_position
		var throw_dir = -camera.global_transform.basis.z.normalized()
		var forward_force = 10
		var upward_force = 3.5
		instance_grenade.apply_central_impulse((throw_dir * forward_force) + Vector3(0, upward_force, 0) + velocity)
		get_parent().add_child(instance_grenade)
		grenadeCool = 0

#func shoot_speargun(): ## UNUSED
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

func slam_ground():
	if slam_area.has_overlapping_bodies():
		var bodies = slam_area.get_overlapping_bodies()
		for body in bodies:
			body.get_pounded(slam_damage)

func knockBack(direction, force, time):
	if is_on_floor():
		force /= 2
	knocked = true
	velocity += direction * force
	await get_tree().create_timer(time).timeout
	knocked = false

func checkLifeLine():
	print(player_health)
	if player_health <= 0 and dead == false:
		print("u ded lol")
		if !DEBUG_deathBypass:
			dead = true
			current_gun_R.undraw()
			await get_tree().create_timer(0.3).timeout
			camAnim.play("death")
			playerDead.emit()

func enemy_killed():
	restoreCool.emit(coolOnKill)
	

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
