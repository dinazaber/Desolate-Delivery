class_name GameRoom
extends Node3D

@onready var area = $PlayerDetectionArea

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)

func hide_room(): hide()

func show_room(): show()

func player_inside(): 
	var player = get_tree().get_first_node_in_group("Player")
	print(area.overlaps_body(player))
	return area.overlaps_body(player)
	
	
func _on_body_entered(body):
	var player = get_tree().get_first_node_in_group("Player")
	if body == player:
		print("Saved current room is: ", player.current_room) 
		print("Current room is: ", self.name)
		player.current_room = self.name
