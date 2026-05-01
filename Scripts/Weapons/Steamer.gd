extends Node3D
signal knockBack(force: int, time: float)

#gun stats
@export var damage = 70.0
@export var recoil = 10.0 # degree rotation
@export var heatPerShot: float = 90.0
@export var coolDown: float = 5.0 # time (s) it takes to go from 100 to 0 heat

@export var camera: Area3D
@export var playerRay: RayCast3D

@onready var anim = $AnimationPlayer
@onready var heatBuffer = $HeatBuffer
@onready var dialArrow = $Gun/DialArrow/DialArrow
@onready var blastRange = $Gun/Area3D
@onready var steam = $Gun/GPUParticles3D
@onready var playerPos = $playerPos #correction value of the steamer's pos in relation to the player's hold pos

var can_cool: bool = true
var in_action: bool = false
var heat: float = 0.0


func shoot():
	in_action = true
	if !anim.is_playing() and heat <= 100 - heatPerShot:
		anim.play("draw")
		await anim.animation_finished
		anim.play("shoot")
		
		camera.add_recoil(recoil)
		steam.restart()
		steam.emitting = true
		heatBuffer.start()
		can_cool = false
		heat = clamp(heat + heatPerShot, 0.0, 100.0)
		
		var direction = camera.global_transform.basis.z.normalized()
		
		knockBack.emit(direction, 10, true, 0.2)
		
		var bodies = []
		if blastRange.has_overlapping_bodies(): bodies += blastRange.get_overlapping_bodies()
		if !bodies.is_empty():
			for body in bodies:
				if body.has_method("damage_taken") and !body.is_in_group("Player"):
					body.damage_taken(damage, true)
				if body.has_method("knockBack"):
					body.knockBack((body.global_position - playerPos.global_position).normalized(), damage/25.0, "_slowOnGround placeholder" , 0.2)
				if body.has_method("throw"):
					body.throw((body.global_position - playerPos.global_position).normalized(), 60.0)
		
		await anim.animation_finished
		anim.play_backwards("draw")
		await anim.animation_finished
	in_action = false

func get_heat() -> float:
	return heat

func _on_restore_cool(coolOnKill: float) -> void:
	heat -= coolOnKill

func _process(delta: float) -> void:
	if can_cool:
		heat = clamp(heat - (100 * delta) / coolDown, 0.0, 100.0)
	dialArrow.rotation_degrees.y = lerp(dialArrow.rotation_degrees.y, 45.0 - 2.7*heat, delta * 7.0)

func _on_heat_buffer_timeout() -> void:
	can_cool = true
