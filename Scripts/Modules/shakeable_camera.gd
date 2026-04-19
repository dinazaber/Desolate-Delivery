extends Area3D

@export var trauma_reduction_rate = 1.0
@export var noise: FastNoiseLite
@export var noise_speed = 50.0
@export var max_x = 10.0
@export var max_y = 10.0
@export var max_z = 5.0

var trauma = 0.0
var time = 0.0
var recoil_rotation = Vector2(0.0, 0.0)

@onready var camera = $Camera3D
@onready var initial_rotation = camera.rotation_degrees

func _process(delta: float) -> void:
	time += delta
	trauma = max(trauma - delta * trauma_reduction_rate, 0.0)
	
	recoil_rotation.x = lerp(recoil_rotation.x, 0.0, delta * 10.0)
	recoil_rotation.y = lerp(recoil_rotation.y, 0.0, delta * 10.0)
	
	camera.rotation_degrees.x = initial_rotation.x + recoil_rotation.x + max_x * get_shake_intencity() * get_noise_from_seed(0)
	camera.rotation_degrees.y = initial_rotation.y + recoil_rotation.y + max_y * get_shake_intencity() * get_noise_from_seed(1)
	camera.rotation_degrees.z = initial_rotation.z + max_z * get_shake_intencity() * get_noise_from_seed(2)


func add_recoil(recoil_amount: float): # y,x cuz godot is goofy
	recoil_rotation += Vector2(randf_range(0.5, 1.0), randf_range(-0.7, 0.7)).normalized() * recoil_amount

func add_trauma(trauma_amount: float):
	trauma = clamp(trauma + trauma_amount, 0.0, 1.0)

func get_shake_intencity() -> float:
	return trauma * trauma

func get_noise_from_seed(_seed: int) -> float:
	noise.seed = _seed
	return noise.get_noise_1d(time * noise_speed)
