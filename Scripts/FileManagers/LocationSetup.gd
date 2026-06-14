extends Node

@onready var player = $Player
@export var check_point_room: Node3D #Place here starting room of the level

func _ready():
	# save files
	if !SaveManager.curSave: SaveManager.save_game("AutoSave1")
		
	#await SaveManager.load_game(SaveManager.curSave)
	
	# occulusions
	if $OccluderInstance3D: $OccluderInstance3D.visible = true
	
	if $Rooms: show_spawn_room_only()
	


func show_spawn_room_only():
	var rooms = $Rooms
	for room in rooms.get_children():
		if room.name != check_point_room.name: room.hide()
		
