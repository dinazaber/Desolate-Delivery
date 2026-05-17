extends Node3D

#gun stats
@export var damage: float = 2.0
@export var recoil: float = 0.5 # degree rotation
@export var spread: Vector2 = Vector2(5.0, 15.0) # max deg rotation for 100% heat
@export var accuracyPerShot: float = 0.05
@export var heatPerShot: float = 2.75
@export var coolDown: float = 6.0 # time (s) it takes to go from 100 to 0 heat
@export var destabilize: float = 4.0 # time (s) it takes to go from max to min accuracy
@export var pellets: int = 2 # number of pellets
@export var bullet_speed: float = 70.0 # Speed of particles

@export var camera: Area3D
@export var playerRay: RayCast3D
@export var playerRayEnd: Marker3D
@onready var lookTarget = playerRayEnd.global_position

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var heatBuffer = $HeatBuffer

@onready var barrel = $Destabilizer/Barrel
@onready var tracer = $Destabilizer/tracer
@onready var ray = $Destabilizer/Barrel/RayCast3D

var can_cool: bool = true
var heat: float = 0.0
var accuracy_mod: float = 1.0
var spin_amount: float = 0.0

var crosshair_def_pos: Vector2

func _ready() -> void:
	var material = tracer.process_material as ShaderMaterial # Get particle material
	material.set_shader_parameter("speed", bullet_speed) # Pellet speed
	tracer.amount = pellets # Set amount of pellets
	
	crosshair_def_pos = $Crosshair/mid.position

func draw(playSpeed):
	$Crosshair.visible = true
	anim.play("draw", -1, playSpeed)
	await anim.animation_finished

func undraw(playSpeed, asap):
	if anim.is_playing():
		if asap: anim.speed_scale = 3.0
		await anim.animation_finished
		anim.speed_scale = 1.0
	anim.play("undraw", -1, playSpeed)
	await anim.animation_finished
	$Crosshair.visible = false
	spin_amount = 0.0

func spinup(up):
	if !anim.is_playing():
		var can_spinup: bool = up and heat < 100 - heatPerShot
		spin_amount = clamp(spin_amount + (1.0 if can_spinup else -0.33) * 60, 0.0, 1440.0)
	if spin_amount >= 1440.0: shoot()

func shoot():
	if !anim.is_playing() and heat < 100 - heatPerShot:
		$Destabilizer/tracer/Sprite.look_at(camera.global_position, Vector3.UP)
		$Destabilizer/tracer/Sprite.rotation.z = randf_range(-PI, PI)
		anim.play("shoot")
		
		var points = PackedVector3Array()
		points.resize(pellets)
		
		accuracy_mod = clamp(accuracy_mod - accuracyPerShot, 0.2, 1.0)
		
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
			ray.rotation.y = deg_to_rad(randf_range(-spread.y, spread.y) * accuracy_mod)
			ray.rotation.z = deg_to_rad(randf_range(0.0, 360.0))
			ray.rotation.x = deg_to_rad(randf_range(0.0, spread.x))
			
			ray.force_raycast_update()
		
			if ray.is_colliding(): # shoot
				var hit_pos = ray.get_collision_point()
				await spawn_debug_cube(hit_pos) # Cube spawn, will be replaced by decal later
				points[i] = hit_pos # Use collsion point as particle's target point
				var collider = ray.get_collider()
				if collider.is_in_group("Enemy"):
					if collider.has_method("hit"):
						collider.hit(damage, true)
				if collider.is_in_group("ShotReactable"):
					collider.shot()
			
			else: points[i] = $Destabilizer/Barrel/RayCast3D/Marker3D.global_position # Take end of weapon ray as particle's target point
		
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
	if can_cool:
		heat = clamp(heat - (100 * delta) / coolDown, 0.0, 100.0)
		accuracy_mod = clamp(accuracy_mod + delta / destabilize, 0.2, 1.0)
	
	$Destabilizer/Base/Barrels.rotation_degrees.z -= spin_amount * delta
	
	update_crosshair()

func _on_heat_buffer_timeout() -> void:
	can_cool = true

# --- crosshair ---
func update_crosshair():
	$Crosshair/handL.position.x = move_toward($Crosshair/handL.position.x, crosshair_def_pos.x - spread.y - accuracy_mod * 100, 1.25)
	$Crosshair/handR.position.x = move_toward($Crosshair/handR.position.x, crosshair_def_pos.x + spread.y + accuracy_mod * 100, 1.25)

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
