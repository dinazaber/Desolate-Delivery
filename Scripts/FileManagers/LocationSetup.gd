extends Node

func _ready():
	# save files
	if !SaveManager.curSave: SaveManager.save_game("AutoSave1")
	SaveManager.load_game(SaveManager.curSave)
	
	# occulusions
	if $OccluderInstance3D: $OccluderInstance3D.visible = true
