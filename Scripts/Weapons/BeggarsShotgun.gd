extends Node3D

#gun stats
@export var damage: float = 7.0 # per pellet
@export var recoil: float = 4.0 # degree rotation
@export var spread: float = 2.5 # max pellet spread (degrees)
@export var mag: int = 4
@export var heatPerShot: float = 22.25
@export var coolDown: float = 5.0 # time (s) it takes to go from 100 to 0 heat

@export var camera: Area3D
@export var playerRay: RayCast3D
@export var playerRayEnd: Marker3D

var shotNum: int = 0
var can_cool: bool = true
var heat: float = 0.0

@onready var anim = $AnimationPlayer
@onready var heatBuffer = $HeatBuffer

@onready var pellet_1 = $BeggarsShotgun/Frame/Rays/RayCast3D1
@onready var pellet_2 = $BeggarsShotgun/Frame/Rays/RayCast3D2
@onready var pellet_3 = $BeggarsShotgun/Frame/Rays/RayCast3D3
@onready var pellet_4 = $BeggarsShotgun/Frame/Rays/RayCast3D4
@onready var pellet_5 = $BeggarsShotgun/Frame/Rays/RayCast3D5
@onready var pellet_6 = $BeggarsShotgun/Frame/Rays/RayCast3D6
@onready var pellet_7 = $BeggarsShotgun/Frame/Rays/RayCast3D7
@onready var pellet_8 = $BeggarsShotgun/Frame/Rays/RayCast3D8
@onready var pellet_9 = $BeggarsShotgun/Frame/Rays/RayCast3D9
@onready var pellets: Array = [pellet_1,pellet_2,pellet_3,pellet_4,pellet_5,pellet_6,pellet_7,pellet_8,pellet_9]

@onready var tracer_1 = $BeggarsShotgun/Frame/Rays/RayCast3D1/tracer
@onready var tracer_2 = $BeggarsShotgun/Frame/Rays/RayCast3D2/tracer
@onready var tracer_3 = $BeggarsShotgun/Frame/Rays/RayCast3D3/tracer
@onready var tracer_4 = $BeggarsShotgun/Frame/Rays/RayCast3D4/tracer
@onready var tracer_5 = $BeggarsShotgun/Frame/Rays/RayCast3D5/tracer
@onready var tracer_6 = $BeggarsShotgun/Frame/Rays/RayCast3D6/tracer
@onready var tracer_7 = $BeggarsShotgun/Frame/Rays/RayCast3D7/tracer
@onready var tracer_8 = $BeggarsShotgun/Frame/Rays/RayCast3D8/tracer
@onready var tracer_9 = $BeggarsShotgun/Frame/Rays/RayCast3D9/tracer
@onready var tracers: Array = [tracer_1,tracer_2,tracer_3,tracer_4,tracer_5,tracer_6,tracer_7,tracer_8,tracer_9]

@onready var rays = $BeggarsShotgun/Frame/Rays


func _ready() -> void:
	for pellet in pellets: # scatter
		pellet.rotation = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * deg_to_rad(spread)

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
		
		await scatterNshoot()
		
		heatBuffer.start()
		can_cool = false
		heat = clamp(heat + heatPerShot, 0.0, 100.0)
		camera.add_recoil(recoil)
		shotNum -= 1
		
		await anim.animation_finished

func scatterNshoot():
	var dist
	if playerRay.is_colliding():
		dist = rays.global_position.distance_to(playerRay.get_collision_point())
		if dist < 0.7:
			rays.look_at(playerRayEnd.global_position)
		else:
			rays.look_at(playerRay.get_collision_point())
	else:
		rays.look_at(playerRayEnd.global_position)
	
	for pellet in pellets: # scatter
		pellet.rotation = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * deg_to_rad(spread)
		
		if pellet.is_colliding(): # shoot
			if pellet.get_collider().is_in_group("Enemy"):
				pellet.get_collider().hit(damage, "player")
			if pellet.get_collider().is_in_group("ShotReactable"):
				pellet.get_collider().shot()
	
	for tracer in tracers: # emit
		tracer.restart()
		tracer.emitting = true

func get_heat() -> float:
	return heat

func _on_restore_cool(coolOnKill: float) -> void:
	heat -= coolOnKill

func _process(delta: float) -> void:
	if can_cool:
		heat = clamp(heat - (100 * delta) / coolDown, 0.0, 100.0)

func _on_heat_buffer_timeout() -> void:
	can_cool = true
