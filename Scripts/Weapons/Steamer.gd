extends Node3D
signal knockBack(force: int, direction: Vector3, slowOnGround: bool, time: float)

#gun stats
@export_category("stats")
@export var damage = 40.0
@export var selfKnockback: float = 6.0
@export var recoil = 10.0 # degree rotation
@export var heatPerShot: float = 45.0
@export var coolDown: float = 8.0 # time (s) it takes to go from 100 to 0 heat

@export_category("modifications")
@export var two_shots: bool = false # dual chamber presure tube

@export_category("editor")
@export var camera: Area3D
@export var playerRay: RayCast3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var heatBuffer = $HeatBuffer
@onready var dialArrow = $Gun/DialArrow/DialArrow
@onready var blastRange = $Gun/Area3D
@onready var steam = $Gun/GPUParticles3D
@onready var playerPos = $playerPos #correction value of the steamer's pos in relation to the player's hold pos

var shot_queued: bool = false
var can_cool: bool = true
var in_action: bool = false
var heat: float = 0.0

var damage_number = load("res://Scenes/UI/DamageNumber.tscn")
var damage_number_instance


func _ready() -> void:
	# modifications
	if !two_shots:
		damage *= 2
		selfKnockback = 2*selfKnockback - 2
		heatPerShot *= 2
		coolDown = coolDown / 2 + 1


func shoot():
	if anim.current_animation == "draw": return
	
	in_action = true
	
	if heat <= 100 - heatPerShot:
		show()
		if anim.is_playing() and anim.current_animation == "shoot":
			shot_queued = true
			await anim.animation_finished
			shot_queued = false
		else:
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
		
		knockBack.emit(direction, selfKnockback, true, 0.2)
		
		var bodies = []
		if blastRange.has_overlapping_bodies(): bodies += blastRange.get_overlapping_bodies()
		if !bodies.is_empty():
			for body in bodies:
				if body.has_method("damage_taken") and !body.is_in_group("Player"):
					body.damage_taken(damage, true, "heat", body.global_position)
				if body.has_method("knockBack"):
					body.knockBack((body.global_position - playerPos.global_position).normalized(), damage/25.0, null, 0.2)
				if body.has_method("throw"):
					body.throw((body.global_position - playerPos.global_position).normalized(), 80.0)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "shoot" and !shot_queued:
		anim.play_backwards("draw")
		await anim.animation_finished
		in_action = false
		hide()

func get_heat() -> float:
	return heat

func _on_restore_cool(coolOnKill: float) -> void:
	heat -= coolOnKill

func _process(delta: float) -> void:
	if can_cool:
		heat = clamp(heat - (100 * delta) / coolDown, 0.0, 100.0)
	dialArrow.rotation_degrees.y = lerp(dialArrow.rotation_degrees.y, 45.0 - 2.7*heat, delta * 12.5)

func _on_heat_buffer_timeout() -> void:
	can_cool = true

func handle_damage_number(dmg, pos): # aoe must use body pose
	damage_number_instance = damage_number.instantiate()
	damage_number_instance.position = pos
	get_tree().root.add_child(damage_number_instance)
	damage_number_instance.spawn(dmg)
