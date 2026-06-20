@tool
extends MeshInstance3D

var power = true

@export var editor_glow_intensity: float = 0.0:
	set(value):
		editor_glow_intensity = value
		_update_shader_glow(value > 0.0, value)

@export var anim_player: AnimationPlayer

func _ready():
	anim_player.play("Playing")

func _update_shader_glow(enabled: bool, intensity: float):
	var mat = get_active_material(0)
	var shader_material = mat as ShaderMaterial
	shader_material.set_shader_parameter("enable_glow", enabled)
	shader_material.set_shader_parameter("glow_intensity", intensity)
	
	
func interact(): #Function called when player presses E key
	pass
	

func _enable():
	power = true
	
