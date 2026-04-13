extends Node3D

@export_category("gun sway")
@export var sway_min: Vector2 = Vector2(-20.0,-20.0)
@export var sway_max: Vector2 = Vector2(20.0,20.0)
@export_range(0,0.2,0.01) var sway_speed_pos: float = 0.07
@export_range(0,0.2,0.01) var sway_speed_rot: float = 0.1
@export_range(0,0.25,0.01) var sway_amount_pos: float = 0.01
@export_range(0,50,0.01) var sway_amount_rot: float = 30.0
@export var idle_sway_adjustment: float = 10.0
@export var idle_sway_rotation_strength: float = 300.0
@export_range(0.1, 10.0, 0.1) var random_sway_amount = 5.0
@export var sway_speed: float = 1.2
#--------------------------------------------------------------


var mouse_movement: Vector2 = Vector2.ZERO
var random_sway_x
var random_sway_y
var time: float = 0.0


func _ready() -> void:
	await owner.ready

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_movement = event.relative
	else:
		mouse_movement = Vector2.ZERO
	

func sway_gun(delta):
	#constant waving
	#var sway_random: float = randf_range(0.01, 0.2) * idle_sway_adjustment
	#time += delta * (sway_speed + sway_random)
	#random_sway_x = sin(time + sway_random) / random_sway_amount
	#random_sway_y = sin(time * 1.5 - sway_random) / random_sway_amount
	random_sway_x = 0.0 ## remove when enabling constant waving
	random_sway_y = 0.0 ## remove when enabling constant waving
	
	mouse_movement = mouse_movement.clamp(sway_min,sway_max)
	
#	broken - sways the gun permanently (pos only)
#	position.x = lerp(position.x, position.x + (mouse_movement.x * sway_amount_pos + random_sway_x) * delta,
#sway_speed_pos)
#	position.y = lerp(position.y, position.y + (mouse_movement.y * sway_amount_pos * random_sway_y) * delta,
#sway_speed_pos)
	
	rotation_degrees.y = lerp(rotation_degrees.y, rotation.y + (mouse_movement.x * sway_amount_rot + 
(random_sway_y * idle_sway_rotation_strength)) * delta, sway_speed_rot)
	rotation_degrees.x = lerp(rotation_degrees.x, rotation.x + (mouse_movement.y * sway_amount_rot + 
(random_sway_x * idle_sway_rotation_strength))* delta, sway_speed_rot)

func _process(delta: float) -> void:
	sway_gun(delta)
