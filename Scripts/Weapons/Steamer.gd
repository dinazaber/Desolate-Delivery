extends Node3D
signal knockBack(force: int, time: float)

#gun stats
@export var damage = 70
@export var recoil = 1.5
@export var heatPerShot: float = 60.0
@export var coolDown: float = 7.0 # time (s) it takes to go from 100 to 0 heat

@export var camera: Area3D
@export var playerRay: RayCast3D

@onready var anim = $AnimationPlayer
@onready var heatBuffer = $HeatBuffer

var can_cool: bool = true
var heat: float = 0.0


func shoot():
	if !anim.is_playing() and heat <= 100 - heatPerShot:
		anim.play("Draw")
		await anim.animation_finished
		anim.play("Shoot")
		
		camera.add_trauma(recoil)
		heatBuffer.start()
		can_cool = false
		heat = clamp(heat + heatPerShot, 0.0, 100.0)
		
		var direction = camera.global_transform.basis.z.normalized()
		
		knockBack.emit(direction, 10, 0.2)
		
		if playerRay.is_colliding():
			if playerRay.get_collider().is_in_group("Enemy"):
				playerRay.get_collider().hit(damage, "player")
			if playerRay.get_collider().is_in_group("ShotReactable"):
				playerRay.get_collider().shot()
		
		await anim.animation_finished
		anim.play_backwards("Draw")

func get_heat() -> float:
	return heat

func _on_restore_cool(coolOnKill: float) -> void:
	heat -= coolOnKill

func _process(delta: float) -> void:
	if can_cool:
		heat = clamp(heat - (100 * delta) / coolDown, 0.0, 100.0)

func _on_heat_buffer_timeout() -> void:
	can_cool = true
