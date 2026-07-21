@tool
extends EditorPlugin

const GLOBAL_PARAMS = {
	"top_down_shadow_map": { "type": "sampler2D", "value": null },
	"shadow_world_size": { "type": "float", "value": 15.0 },
	"shadow_camera_center": { "type": "vec2", "value": Vector2.ZERO },
	"filter_type": {"type": "int", "value": 3},
	"shadow_color": {"type": "vec3", "value": Vector3(0.1, 0.1, 0.1)},
	"filter_scale": {"type": "float", "value": 1.0}
}

func _enter_tree() -> void:
	# Add the custom node to the "Add Node" menu
	add_custom_type(
		"OrthogonalShadowProjector",
		"Node",
		preload("res://addons/dynamic_lightmap_shadows/orthogonal_shadow_projector.gd"),
		preload("res://addons/dynamic_lightmap_shadows/ProjectorIcon.svg")
	)
	
	add_custom_type(
		"BlobShadow",
		"Node3D",
		preload("res://addons/dynamic_lightmap_shadows/blob_shadow.gd"),
		preload("res://addons/dynamic_lightmap_shadows/BlobIcon.svg")
	)
	
	# Automatically register the required Shader Globals in Project Settings
	for param_name in GLOBAL_PARAMS.keys():
		var path = "shader_globals/" + param_name
		var data = GLOBAL_PARAMS[param_name]
		ProjectSettings.set_setting(path, {
			"type": data["type"],
			"value": data["value"]
		})
	ProjectSettings.save()

func _exit_tree() -> void:
	remove_custom_type("OrthogonalShadowProjector")
	remove_custom_type("BlobShadow")
	
	# Clean up Project Settings when disabling the plugin
	for param_name in GLOBAL_PARAMS.keys():
		var path = "shader_globals/" + param_name
		if ProjectSettings.has_setting(path):
			ProjectSettings.set_setting(path, null)
	ProjectSettings.save()
