extends Node

@onready var player = $Player
@export var check_point_room: Node3D #Place here starting room of the level

func _ready():

	# occulusions
	if $OccluderInstance3D: $OccluderInstance3D.visible = true
	
	if $Rooms: show_check_point_room_only()
	
	SettingsManager.world_enviroment = $WorldEnvironment
	$WorldEnvironment.environment.glow_enabled = SettingsManager.settings.video.glow
	
	


func show_check_point_room_only():
	var rooms = $Rooms
	for room in rooms.get_children():
		if room.name != check_point_room.name: room.hide()
		
