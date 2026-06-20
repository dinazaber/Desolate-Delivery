extends Control


func _on_restart_pressed() -> void:
	print("Should add chekpoints first!")


func _on_settings_pressed() -> void:
	$VBoxContainer.hide()
	$Settings.show()


func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")


func _on_player_dead() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()
