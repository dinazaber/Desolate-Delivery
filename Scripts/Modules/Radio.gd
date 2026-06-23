@tool
extends Node3D

@export var glow_intensity: float = 0.0:
	set(value):
		glow_intensity = value
		_update_shader_glow(value > 0.0, value)

@export var in_main_menu = false
@export var turn_on_start = false
var power = turn_on_start

@onready var anim_player = $AnimationPlayer
@onready var mesh = $MeshInstance3D
@onready var audio = $AudioStreamPlayer3D

func _ready():
	if in_main_menu:
		audio.volume_db = -80
		anim_player.play("TurnOn")
		await anim_player.animation_finished
		$AudioStreamPlayer.play()
		anim_player.play("Playing")
		
	elif turn_on_start:
		anim_player.play("Playing")
		audio.volume_db = -25
	
	else:
		anim_player.play("RESET")
		audio.volume_db = -80

func _update_shader_glow(enabled: bool, intensity: float):
	var mat = mesh.get_active_material(0)
	var shader_material = mat as ShaderMaterial
	shader_material.set_shader_parameter("enable_glow", enabled)
	shader_material.set_shader_parameter("glow_intensity", intensity)
	
	
func interact(): #Function called when player presses E key, called in player script
	if power: _turn_off()
	else: _turn_on()
	

func _turn_on():
	power = true
	anim_player.play("TurnOn")
	await anim_player.animation_finished
	anim_player.play("Playing")
	audio.volume_db = -25

func _turn_off():
	power = false
	audio.volume_db = -80
	anim_player.play("TurnOff")
	await anim_player.animation_finished
	anim_player.play("RESET")
	
