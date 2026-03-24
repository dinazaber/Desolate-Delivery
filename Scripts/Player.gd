extends CharacterBody3D

var cameraDistance = 15

const headFreq = 2.4
const headAmp = 0.08
var headTime = 0.0
@onready var camDefHeight = $PlayerCamera.position.y
@export var screenEffect: ColorRect

var deceleration = 0.3
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
@export var player_health = 100
@export var walk_speed = 4
@export var run_speed = 8
@export var dash_speed = 25
@export var jump_speed = 10
@export var slam_speed = -30

#gun stats
@export var smg_damage = 15
@export var quickDraw_damage = 70

@export var slam_damage = 40

#guns
@onready var smg_anim = $PlayerCamera/Weapon/AnimationPlayer
@onready var smg_ray = $PlayerCamera/Weapon/RayCast3D
@onready var quickDraw_anim = $PlayerCamera/OffHandShotgun/AnimationPlayer
@onready var quickDraw_ray = $PlayerCamera/OffHandShotgun/RayCast3D

@onready var slam_area = $GroundSlam

#UI
@onready var crosshair = $HUD/crosshair


func InteriorEnter(metaData: Variant) -> void:
	currentRoof = metaData.mesh
	currentRoof = currentRoof.surface_get_material(0)
	currentRoof.albedo_color.a = 0


func InteriorExit(body: Node3D) -> void:
	if body.name == "Player":
		if currentRoof!=null:
			currentRoof.albedo_color.a = 1


func DashTimerTimeOut() -> void:
	dash = false
	$SuperTimer.set("wait_time",0.5)
	$SuperTimer.start()


func SuperTimerTimeOut() -> void:
	if !canDash:
		canDash = true
		
func animFinished(anim_name: StringName) -> void:
	if "Attack" in anim_name:
		attack = false


func updateScreenEffect():
		var forward = -$PlayerCamera.global_transform.basis.z
		var horizontal_forward = Vector3(forward.x, 0, forward.z).normalized()
		var dot = forward.dot(horizontal_forward)
		var factor = clamp(dot, 0.0, 1.0)
		screenEffect.material.set("shader_parameter/look_angle_factor", factor)

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

	cameraDistance = clamp(cameraDistance,15, 45)
	
	rotation.y = lerp_angle(rotation.y, yaw, delta*20)#left/right
	$PlayerCamera.rotation.x = lerp_angle($PlayerCamera.rotation.x, -pitch, delta*20)
	
	
	if Input.is_action_pressed("LeftMouse"):
		shoot_smg()
	
	if Input.is_action_just_pressed("RightMouse"):
		shoot_offHandShotgun()
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
			
		if collider is RigidBody3D:
			var pushDir = -collision.get_normal()
			collider.apply_impulse(pushDir * 4, collision.get_position() - collider.global_position)

	
	if is_on_floor():
		if slam == true:
			slam = false
			slam_ground()
		
		if Input.is_action_just_pressed("Space"):
			velocity.y += jump_speed
			
	else:
		velocity.y -= 20 * delta # Gravity
		
		if Input.is_action_just_pressed("Ctrl"): # Groundslam
			slam = true
			velocity.y += slam_speed
	
	if Input.is_action_pressed("Shift"):
		
		speed = run_speed
	else:
		speed = walk_speed
	
	
	# Get direction
	currentInput = Input.get_vector("A", "D", "S", "W")

				
	var direction = (transform.basis * Vector3(currentInput.y, 0, currentInput.x)).normalized()
			
	#Basic movement & dash
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if Input.is_action_just_pressed("Ctrl") and canDash and is_on_floor():
			$DashTimer.start()
			dash = true
			canDash = false
		if dash:
			velocity = direction * dash_speed
			
		headTime += delta * velocity.length() * float(is_on_floor())
		var pos = Vector3.ZERO
		pos.y = camDefHeight + sin(headTime*headFreq) * headAmp
		$PlayerCamera.position.y = lerp($PlayerCamera.position.y, pos.y, 20*delta)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, deceleration)
		velocity.z = move_toward(velocity.z, 0, deceleration)
		speed=0
		$PlayerCamera.position.y = lerp($PlayerCamera.position.y, camDefHeight, 20*delta)
	
	move_and_slide()

func get_cam_forward_direction() -> Vector3:
	var look_dir = -$PlayerCamera.global_transform.basis.z.normalized()
	return look_dir

func knock_back(direction: Vector3, speed):
	velocity = speed * direction

func hit(recieved_damage):
	player_health -= recieved_damage
	checkLifeLine()

func shoot_smg():
	if !smg_anim.is_playing():
			smg_anim.play("Shoot")
			if smg_ray.is_colliding():
				#var pos = smg_ray.get_collision_point()
				#var normal = smg_ray.get_collision_normal()
				if smg_ray.get_collider().is_in_group("Enemy"):
					smg_ray.get_collider().hit(smg_damage, "player")

func shoot_offHandShotgun():
	if !quickDraw_anim.is_playing():
		quickDraw_anim.play("Draw")
		await get_tree().create_timer(0.25).timeout
		quickDraw_anim.play("Shoot")
		
		if !is_on_floor():
			var direction = get_cam_forward_direction()
			print(direction)
			knock_back(direction, -20)
		
		if quickDraw_ray.is_colliding():
			if quickDraw_ray.get_collider().is_in_group("Enemy"):
				quickDraw_ray.get_collider().hit(quickDraw_damage, "player")
		await get_tree().create_timer(0.4).timeout
		quickDraw_anim.play_backwards("Draw")

func slam_ground():
	if slam_area.has_overlapping_bodies():
		var bodies = slam_area.get_overlapping_bodies()
		for body in bodies:
			body.get_pounded(slam_damage)

func checkLifeLine():
	if player_health <= 0 and dead == false:
		print("u ded lol")
		dead = true
		#get_tree().quit()
