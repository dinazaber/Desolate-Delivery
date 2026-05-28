@tool #Changing door mesh in the future
extends Node3D

@export var door_mesh: Mesh:
	set(value): 
		door_mesh = value
		$MeshInstance3D.mesh = door_mesh

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var closeTimer: Timer = $Timer
@onready var areas = $Areas.get_children()


var isOpen: int = 0
var type = "Door"

func _ready() -> void:
	anim.play("RESET")
	isOpen = 0

func _process(_delta: float) -> void:
	for i in range(0, 2): # 0 front; 1 back
		var player: CharacterBody3D = null
		if areas[i].has_overlapping_bodies():
			var bodies = []
			bodies += areas[i].get_overlapping_bodies()
			for body in bodies: if body.is_in_group("Player"): player = body
		
		if player:
			closeTimer.start()
			var dotVal = (player.velocity + player.direction).dot(($Marker3D.global_position - $Areas/OpenAreaFront/CollisionShape3D.global_position) * (1 if i else -1))
			if dotVal > 0.1: open(i)


func open(i):
	if !isOpen and !anim.is_playing():
		closeTimer.start()
		
		if i == -1: i = randi_range(0, 1)
		
		anim.play("Open" + str(i))
		await anim.animation_finished
		isOpen = i + 1
	

func close(playSpeed):
	if isOpen and !anim.is_playing():
		anim.play("Close" + str(isOpen - 1), -1, playSpeed)
		await anim.animation_finished
		isOpen = 0

func getOpenStatus(): return isOpen

func getType(): return type

func _on_timer_timeout() -> void:
	close(0.4)
