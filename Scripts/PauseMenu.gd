extends Control

func _unhandled_input(event: InputEvent) -> void:

	if event.is_action_pressed("Escape"):
		if is_visible_in_tree():
			_on_resume_pressed()
		else:
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			show()

func _on_resume_pressed() -> void:
	hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_settings_pressed() -> void:
	$PauseMenu.hide()
	$Settings.show()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_settings_closed() -> void:
	$PauseMenu.show()
