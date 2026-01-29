extends CharacterBody3D

var cameraDistance = 15

var speed = 0
var dash = false
var canDash = true

var isInInterior = false
var currentRoof = null

var yaw = 0.0
var pitch = 0.0

var attack = false

var currentInput = Vector2()

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
		
	
	cameraDistance = clamp(cameraDistance,15, 45)
	
	rotation.y = lerp_angle(rotation.y, yaw, delta*25)#left/right
	
	$PlayerCamera.position = $PlayerCamera.position.lerp(Vector3(-cameraDistance/2, sqrt((cameraDistance)**2-(cameraDistance/2)**2), 0), delta*10)
	
	if not is_on_floor():
		$Human/AnimationTree["parameters/Main/playback"].travel("InAir")
		velocity.y -= 27 * delta #gravity
		
		
			
	if Input.is_action_just_pressed("LeftMouse") and !attack:
		$Human/AnimationTree.set("parameters/OneShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		$Human/AnimationTree["parameters/Actions/playback"].travel("SwordAttack")
		attack = true
	
	if is_on_floor():
		
		if Input.is_action_just_pressed("Space"):
			velocity.y = 10 #jumping
			
			
		if Input.is_action_pressed("Shift"):
			speed = 8
			$Human/AnimationTree["parameters/Main/playback"].travel("Sprint")
	
		else:
			speed = 4
			$Human/AnimationTree["parameters/Main/playback"].travel("Walk")
		
		# Get direction
		currentInput = Input.get_vector("A", "D", "S", "W")
		# Player's rotation based on key input
		if currentInput.y:
			$Human.rotation.y = deg_to_rad(-90*(currentInput.y-1))
		elif currentInput.x:
			$Human.rotation.y = deg_to_rad(-90*currentInput.x)
		if currentInput.x and currentInput.y:
			if currentInput.y<0:
				$Human.rotation.y = deg_to_rad(180+45*currentInput.x)
			elif currentInput.y>0:
				$Human.rotation.y = deg_to_rad(0-45*currentInput.x)
				
		var direction = (transform.basis * Vector3(currentInput.y, 0, currentInput.x)).normalized()
			
		#Basic movement & dash
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			if Input.is_action_just_pressed("Alt") and canDash:
				$DashTimer.start()
				dash = true
				canDash = false
			if dash:
				$Human/AnimationTree["parameters/Main/playback"].travel("Dash")
				velocity = direction*10
		else:		
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			$Human/AnimationTree["parameters/Main/playback"].travel("Idle")
			speed=0
			
	move_and_slide()
