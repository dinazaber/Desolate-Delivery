extends Node3D

#gun stats
@export var damage: float = 15.0
@export var recoil: float = 1.5 # degree rotation
@export var heatPerShot: float = 10.0
@export var coolDown: float = 4.0 # time (s) it takes to go from 100 to 0 heat
@export var pellets: int = 1 # number of pellets
@export var bullet_speed: float = 70.0 # Speed of particles

@export var camera: Area3D
@export var playerRay: RayCast3D
@export var playerRayEnd: Marker3D
@onready var lookTarget = playerRayEnd.global_position

@onready var anim = $AnimationPlayer
@onready var heatBuffer = $HeatBuffer

@onready var barrel = $Marker3D/Barrel
@onready var tracer = $Marker3D/Barrel/RayCast3D/smg_tracers
@onready var ray = $Marker3D/Barrel/RayCast3D

var can_cool: bool = true
var heat: float = 0.0


func _ready() -> void:
	var material = tracer.process_material as ShaderMaterial # Get particle material
	material.set_shader_parameter("speed", bullet_speed) # Pellet speed
	tracer.amount = pellets # Set amount of pellets

func draw(playSpeed):
	anim.play("draw", -1, playSpeed)
	await anim.animation_finished

func undraw(playSpeed, asap):
	if anim.is_playing():
		if asap: anim.speed_scale = 3.0
		await anim.animation_finished
		anim.speed_scale = 1.0
	anim.play("undraw", -1, playSpeed)
	await anim.animation_finished

func shoot():
	if !anim.is_playing() and heat <= 100 - heatPerShot:
		anim.play("shoot")
		
		var points = PackedVector3Array()
		points.resize(pellets)
		
		var dist
		if playerRay.is_colliding():
			dist = ray.global_position.distance_to(playerRay.get_collision_point())
			if dist < 0.7:
				barrel.look_at(playerRayEnd.global_position)
			else:
				barrel.look_at(playerRay.get_collision_point())
		else:
			barrel.look_at(playerRayEnd.global_position)
		
		#barrel.rotation_degrees.y -= 90.0
		
		for i in range(pellets):
			ray.rotation.x = deg_to_rad(randf_range(-0.015, 0.015) * heat)
			ray.rotation.y = deg_to_rad(randf_range(-0.015, 0.015) * heat)
			
			ray.force_raycast_update()
		
			if ray.is_colliding(): # shoot
				var hit_pos = ray.get_collision_point()
				await spawn_debug_cube(hit_pos) # Cube spawn, will be replaced by decal later
				points[i] = hit_pos # Use collsion point as particle's target point
				if ray.get_collider().is_in_group("Enemy"):
					ray.get_collider().hit(damage, true)
				if ray.get_collider().is_in_group("ShotReactable"):
					ray.get_collider().shot()
			
			else: points[i] = $Marker3D/Barrel/RayCast3D/Marker3D.global_position # Take end of weapon ray as particle's target point
		
		var material = tracer.process_material as ShaderMaterial
		material.set_shader_parameter("hit_points", points) #Updating target points
		material.set_shader_parameter("gun_barrel_pos", tracer.global_position) #Setting starting point
		
		camera.add_recoil(recoil)
		tracer.restart()
		tracer.emitting = true
		heatBuffer.start()
		can_cool = false
		heat = clamp(heat + heatPerShot, 0.0, 100.0)
	
	await anim.animation_finished

func get_heat() -> float:
	return heat

func _on_restore_cool(coolOnKill: float) -> void:
	heat -= coolOnKill

func _process(delta: float) -> void:
	$Marker3D/Gun/Sprite.look_at(camera.global_position, Vector3.UP)
	
	if can_cool:
		heat = clamp(heat - (100 * delta) / coolDown, 0.0, 100.0)

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
