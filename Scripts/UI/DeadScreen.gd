extends Control


func _ready() -> void:
	$SaveMenu/Add.hide()

func _on_restart_pressed() -> void:
	var curSave = SaveManager.curSave
	SaveManager.load_game(curSave)


func _on_load_save_pressed() -> void:
	$VBoxContainer.hide()
	$SaveMenu.show()


func _on_settings_pressed() -> void:
	$VBoxContainer.hide()
	$Settings.show()


func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")



func _on_save_menu_closed() -> void:
	$VBoxContainer.show()


func _on_settings_closed() -> void:
	$VBoxContainer.show()


func _on_player_dead() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()
