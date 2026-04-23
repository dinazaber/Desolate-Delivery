extends Node3D

#gun stats
@export var damage: float = 40.0
@export var recoil: float = 5.0 # degree rotation
@export var mag: int = 4
@export var heatPerShot: float = 22.25
@export var coolDown: float = 5.0 # time (s) it takes to go from 100 to 0 heat

@export var camera: Area3D
@export var playerRay: RayCast3D

var shotNum: int = 0
var can_cool: bool = true
var heat: float = 0.0

const MAX_DEVIATION = 5 # deviation (in degrees) of the pellets from the player's sight vector
const MIN_INPUTS = 8
const MAX_INPUTS = 12

@onready var anim = $AnimationPlayer
@onready var heatBuffer = $HeatBuffer

func draw():
	anim.play("draw")
	shotNum = 0

func undraw():
	if anim.is_playing():
		await anim.animation_finished
	anim.play("undraw")
	shotNum = 0
	await anim.animation_finished

func charge():
	if !anim.is_playing():
		if shotNum < mag and heat <= 100 - heatPerShot * (shotNum + 1):
			anim.play("load")
			await anim.animation_finished
			shotNum += 1
					
func shoot():
	if anim.is_playing(): await anim.animation_finished
	while shotNum > 0:
		if shotNum > 1: anim.play("shootConsecutive")
		else: anim.play("shootLast")
		
		heatBuffer.start()
		can_cool = false
		heat = clamp(heat + heatPerShot, 0.0, 100.0)
		camera.add_recoil(recoil)
		shotNum -= 1
		
		if playerRay.is_colliding():
			if playerRay.get_collider().is_in_group("Enemy"):
				playerRay.get_collider().hit(damage, "player")
			if playerRay.get_collider().is_in_group("ShotReactable"):
				playerRay.get_collider().shot()
		await anim.animation_finished

func get_heat() -> float:
	return heat

func _on_restore_cool(coolOnKill: float) -> void:
	heat -= coolOnKill

func _process(delta: float) -> void:
	if can_cool:
		heat = clamp(heat - (100 * delta) / coolDown, 0.0, 100.0)

func _on_heat_buffer_timeout() -> void:
	can_cool = true

func random_deviations() -> Array:
	var deviations = []
	var inputs = randi_range(MIN_INPUTS, MAX_INPUTS)
	for i in range(inputs):
		deviations.append(MAX_DEVIATION * randf())
	return deviations
