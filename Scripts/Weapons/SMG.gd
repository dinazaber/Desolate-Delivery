extends Node3D

#gun stats
@export var damage: float = 15.0
@export var recoil: float = 0.4
@export var heatPerShot: float = 10.0
@export var coolDown: float = 5.0 # time (s) it takes to go from 100 to 0 heat

@export var camera: Area3D
@export var playerRay: RayCast3D

@onready var anim = $AnimationPlayer
@onready var heatBuffer = $HeatBuffer

var can_cool: bool = true
var heat: float = 0.0

func draw():
	anim.play("draw")

func undraw():
	if anim.is_playing():
		await anim.animation_finished
	anim.play("undraw")
	await anim.animation_finished

func shoot():
	if !anim.is_playing() and heat <= 100 - heatPerShot:
		anim.play("shoot")
		
		camera.add_trauma(recoil)
		heatBuffer.start()
		can_cool = false
		heat = clamp(heat + heatPerShot, 0.0, 100.0)
		
		if playerRay.is_colliding():
			if playerRay.get_collider().is_in_group("Enemy"):
				playerRay.get_collider().hit(damage, "player")
			if playerRay.get_collider().is_in_group("ShotReactable"):
				playerRay.get_collider().shot()

func get_heat() -> float:
	return heat

func _on_restore_cool(coolOnKill: float) -> void:
	heat -= coolOnKill

func _process(delta: float) -> void:
	if can_cool:
		heat = clamp(heat - (100 * delta) / coolDown, 0.0, 100.0)

func _on_heat_buffer_timeout() -> void:
	can_cool = true
