@tool
extends Node3D

@export var door_mesh: Mesh:
	set(value): 
		door_mesh = value
		$MeshInstance3D.mesh = door_mesh

@export var front_room: Node3D #Green area
@export var back_room: Node3D #Red area

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var closeTimer: Timer = $Timer
@onready var areas = $Areas.get_children()
@onready var rooms = [front_room, back_room]


var openType: int = -1
var type = "Door"
var last_exited_area

func _ready() -> void:
	anim.play("RESET")
	openType = -1
	for i in range(areas.size()):
		areas[i].body_exited.connect(func(body): _on_area_body_exited(body, i))

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
				closeTimer.start()
		
		if enemy:
			var dotVal = (enemy.velocity).dot(($Marker3D.global_position - $Areas/OpenAreaFront/CollisionShape3D.global_position) * (1 if i else -1))
			if dotVal > 0.1: open(i)
			closeTimer.start()


func open(i):
	if openType < 0:
		anim.play("Open" + str(i), 0.25)
		openType = i
		for room in rooms: room.show()
	

func close(playSpeed):
	if openType >= 0:
		anim.play("Close" + str(openType), 0.25, playSpeed)
		openType = -1
		

func getOpenStatus(): return openType

func getType(): return type

func _on_timer_timeout() -> void:
	close(0.5)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Close0": hide_room(0)
	elif anim_name == "Close1": hide_room(1)


func hide_room(side):
	if last_exited_area != side: rooms[side].hide()
	else: rooms[1 - last_exited_area].hide()
	
func _on_area_body_exited(body, i):
	if body.is_in_group("Player"): last_exited_area = i
