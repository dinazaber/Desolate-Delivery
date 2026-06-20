extends Control


func _on_settings_pressed() -> void:
	$MainMenu.hide()
	$Settings.show()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_levels_pressed() -> void:
	$MainMenu.hide()
	$LevelSelect.show()
