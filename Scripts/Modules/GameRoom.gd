class_name GameRoom
extends Node3D

@onready var area = $PlayerDetectionArea

func hide_room(): hide()

func show_room(): show()

func player_inside(): 
	var player = get_tree().get_first_node_in_group("Player")
	print(area.overlaps_body(player))
	return area.overlaps_body(player)
