extends Node3D

#gun stats
@export var damage: float = 50.0
@export var recoil: float = 9.0 # degree rotation
@export var heatPerShot: float = 45.0
@export var coolDown: float = 5.0 # time (s) it takes to go from 100 to 0 heat

@export var camera: Area3D
@export var playerRay: RayCast3D
@export var playerRayEnd: Marker3D
@onready var lookTarget = playerRayEnd.global_position

@onready var anim = $AnimationPlayer
@onready var heatBuffer = $HeatBuffer
@onready var ray = $Marker3D/RayCast3D

var can_cool: bool = true
var heat: float = 0.0

var crosshair_def_pos: Vector2
var crosshair_move: float = 0.0

var shot_instance
var shot = load("res://Scenes/Weapons/DevastatorShot.tscn")

func draw(playSpeed):
	$Crosshair.visible = true
	anim.play("draw", -1, playSpeed)
	await anim.animation_finished

func undraw(playSpeed, asap):
	if anim.is_playing():
		if asap: anim.speed_scale = 3.0
		await anim.animation_finished
		anim.speed_scale = 1.0
	anim.play("undraw", -1, playSpeed)
	await anim.animation_finished
	$Crosshair.visible = false

func shoot():
	if !anim.is_playing() and heat <= 100 - heatPerShot:
		$sparks.restart()
		$sparks.emitting = true
		
		anim.play("shoot")
		
		var dist
		if playerRay.is_colliding():
			dist = ray.global_position.distance_to(playerRay.get_collision_point())
			if dist < 0.7:
				ray.look_at(playerRayEnd.global_position)
			else:
				ray.look_at(playerRay.get_collision_point())
		else:
			ray.look_at(playerRayEnd.global_position)
		
		shot_instance = shot.instantiate()
		get_tree().root.add_child(shot_instance)
		shot_instance.global_position = ray.global_position
		shot_instance.rotation = ray.rotation
		shot_instance.set_velocity(($Marker3D/RayCast3D/Marker3D.global_position - ray.global_position).normalized())
		
		camera.add_recoil(recoil)
		camera.add_trauma(recoil*0.7)
		
		heatBuffer.start()
		can_cool = false
		heat = clamp(heat + heatPerShot, 0.0, 100.0)
	await anim.animation_finished

func get_heat() -> float:
	return heat

func _on_restore_cool(coolOnKill: float) -> void:
	heat -= coolOnKill

func _process(delta: float) -> void:
	$Sprite.look_at(camera.global_position, Vector3.UP)
	
	if can_cool:
		heat = clamp(heat - (100 * delta) / coolDown, 0.0, 100.0)

func _on_heat_buffer_timeout() -> void:
	can_cool = true
