extends Node

func _ready():
	SaveManager.load_game(SaveManager.curSave)
	
