extends Node

@onready var player = $Player
var spawn_room = null

func _ready():
	# save files
	if !SaveManager.curSave: SaveManager.save_game("AutoSave1")
	SaveManager.load_game(SaveManager.curSave)
	
	# occulusions
	if $OccluderInstance3D: $OccluderInstance3D.visible = true
	
	

func _physics_process(_delta: float) -> void:
	if spawn_room: return
	show_spawn_room_only()
	


func show_spawn_room_only():
	var rooms = $Rooms
	for room in rooms.get_children():
		if room is GameRoom:
			print(room) 
			room.hide_room()
		
			if !spawn_room and room.player_inside(): spawn_room = room
	
	if spawn_room: spawn_room.show_room()
