extends Node3D

#gun stats
@export var damage: float = 8.0
@export var recoil: float = 0.7 # degree rotation
@export var spread: Vector2 = Vector2(2.5, 5.0) # max deg rotation for 100% destabilization
@export var accuracyPerShot: float = 0.08
@export var accuracyExponent: float = 2.5
@export var heatPerShot: float = 2.75
@export var coolDown: float = 6.0 # time (s) it takes to go from 100 to 0 heat
@export var destabilize: float = 2.0 # time (s) it takes to go from min to max accuracy
@export var pellets: int = 1 # number of pellets
@export var bullet_speed: float = 85.0 # Speed of particles

var camera: Area3D
var playerRay: RayCast3D
var playerRayEnd: Marker3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var heatBuffer = $HeatBuffer

@onready var barrel = $Skeleton3D/Barrel
@onready var tracer = $Skeleton3D/tracer
@onready var ray = $Skeleton3D/Barrel/RayCast3D
@onready var crosshair = $Crosshair

var can_cool: bool = true
var heat: float = 0.0
var accuracy_mod: float = 0.0
var spin_amount: float = 0.0

func _ready() -> void:
	var material = tracer.process_material as ShaderMaterial # Get particle material
	material.set_shader_parameter("speed", bullet_speed) # Pellet speed
	tracer.amount = pellets # Set amount of pellets

func draw(playSpeed):
	anim.play("draw", -1, playSpeed)
	#$Crosshair.visible = true
	await anim.animation_finished

func undraw(playSpeed, asap):
	if anim.is_playing():
		if asap: anim.speed_scale = 3.0
		await anim.animation_finished
		anim.speed_scale = 1.0
	anim.play("undraw", -1, playSpeed)
	await anim.animation_finished
	#$Crosshair.visible = false
	spin_amount = 0.0

func spinup(up):
	if !anim.is_playing():
		var can_spinup: bool = up and heat < 100 - heatPerShot
		spin_amount = clamp(spin_amount + (1.0 if can_spinup else -0.2) * 80, 0.0, 1000.0)
	if spin_amount >= 1000.0: shoot(up)

func shoot(got_input):
	if got_input and (!anim.is_playing() or is_fireRate()) and heat < 100 - heatPerShot:
		$Skeleton3D/tracer/Sprite.look_at(camera.global_position, Vector3.UP)
		$Skeleton3D/tracer/Sprite.rotation.z = randf_range(-PI, PI)
		
		anim.stop()
		anim.play("shoot")
		
		var points = PackedVector3Array()
		points.resize(pellets)
		
		accuracy_mod = clamp(accuracy_mod + accuracyPerShot, 0.1, 1.0)
		
		var dist
		if playerRay.is_colliding():
			dist = ray.global_position.distance_to(playerRay.get_collision_point())
			if dist < 0.7:
				barrel.look_at(playerRayEnd.global_position)
			else:
				barrel.look_at(playerRay.get_collision_point())
		else:
			barrel.look_at(playerRayEnd.global_position)
		
		for i in range(pellets):
			ray.rotation.y = deg_to_rad(randf_range(-spread.y, spread.y) * accuracy_mod**accuracyExponent)
			ray.rotation.z = deg_to_rad(randf_range(0.0, 360.0))
			ray.rotation.x = deg_to_rad(randf_range(0.0, spread.x))
			
			ray.force_raycast_update()
		
			if ray.is_colliding(): # shoot
				var hit_pos = ray.get_collision_point()
				#await spawn_debug_cube(hit_pos) # Cube spawn, will be replaced by decal later | Causes freezes in large rooms!!!
				points[i] = hit_pos # Use collsion point as particle's target point
				var collider = ray.get_collider()
				if collider.is_in_group("Enemy"):
					if collider.has_method("hit"):
						collider.hit(damage, true, "bullet", ray.get_collision_point())
				if collider.is_in_group("ShotReactable"):
					collider.shot()
			
			else: points[i] = $Skeleton3D/Barrel/RayCast3D/Marker3D.global_position # Take end of weapon ray as particle's target point
		
		var material = tracer.process_material as ShaderMaterial
		material.set_shader_parameter("hit_points", points) #Updating target points
		material.set_shader_parameter("gun_barrel_pos", tracer.global_position) #Setting starting point
		
		camera.add_recoil(recoil)
		tracer.restart()
		tracer.emitting = true
		heatBuffer.start()
		can_cool = false
		heat = clamp(heat + heatPerShot, 0.0, 100.0)

func is_fireRate() -> bool:
	if anim.current_animation != "shoot": return false
	if anim.current_animation_position < 0.05: return false
	return true

func get_heat() -> float:
	return heat

func _on_restore_cool(coolOnKill: float) -> void:
	heat -= coolOnKill

func _physics_process(delta: float) -> void:
	if can_cool:
		heat = clamp(heat - (100 * delta) / coolDown, 0.0, 100.0)
		accuracy_mod = clamp(accuracy_mod - delta / destabilize, 0.1, 1.0)
	
	#if anim.is_playing() and anim.current_animation == "shoot":
		#await get_tree().create_timer(0.05 / anim.speed_scale).timeout
		#anim.stop()
	
	update_crosshair()

func _process(delta: float) -> void:
	$Skeleton3D/BatteryB.rotation_degrees.y -= spin_amount * delta
	$Skeleton3D/BatteryF.rotation_degrees.y += spin_amount * delta

func _on_heat_buffer_timeout() -> void:
	can_cool = true


# --- crosshair ---
func update_crosshair():
	var spin_mod = (1000 - spin_amount) / 1000
	var spinner_rot_mod = 1.5 * spin_mod - 0.25 - 2 * (spin_mod - 0.5) ** 3
	var spinner_pos_mod = (abs(0.5 - spinner_rot_mod) * 2) ** 4
	$Crosshair/base/spinnerBase.rotation = PI * spinner_rot_mod
	
	$Crosshair/base/handL.position.x = move_toward($Crosshair/base/handL.position.x, -accuracy_mod**accuracyExponent * 40, 2.0)
	$Crosshair/base/spinnerBase/spinnerL.position.x = $Crosshair/base/handL.position.x * spinner_pos_mod
	
	$Crosshair/base/handR.position.x = move_toward($Crosshair/base/handR.position.x, accuracy_mod**accuracyExponent * 40, 2.0)
	$Crosshair/base/spinnerBase/spinnerR.position.x = $Crosshair/base/handR.position.x * spinner_pos_mod


# --- SPREADAING DEBUG FUNCTION ---
func spawn_debug_cube(pos: Vector3):
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	
	var particle_collision_instance: GPUParticlesCollisionSphere3D = GPUParticlesCollisionSphere3D.new()
	
	# Set a small size for the cube (e.g., 10cm)
	box_mesh.size = Vector3(0.1, 0.1, 0.1)
	mesh_instance.mesh = box_mesh
	
	particle_collision_instance.radius = 0.3
	
	# Create a simple red material to make it pop
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0) # Red
	mesh_instance.material_override = material
	
	# Add to the scene and position it
	get_tree().root.add_child(mesh_instance)
	mesh_instance.global_position = pos
	
	get_tree().root.add_child(particle_collision_instance)
	particle_collision_instance.global_position = pos
	
	# Auto-delete after 2 seconds to keep performance high
	get_tree().create_timer(0.5).timeout.connect(mesh_instance.queue_free)
	get_tree().create_timer(0.3).timeout.connect(particle_collision_instance.queue_free)
