extends CharacterBody3D

var cameraDistance = 15

const headFreq = 2.4
const headAmp = 0.08
var headTime = 0.0

@onready var camera = $shakeable_camera
@onready var camDefHeight = camera.position.y
@onready var healthBar = $HUD/HealthBar
@export var screenEffect: ColorRect
@export var sun: DirectionalLight3D

@onready var rightWeapon_smg: MeshInstance3D = $shakeable_camera/RightHand/SMG
@onready var rightWeapon_beggarsShotgun: Marker3D = $shakeable_camera/RightHand/BeggarsShotgun
@onready var rightWeapon_speargun: MeshInstance3D = $shakeable_camera/RightHand/SpeargunPlaceholder
@onready var leftWeapon: MeshInstance3D = $shakeable_camera/LeftHand/Shotty


var speed: float = 0
var accel_mod: float = 1.0 #acceleration modifier
var dash: bool = false
var canDash: bool = true
var knocked: bool = false
var crouch: bool = false
var slam: bool = false
var airborne: bool = false
var dead: bool = false
var canShoot: bool = true

var isInInterior = false
var currentRoof = null

var yaw = 0.0
var pitch = 0.0

var attack = false

var currentInput = Vector2()

#player stats
const PLAYER_MAX_HEALTH = 100
@export var player_health: float = PLAYER_MAX_HEALTH
@export var walk_speed: float = 5
@export var dash_speed: float = 15
@export var jump_speed: float = 10
@export var slam_speed: float = -30

#player boxes
@onready var player_stand = $PlayerCollisionStand
@onready var player_crouch = $PlayerCollisionCrouch

#gun stats
@export var smg_damage = 15
@export var smg_recoil = 0.3

@export var beggarsShotgun_recoil = 1.0

@export var quickDraw_damage = 70
@export var quickDraw_recoil = 1.5

@export var slam_damage = 40


#loading objects
var spear = load("res://Scenes/Spear.tscn")
var instance_spear
var grenade = load("res://Scenes/Grenade.tscn")
var instance_grenade


@onready var playerRay = $shakeable_camera/PlayerRay
@onready var playerRay_end = $shakeable_camera/PlayerRayEnd

var current_gun = "smg"
var beggarsMag = 0
@onready var rightWeaponAnim = $shakeable_camera/RightHand/AnimationPlayer
@onready var spearSpawn = $shakeable_camera/RightHand/SpeargunPlaceholder/Barrel
@onready var leftWeaponAnim = $shakeable_camera/LeftHand/AnimationPlayer

@onready var slam_area = $GroundSlam


#UI
@onready var crosshair = $HUD/crosshair


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
	$shakeable_camera/Camera3D.make_current()
	healthBar.max_value = PLAYER_MAX_HEALTH
	
	if sun!=null: 
		var sunDir = sun.global_transform.basis.z.normalized()
		rightWeapon_smg.set_instance_shader_parameter("sun_direction", sunDir)

func _input(event):
	#if event is InputEventMouseButton:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#elif event.is_action_pressed("cancel"):
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			yaw-=event.relative.x * 0.005
			pitch+=event.relative.y * 0.005
			pitch = clamp(pitch, deg_to_rad(-90), deg_to_rad(90))
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				cameraDistance+=1.5
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				cameraDistance-=1.5
				


