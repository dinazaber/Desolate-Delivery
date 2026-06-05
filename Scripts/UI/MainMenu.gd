extends Control

func _ready() -> void:
	$SaveMenu/Add.hide()

func _on_start_pressed() -> void:
	var curSave = SaveManager.curSave
	print(curSave)
	if curSave: SaveManager.load_game(curSave)
	
	else:
		get_tree().change_scene_to_file("res://Scenes/Locations/Levels/Prologue.tscn")


func _on_settings_pressed() -> void:
	$MainMenu.hide()
	$Settings.show()


func _on_quit_pressed() -> void:
	get_tree().quit()
	

func _on_settings_closed() -> void:
	$MainMenu.show()


func _on_load_pressed() -> void:
	$MainMenu.hide()
	$SaveMenu.show()


func _on_save_menu_closed() -> void:
	$MainMenu.show()
