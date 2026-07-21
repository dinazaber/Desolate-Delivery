@tool
@icon("res://addons/dynamic_lightmap_shadows/ProjectorIcon.svg")
class_name OrthogonalShadowProjector
extends Node

enum FilterType {NONE, PCF4, PCF9, VOGEL}

@export_category("General")

## Shadow map preview.[br]
## Every black silhouette is a shadow.
@export var shadow_map_preview: Texture2D:
	get():
		if viewport: return viewport.get_texture()
		return null
		

## The player or object the shadow camera should follow.
@export var target_node: Node3D


## The size of the orthographic camera's view frustum in world units(shadow draw max distance).
@export var shadow_draw_distance: float = 15.0:
	set(val):
		shadow_draw_distance = val
		RenderingServer.global_shader_parameter_set("shadow_world_size", shadow_draw_distance)
		if is_inside_tree() and camera: camera.size = shadow_draw_distance
			

## The visual layer index used for shadow casting objects.
@export_range(1, 20) var shadow_layer: int = 2:
	set(val):
		shadow_layer = val
		if is_inside_tree() and camera:
			camera.cull_mask = 1 << (shadow_layer - 1)
			

@export_category("Shadow Settings")
## Resolution of shadows. The higher resolution, the more VRAM and resources needed.[br]
## Note: Increasing 'shadow_draw_distance' makes shadows less detailed.
@export var shadow_size: int = 512:
	set(val):
		val = clampi(val, 0, 8192)
		shadow_size = nearest_po2(val)
		if is_inside_tree() and viewport:
			viewport.size = Vector2(shadow_size, shadow_size)
			
## Adjust shadow filter.[br]
## Vogel - best quality, uses 16 shadow map samples, slow.[br]
## PCF9 - high quality, uses 9 shadow map samples, fast.[br]
## PCF4 - meduim quality, uses 4 shadow map samples, faster.[br]
## None - worst quality, fastest.
@export var active_filter: FilterType = FilterType.VOGEL:
	set(val):
		active_filter = val
			
		RenderingServer.global_shader_parameter_set("filter_type", active_filter)
		
		
## Set shadow filter scale(bloor amount)
@export_range(0.1, 3.0) var filter_scale: float = 1.0:
	set(val):
		filter_scale = val
		RenderingServer.global_shader_parameter_set("filter_scale", filter_scale)
		
		
## Set shadow color, brighter colors increase shadow's transparency
@export var shadow_color: Color = Color.BLACK:
	set(val):
		shadow_color = val
		RenderingServer.global_shader_parameter_set("shadow_color", shadow_color)
		

var viewport: SubViewport
var camera: Camera3D

func _ready() -> void:
	
	_initialize_nodes()
	
	viewport.size = Vector2(shadow_size, shadow_size)
	camera.size = shadow_draw_distance
	camera.cull_mask = 1 << (shadow_layer - 1)
	
	_update_shader_globals()
	

func _process(_delta: float) -> void:
	if not target_node or not is_instance_valid(target_node): return
	if not viewport or not camera: return
	
	# Match the target's position
	var target_pos = target_node.global_position
	var texel_size = shadow_draw_distance / float(shadow_size)
	var snapped_x: float = round(target_pos.x / texel_size) * texel_size
	var snapped_z: float = round(target_pos.z / texel_size) * texel_size
	camera.global_position = Vector3(snapped_x, target_pos.y + 1000.0, snapped_z)
		
	# Updating camera's center
	RenderingServer.global_shader_parameter_set("shadow_camera_center", Vector2(camera.global_position.x, camera.global_position.z))


func _update_shader_globals():
	
	if !is_inside_tree(): return
	
	if viewport: RenderingServer.global_shader_parameter_set("top_down_shadow_map", viewport.get_texture())
	RenderingServer.global_shader_parameter_set("shadow_world_size", shadow_draw_distance)
	RenderingServer.global_shader_parameter_set("filter_scale", filter_scale)
	RenderingServer.global_shader_parameter_set("shadow_color", shadow_color)
	RenderingServer.global_shader_parameter_set("filter_type", active_filter)


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE: _update_shader_globals()



func _initialize_nodes():
	
	#initialize viewport
	if not has_node("ShadowViewport"):
		viewport = SubViewport.new()
		viewport.name = "ShadowViewport"
		viewport.transparent_bg = true
		viewport.handle_input_locally = false
		viewport.gui_disable_input = true
		viewport.use_hdr_2d = false
		viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		viewport.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
		add_child(viewport)
		
	viewport = get_node("ShadowViewport") as SubViewport

	# Initialize camera
	if not viewport.has_node("ShadowCamera"):
		camera = Camera3D.new()
		camera.name = "ShadowCamera"
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.rotation_degrees = Vector3(-90, 0, 0)
		viewport.add_child(camera)
		
	camera = viewport.get_node("ShadowCamera") as Camera3D
