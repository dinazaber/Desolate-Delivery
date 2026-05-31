extends Node

func _ready():
	if !SaveManager.curSave: SaveManager.save_game("AutoSave1")
	SaveManager.load_game(SaveManager.curSave)
	
	
	
	
