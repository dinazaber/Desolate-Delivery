extends Node3D

#gun stats
@export var damage: float = 15.0
@export var recoil: float = 1.5 # degree rotation
@export var heatPerShot: float = 10.0
@export var coolDown: float = 5.0 # time (s) it takes to go from 100 to 0 heat

@export var camera: Area3D
@export var playerRay: RayCast3D
@export var playerRayEnd: Marker3D
@onready var lookTarget = playerRayEnd.global_position

@onready var anim = $AnimationPlayer
@onready var heatBuffer = $HeatBuffer
@onready var tracer = $SMG/Barrel/RayCast3D/smg_tracers
@onready var ray = $SMG/Barrel/RayCast3D
@onready var barrel = $SMG/Barrel

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
		
		var dist
		if playerRay.is_colliding():
			dist = barrel.global_position.distance_to(playerRay.get_collision_point())
			if dist < 0.7:
				barrel.look_at(playerRayEnd.global_position)
			else:
				barrel.look_at(playerRay.get_collision_point())
		else:
			barrel.look_at(playerRayEnd.global_position)
		
		camera.add_recoil(recoil)
		tracer.restart()
		tracer.emitting = true
		heatBuffer.start()
		can_cool = false
		heat = clamp(heat + heatPerShot, 0.0, 100.0)
		
		if ray.is_colliding():
			if ray.get_collider().is_in_group("Enemy"):
				ray.get_collider().hit(damage, true)
			if ray.get_collider().is_in_group("ShotReactable"):
				ray.get_collider().shot()

func get_heat() -> float:
	return heat

func _on_restore_cool(coolOnKill: float) -> void:
	heat -= coolOnKill

func _process(delta: float) -> void:
	if can_cool:
		heat = clamp(heat - (100 * delta) / coolDown, 0.0, 100.0)

func _on_heat_buffer_timeout() -> void:
	can_cool = true
