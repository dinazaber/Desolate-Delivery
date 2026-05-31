@tool #Changing door mesh in the future
extends Node3D

@export var door_mesh: Mesh:
	set(value): 
		door_mesh = value
		$MeshInstance3D.mesh = door_mesh

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var closeTimer: Timer = $Timer
@onready var areas = $Areas.get_children()


var openType: int = -1
var type = "Door"

func _ready() -> void:
	anim.play("RESET")
	openType = -1

func _physics_process(_delta: float) -> void:
	for i in range(0, 2): # 0 front; 1 back
		var player: CharacterBody3D = null
		var enemy: CharacterBody3D = null
		if areas[i].has_overlapping_bodies():
			var bodies = []
			bodies += areas[i].get_overlapping_bodies()
			for body in bodies:
				if body.is_in_group("Player"): player = body
				elif body.is_in_group("Enemy"): enemy = body
		
		if player:
			if player.autoOpenDoors:
				var dotVal = (player.velocity + player.direction).dot(($Marker3D.global_position - $Areas/OpenAreaFront/CollisionShape3D.global_position) * (1 if i else -1))
				if dotVal > 0.1: open(i)
			if player.autoCloseDoors:
				closeTimer.start()
		
		if enemy:
			var dotVal = (enemy.velocity).dot(($Marker3D.global_position - $Areas/OpenAreaFront/CollisionShape3D.global_position) * (1 if i else -1))
			if dotVal > 0.1: open(i)
			closeTimer.start()


func open(i):
	if openType < 0:
		anim.play("Open" + str(i), 0.25)
		openType = i
	

func close(playSpeed):
	if openType >= 0:
		anim.play("Close" + str(openType), 0.25, playSpeed)
		openType = -1

func getOpenStatus(): return openType

func getType(): return type

func _on_timer_timeout() -> void:
	close(0.5)


#func _on_open_area_front_body_entered(body: Node3D) -> void:
#	if anim.is_playing(): await anim.animation_finished
#	if body.is_in_group("Player"):
#		if body.autoOpenDoors:
#			closeTimer.start()
#			open(0) #Open Front


#func _on_open_area_back_body_entered(body: Node3D) -> void:
#	if anim.is_playing(): await anim.animation_finished
#	if body.is_in_group("Player"):
#		if body.autoOpenDoors:
#			closeTimer.start()
#			open(1) #Open Back
