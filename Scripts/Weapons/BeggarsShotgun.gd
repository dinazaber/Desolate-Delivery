extends Node3D

#gun stats
@export var damage: float = 7.0 # per pellet
@export var recoil: float = 4.0 # degree rotation
@export var spread: float = 4.5 # max pellet spread (degrees) (for first shot)
@export var pellets: int = 9 # number of pellets
@export var bullet_speed: float = 70.0 # Speed of particles
@export var mag: int = 4
@export var heatPerShot: float = 22.25
@export var coolDown: float = 5.0 # time (s) it takes to go from 100 to 0 heat

@export var camera: Area3D
@export var playerRay: RayCast3D
@export var playerRayEnd: Marker3D

var shotNum: int = 1
var can_cool: bool = true
var heat: float = 0.0
var last_anim: String = ""

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var heatBuffer = $HeatBuffer

@onready var barrel = $BeggarsShotgun/Barrel
@onready var pellet = $BeggarsShotgun/Barrel/RayCast
@onready var tracer = $BeggarsShotgun/Barrel/RayCast/tracer
@onready var steam = $BeggarsShotgun/steam


func _ready() -> void:
	#pellet.rotation = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * deg_to_rad(spread)
	var material = tracer.process_material as ShaderMaterial # Get particle material
	material.set_shader_parameter("speed", bullet_speed) # Pellet speed
	tracer.amount = pellets # Set amount of pellets

func draw(playSpeed):
	anim.play("draw", -1, playSpeed)
	shotNum = 1
	await anim.animation_finished

func undraw(playSpeed, asap):
	if anim.is_playing():
		if asap or anim.current_animation == "load": anim.speed_scale = 3.0
		shotNum = 0
		await anim.animation_finished
		anim.speed_scale = 1.0
	anim.play("undraw", -1, playSpeed)
	shotNum = 1
	await anim.animation_finished

func charge():
	if !anim.is_playing():
		if shotNum < mag and heat <= 100 - heatPerShot * (shotNum + 1):
			anim.play("load")
			await anim.animation_finished
			if last_anim == "load":
				shotNum += 1

func shoot():
	if anim.is_playing() and anim.current_animation != "load": await anim.animation_finished
	while shotNum > 0:
		if shotNum > 1: anim.play("shootConsecutive")
		else: anim.play("shootLast")
		
		await scatterNshoot()
		
		heatBuffer.start()
		can_cool = false
		heat = clamp(heat + heatPerShot, 0.0, 100.0)
		camera.add_recoil(recoil)
		shotNum -= 1
		
		await anim.animation_finished

func scatterNshoot():
	var points = PackedVector3Array()
	points.resize(pellets)
	var dist
	if playerRay.is_colliding():
		dist = barrel.global_position.distance_to(playerRay.get_collision_point())
		if dist < 0.7:
			barrel.look_at(playerRayEnd.global_position, Vector3.UP, true)
		else:
			barrel.look_at(playerRay.get_collision_point(), Vector3.UP, true)
	else:
		barrel.look_at(playerRayEnd.global_position, Vector3.UP, true)
	
	for i in range(pellets):
		pellet.rotation.x = deg_to_rad(randf_range(-spread, spread) * (4 - shotNum*0.7)/4)
		pellet.rotation.y = deg_to_rad(randf_range(-spread, spread) * (4 - shotNum*0.7)/4 + 180)
		
		pellet.force_raycast_update()
		
		if pellet.is_colliding(): # shoot
			var hit_pos = pellet.get_collision_point()
			await spawn_debug_cube(hit_pos) # Cube spawn, will be replaced by decal later
			points[i] = hit_pos # Use collsion point as particle's target point
			if pellet.get_collider().is_in_group("Enemy"):
				pellet.get_collider().hit(damage, true)
			if pellet.get_collider().is_in_group("ShotReactable"):
				pellet.get_collider().shot()
				
		else: points[i] = $BeggarsShotgun/Barrel/RayCast/Marker3D.global_position # Take end of weapon ray as particle's target point
	
	var material = tracer.process_material as ShaderMaterial
	material.set_shader_parameter("hit_points", points) #Updating target points
	material.set_shader_parameter("gun_barrel_pos", tracer.global_position) #Setting starting point
	
	tracer.restart()
	tracer.emitting = true

func get_heat() -> float:
	return heat

func _on_restore_cool(coolOnKill: float) -> void:
	heat -= coolOnKill

func _process(delta: float) -> void:
	# Shader gets current shotNum value every frame.
	var mat = $BeggarsShotgun/Frame.get_active_material(0) as ShaderMaterial #Display shader material
	mat.set_shader_parameter("charge_amount", shotNum) #Update charge amount parameter using shotNum
	
	if can_cool:
		heat = clamp(heat - (100 * delta) / coolDown, 0.0, 100.0)
	
	steam.amount_ratio = heat / 100.0
	
	if !anim.is_playing() and shotNum == 0 and heat <= 100.0 - heatPerShot:
		charge()
	
	if anim.is_playing(): last_anim = anim.current_animation

func _on_heat_buffer_timeout() -> void:
	can_cool = true
	

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
	get_tree().create_timer(2.0).timeout.connect(mesh_instance.queue_free)
	get_tree().create_timer(0.3).timeout.connect(particle_collision_instance.queue_free)
