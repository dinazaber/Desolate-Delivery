extends Node

@onready var player = $Player
@export var first_room: Node3D #Place here starting room of the level
var spawn_room = null

func _ready():
	# save files
	if !SaveManager.curSave:
		player.current_room = first_room.name 
		SaveManager.save_game("AutoSave1")
		
	await SaveManager.load_game(SaveManager.curSave)
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("Player")
	print("On start curent room: ", player.current_room)
	
	# occulusions
	if $OccluderInstance3D: $OccluderInstance3D.visible = true
	
	show_spawn_room_only()
	


func show_spawn_room_only():
	var rooms = $Rooms
	for room in rooms.get_children():
		if room.name == player.current_room:
			room.show()
			continue
		room.hide_room()
		print(room.name)
		
