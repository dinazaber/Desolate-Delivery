@tool
extends Area3D

@export var doors: Array[NodePath] = []

func _ready() -> void:
	body_entered.connect(_on_player_entered)
	body_exited.connect(_on_player_exited)
	

func _on_player_entered():
	pass

func _on_player_exited():
	pass
	
	
func hide_rooms():
	for door_path in doors:
		var door = get_node(door_path)
		var room = door.get_meta("Room")
		if door.openType < 0: room.hide()

func hide_doors():
	var all_doors = get_tree().get_nodes_in_group("Doors")
	for door in all_doors:
		if !(door in doors): door.get_parent().hide()
		
