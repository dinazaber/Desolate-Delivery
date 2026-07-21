@tool
@icon("res://addons/dynamic_lightmap_shadows/BlobIcon.svg")
class_name BlobShadow
extends Node3D

## Shadow texture.
@export var shadow_texture: Texture2D:
	set(val):
		shadow_texture = val
		if is_inside_tree() and decal: decal.texture_albedo = shadow_texture

## Size of the blob shadow.
@export var shadow_dimensions: Vector3 = Vector3(1.0, 0.1, 1.0):
	set(val):
		shadow_dimensions = val
		if is_inside_tree() and decal: decal.size = shadow_dimensions

## Max height of blob shadow casting.
@export var max_distance: float = 10.0

## Height offset of the shadow.
@export_range(-10, 10) var shadow_offset: float = 0.0

## Collision mask of the blob shadows.[br]
## Shadow will snap to surfaces that share same collsion layers with it.
@export_flags_3d_physics var collision_mask: int = 1:
	set(val):
		collision_mask = val
		if is_inside_tree() and ray: ray.collision_mask = collision_mask

## Cull mask of the shadow decal.[br]
## Shadow will be visible on meshes that share same visual layers with it.
@export_flags_3d_render var shadow_cull_mask: int = 1:
	set(val):
		shadow_cull_mask = val
		if is_inside_tree() and decal: decal.cull_mask = shadow_cull_mask

var decal: Decal
var ray: RayCast3D

func _ready() -> void:
	# Nodes setup
	_initialize_nodes()
	decal.texture_albedo = shadow_texture
	decal.size = shadow_dimensions
	decal.cull_mask = shadow_cull_mask
	ray.collision_mask = collision_mask
	ray.target_position = Vector3(0, -max_distance, 0)
	
	if Engine.is_editor_hint():
		return
		
	set_as_top_level(true)
	
	var parent = get_parent()
	if parent is CollisionObject3D:
		ray.add_exception(parent)

func _physics_process(_delta: float) -> void:
	var parent = get_parent()
	if not parent or not parent is Node3D:
		return
		
	# Sync position and rotation with parent
	global_position = parent.global_position
	global_rotation = Vector3(0.0, parent.global_rotation.y, 0.0)

	if ray.is_colliding():
		var hit_point = ray.get_collision_point()
		var distance = global_position.y - hit_point.y
		
		hit_point.y -= shadow_offset
		decal.global_position = hit_point
		
		# Distance modifiers (Fading and Air Scale Spread)
		var intensity = remap(distance, 0.0, max_distance, 1.0, 0.0)
		decal.albedo_mix = clamp(intensity, 0.0, 1.0)
		
		var air_spread = remap(distance, 0.0, max_distance, 1.0, 1.5)
		air_spread = clamp(air_spread, 1.0, 1.5)
		
		decal.size.x = shadow_dimensions.x * air_spread
		decal.size.z = shadow_dimensions.z * air_spread
	else:
		decal.albedo_mix = 0.0
	

func _initialize_nodes():
	if !has_node("Shadow"): 
		decal = Decal.new()
		decal.name = "Shadow"
		decal.upper_fade = 0.0
		decal.lower_fade = 0.0
		add_child(decal)
	
	decal = get_node("Shadow")
	
	if !has_node("DecalRay"):
		ray = RayCast3D.new()
		ray.name = "DecalRay"
		ray.target_position = Vector3(0, -max_distance, 0)
		add_child(ray)
	
	ray = get_node("DecalRay")
