extends Node3D

@onready var decal: Decal = $Decal
@onready var raycast: RayCast3D = $RayCast3D

@export var max_distance: float = 10.0
var base_scale

func _ready() -> void:
	set_as_top_level(true)
	base_scale = decal.size
	
	if get_parent() is CollisionObject3D:
		raycast.add_exception(get_parent())

func _physics_process(_delta: float) -> void:
		
	var target_pos = get_parent().global_position
	global_position = target_pos
	global_rotation = Vector3.ZERO 

	if raycast.is_colliding():
		var hit_point = raycast.get_collision_point()
		var distance = target_pos.distance_to(hit_point)
		
		decal.global_position = hit_point
		
		var intensity = remap(distance, 0, max_distance, 1.0, 0.0)
		decal.albedo_mix = clamp(intensity, 0.0, 1.0)
		
		var size_mult = remap(distance, 0, max_distance, 1.0, 1.6)
		decal.size = base_scale * size_mult
	else:
		decal.albedo_mix = 0.0
