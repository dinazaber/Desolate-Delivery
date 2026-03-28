extends CharacterBody3D

var cameraDistance = 15

const headFreq = 2.4
const headAmp = 0.08
var headTime = 0.0
@onready var camDefHeight = $PlayerCamera.position.y
@onready var healthBar = $HUD/HealthBar
@export var screenEffect: ColorRect
@export var sun: DirectionalLight3D
@onready var rightWeapon: MeshInstance3D = $PlayerCamera/RightHand/SMG
@onready var leftWeapon: MeshInstance3D = $PlayerCamera/LeftHand/Shotty

var speed = 0
var dash: bool = false
var canDash: bool = true
var slam: bool = false
var dead: bool = false

var isInInterior = false
var currentRoof = null

var yaw = 0.0
var pitch = 0.0

var attack = false

var currentInput = Vector2()

#player stats
const PLAYER_MAX_HEALTH = 100
@export var player_health = PLAYER_MAX_HEALTH
@export var walk_speed = 4
@export var run_speed = 8
@export var dash_speed = 25
@export var jump_speed = 10
@export var slam_speed = -30


#gun stats
@export var smg_damage = 15
@export var quickDraw_damage = 70

@export var slam_damage = 40


#loading objects
var bullet_trail = load("res://Scenes/BulletTrail.tscn")
var instance_bullet
var grenade = load("res://Scenes/Grenade.tscn")
var instance_grenade


@onready var playerRay = $PlayerCamera/PlayerRay
#@onready var eyes_end = $PlayerCamera/RayEnd


@onready var rightWeaponAnim = $PlayerCamera/RightHand/AnimationPlayer
@onready var leftWeaponAnim = $PlayerCamera/LeftHand/AnimationPlayer


@onready var slam_area = $GroundSlam


#UI
@onready var crosshair = $HUD/crosshair



func SuperTimerTimeOut() -> void:
	if !canDash:
		canDash = true
		


func updateScreenEffect(): #Function for current and future screen effects
	var forward = -$PlayerCamera.global_transform.basis.z
	var horizontal_forward = Vector3(forward.x, 0, forward.z).normalized()
	var dot = forward.dot(horizontal_forward)
	var factor = clamp(dot, 0.0, 1.0)
	screenEffect.material.set("shader_parameter/look_angle_factor", factor)

func _ready() -> void:
	healthBar.max_value = PLAYER_MAX_HEALTH
	
	if sun!=null: 
		var sunDir = sun.global_transform.basis.z.normalized()
		rightWeapon.set_instance_shader_parameter("sun_direction", sunDir)
		print(sunDir)

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
	$PlayerCamera.rotation.x = lerp_angle($PlayerCamera.rotation.x, -pitch, delta*20)
	
	
	if Input.is_action_pressed("LeftMouse"):
		shoot_smg()
	
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

	
	if Input.is_action_pressed("Shift"):
		
		speed = move_toward(speed, run_speed, delta * 15.0)
	else:
		speed = move_toward(speed, walk_speed, delta * 15.0)
	
	
	# Get direction
	currentInput = Input.get_vector("A", "D", "S", "W")
	
	
	var direction = (transform.basis * Vector3(currentInput.y, 0, currentInput.x)).normalized()
			
	#Basic movement & dash
	if is_on_floor(): # grounded speed
		if slam == true:
			slam = false
			slam_ground()
		
		if Input.is_action_just_pressed("Space"):
			velocity.y += jump_speed
		
		
		if direction:
			velocity.x = move_toward(velocity.x, direction.x * speed, delta * 20.0)
			velocity.z = move_toward(velocity.z, direction.z * speed, delta * 20.0)
			if Input.is_action_just_pressed("Alt") and canDash:
				if canDash:
					velocity = direction * dash_speed
					canDash = false
					$SuperTimer.set("wait_time",0.5)
					$SuperTimer.start()

			
			# head bob
			headTime += delta * velocity.length() * float(is_on_floor())
			var pos = Vector3.ZERO
			pos.y = camDefHeight + sin(headTime*headFreq) * headAmp
			$PlayerCamera.position.y = lerp($PlayerCamera.position.y, pos.y, 20 * delta)
		
		else: # no input speed
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 5.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 5.0)
			
	else: # airborne speed
		velocity.y -= 20 * delta # Gravity
		
		if Input.is_action_just_pressed("Ctrl"): # Groundslam
			slam = true
			velocity.y += slam_speed
		
		
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 1.5)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 1.5)
	
	#handle_healthBar()
	move_and_slide()



func hit(recieved_damage, _type):
	handle_healthBar()
	player_health -= recieved_damage
	checkLifeLine()

func throw_grenade():
	instance_grenade = grenade.instantiate()
	instance_grenade.position = $PlayerCamera/throwableSpawn.global_position
	var throw_dir = -$PlayerCamera.global_transform.basis.z.normalized()
	var forward_force = 10
	var upward_force = 3.5
	instance_grenade.apply_central_impulse((throw_dir * forward_force) + Vector3(0, upward_force, 0) + velocity)
	get_parent().add_child(instance_grenade)

func shoot_smg():
	if !rightWeaponAnim.is_playing():
		rightWeaponAnim.play("ShootSMG")
		if playerRay.is_colliding():
			if playerRay.get_collider().is_in_group("Enemy"):
				playerRay.get_collider().hit(smg_damage, "player")
			if playerRay.get_collider().is_in_group("ShotReactable"):
				playerRay.get_collider().shot()
			

func shoot_offHandShotgun():
	if !leftWeaponAnim.is_playing():
		leftWeaponAnim.play("DrawShotgun")
		await get_tree().create_timer(0.25).timeout
		leftWeaponAnim.play("ShootShotgun")
		
		if !is_on_floor():
			var direction = $PlayerCamera.global_transform.basis.z.normalized()
			velocity = 20 * direction
		
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

func checkLifeLine():
	print(player_health)
	if player_health <= 0 and dead == false:
		print("u ded lol")
		dead = true
		#get_tree().quit()

func handle_healthBar():
	var health_dif = healthBar.value - player_health
	healthBar.value = move_toward(healthBar.value, player_health, health_dif/5)