func _physics_process(delta):
	
	if screenEffect!=null: updateScreenEffect()

	#cameraDistance = clamp(cameraDistance,15, 45)
	
	rotation.y = lerp_angle(rotation.y, yaw, delta*20) # left/right
	camera.rotation.x = lerp_angle(camera.rotation.x, -pitch, delta*20)
	
	
	if Input.is_action_just_pressed("1"): # smg
		canShoot = false
		rightWeapon_smg.visible = true
		rightWeapon_beggarsShotgun.visible = false
		rightWeapon_speargun.visible = false
		current_gun = "smg"
		canShoot = true
	
	elif Input.is_action_just_pressed("2"): # beggars shotgun
		canShoot = false
		rightWeapon_smg.visible = false
		rightWeapon_beggarsShotgun.visible = true
		rightWeapon_speargun.visible = false
		current_gun = "beggars shotgun"
		canShoot = true
	
	#elif Input.is_action_just_pressed("3"): # speargun
	#	canShoot = false
	#	rightWeapon_smg.visible = false
	#	rightWeapon_beggarsShotgun.visible = false
	#	rightWeapon_speargun.visible = true
	#	current_gun = "speargun"
	#	canShoot = true
	
	
	if Input.is_action_pressed("LeftMouse"): # shooting
		if current_gun == "smg":
			shoot_smg()
		elif current_gun == "speargun":
			shoot_speargun()
	
	if current_gun == "beggars shotgun": # shooting the beggars spesificaly
		if canShoot:
			if Input.is_action_pressed("LeftMouse"):
				if beggarsMag < 4 and !rightWeaponAnim.is_playing():
					rightWeaponAnim.play("LoadBeggarsShotgun")
					await get_tree().create_timer(0.35).timeout
					beggarsMag += 1
			elif beggarsMag > 1 and !rightWeaponAnim.is_playing():
				rightWeaponAnim.play("ShootBeggarsShotgun_consecutive")
				camera.add_trauma(beggarsShotgun_recoil)
				await get_tree().create_timer(0.2).timeout
				beggarsMag -= 1
				shoot_beggarsShotgun()
			elif beggarsMag == 1 and !rightWeaponAnim.is_playing():
				rightWeaponAnim.play("ShootBeggarsShotgun_last")
				camera.add_trauma(beggarsShotgun_recoil)
				await get_tree().create_timer(0.4).timeout
				beggarsMag -= 1
				shoot_beggarsShotgun()
	
	
	if Input.is_action_just_pressed("RightMouse"):
		shoot_offHandShotgun()
	
	if Input.is_action_just_pressed("R"):
		throw_grenade()
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
			
		if collider is RigidBody3D:
			var pushDir = -collision.get_normal()
			collider.apply_impulse(pushDir * 4, collision.get_position() - collider.global_position)
	
	
	if Input.is_action_pressed("Ctrl"): # crouch/slide
		crouch = true
		player_crouch.visible = true
		player_stand.visible = false
		camera.position.y = lerp(camera.position.y, camDefHeight - 0.5, 20 * delta)
		accel_mod = 0.08
	else:
		crouch = false
		player_crouch.visible = false
		player_stand.visible = true
		camera.position.y = lerp(camera.position.y, camDefHeight, 20 * delta)
		accel_mod = 1.0
	
	speed = move_toward(speed, walk_speed, delta * 15.0)
	
	
	# Get direction
	currentInput = Input.get_vector("A", "D", "S", "W")
	
	
	var direction = (transform.basis * Vector3(currentInput.y, 0, currentInput.x)).normalized()
	
	if direction and !knocked:
		velocity.x = move_toward(velocity.x, direction.x * speed, delta * 20.0 * accel_mod)
		velocity.z = move_toward(velocity.z, direction.z * speed, delta * 20.0 * accel_mod)
	
	#Basic movement & dash
	if is_on_floor(): # grounded speed
		if slam == true:
			slam = false
			slam_ground()
		
		if airborne:
			airborne = false
			camera.add_trauma(0.7)
		
		if Input.is_action_just_pressed("Space"):
			velocity.y += jump_speed
		
		
		if direction:
			if Input.is_action_just_pressed("Shift") and canDash and !crouch:
				if canDash:
					velocity = direction * dash_speed
					canDash = false
					$SuperTimer.set("wait_time",0.5)
					$SuperTimer.start()
			
			
			# head bob
			headTime += delta * velocity.length() * float(is_on_floor())
			var pos = Vector3.ZERO
			pos.y = camera.position.y + sin(headTime*headFreq) * headAmp
			camera.position.y = lerp(camera.position.y, pos.y, 20 * delta)
		
		else: # no input speed
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 5.0 * accel_mod)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 5.0 * accel_mod)
			
	else: # airborne speed
		airborne = true
		velocity.y -= 20 * delta # Gravity
		
		if Input.is_action_just_pressed("Ctrl") and !$GroundSlamCheck.is_colliding(): # Groundslam
			slam = true
			velocity.y += slam_speed
		
		
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 0.5)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 0.5)
	
	handle_healthBar()
	move_and_slide()



func hit(recieved_damage, type):
	if type == "player":
		recieved_damage /= 5
	player_health -= recieved_damage
	camera.add_trauma(recieved_damage/20)
	checkLifeLine()

func throw_grenade():
	instance_grenade = grenade.instantiate()
	instance_grenade.position = $shakeable_camera/throwableSpawn.global_position
	var throw_dir = -camera.global_transform.basis.z.normalized()
	var forward_force = 10
	var upward_force = 3.5
	instance_grenade.apply_central_impulse((throw_dir * forward_force) + Vector3(0, upward_force, 0) + velocity)
	get_parent().add_child(instance_grenade)

func shoot_smg():
	if !rightWeaponAnim.is_playing() and canShoot:
		rightWeaponAnim.play("ShootSMG")
		camera.add_trauma(smg_recoil)
		if playerRay.is_colliding():
			if playerRay.get_collider().is_in_group("Enemy"):
				playerRay.get_collider().hit(smg_damage, "player")
			if playerRay.get_collider().is_in_group("ShotReactable"):
				playerRay.get_collider().shot()
			

func shoot_beggarsShotgun():
	pass

func shoot_speargun(): ## UNUSED
	if !rightWeaponAnim.is_playing() and canShoot:
		rightWeaponAnim.play("ShootSpeargun")
		instance_spear = spear.instantiate()
		instance_spear.position = spearSpawn.global_position
		instance_spear.transform.basis = spearSpawn.global_transform.basis
		get_parent().add_child(instance_spear)
		if playerRay.is_colliding():
			instance_spear.set_velocity(playerRay.get_collision_point())
		else:
			instance_spear.set_velocity(playerRay_end.global_position)

func shoot_offHandShotgun():
	if !leftWeaponAnim.is_playing():
		leftWeaponAnim.play("DrawShotgun")
		await get_tree().create_timer(0.25).timeout
		leftWeaponAnim.play("ShootShotgun")
		camera.add_trauma(quickDraw_recoil)
		
		if !is_on_floor():
			var direction = camera.global_transform.basis.z.normalized()
			knockBack(direction, 10, 0.2)
		
		if playerRay.is_colliding():
			if playerRay.get_collider().is_in_group("Enemy"):
				playerRay.get_collider().hit(quickDraw_damage, "player")
			if playerRay.get_collider().is_in_group("ShotReactable"):
					print("genade shot")
					playerRay.get_collider().shot()
		
		await get_tree().create_timer(0.4).timeout
		leftWeaponAnim.play_backwards("DrawShotgun")

func slam_ground():
	if slam_area.has_overlapping_bodies():
		var bodies = slam_area.get_overlapping_bodies()
		for body in bodies:
			body.get_pounded(slam_damage)

func knockBack(direction, force, time): # dont delete it again, VLAD
	knocked = true
	velocity += direction * force
	await get_tree().create_timer(time).timeout
	knocked = false

func checkLifeLine():
	print(player_health)
	if player_health <= 0 and dead == false:
		print("u ded lol")
		dead = true
		#get_tree().quit()

func handle_healthBar():
	var health_dif = healthBar.value - player_health
	healthBar.value = move_toward(healthBar.value, player_health, health_dif/5)
