extends CharacterBody3D

var cameraDistance = 15

const headFreq = 2.4
const headAmp = 0.08
var headTime = 0.0
@onready var camDefHeight = $PlayerCamera.position.y
@export var screenEffect: ColorRect

var speed = 0
var dash = false
var canDash = true
var dead = false

var isInInterior = false
var currentRoof = null

var yaw = 0.0
var pitch = 0.0

var attack = false

var currentInput = Vector2()

#player stats
@export var player_health = 100

#gun stats
@export var smg_damage = 15

#guns
@onready var smg_anim = $PlayerCamera/Weapon/AnimationPlayer
@onready var smg_ray = $PlayerCamera/Weapon/RayCast3D

#UI
@onready var crosshair = $HUD/crosshair



func _ready() -> void:
	crosshair.position.x = get_viewport().size.x / 2 - 32
	crosshair.position.y = get_viewport().size.y / 2 - 32


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
	
	if not is_on_floor():
		velocity.y -= 27 * delta #gravity
		
		
			
	if Input.is_action_pressed("LeftMouse"):
		shoot_smg()
	
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
			
		if collider is RigidBody3D:
			var pushDir = -collision.get_normal()
			collider.apply_impulse(pushDir * 4, collision.get_position() - collider.global_position)

	
	if is_on_floor():
		
		if Input.is_action_just_pressed("Space"):
			velocity.y = 10 #jumping
			
			
	if Input.is_action_pressed("Shift"):
		speed = 8
	
	else:
		speed = 4
		
		# Get direction
	currentInput = Input.get_vector("A", "D", "S", "W")

				
	var direction = (transform.basis * Vector3(currentInput.y, 0, currentInput.x)).normalized()
			
	#Basic movement & dash
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if Input.is_action_just_pressed("Alt") and canDash and is_on_floor():
			$DashTimer.start()
			dash = true
			canDash = false
		if dash:
			velocity = direction*15
			
		headTime += delta * velocity.length() * float(is_on_floor())
		var pos = Vector3.ZERO
		pos.y = camDefHeight + sin(headTime*headFreq) * headAmp
		$PlayerCamera.position.y = lerp($PlayerCamera.position.y, pos.y, 20*delta)
	else:		
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		speed=0
		$PlayerCamera.position.y = lerp($PlayerCamera.position.y, camDefHeight, 20*delta)
	
	move_and_slide()

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

func checkLifeLine():
	if player_health <= 0 and dead == false:
		print("u ded lol")
		dead = true
		#get_tree().quit()
