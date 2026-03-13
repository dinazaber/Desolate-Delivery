extends Control
signal closed

func _on_resolution_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(3440,1440))
		1:
			DisplayServer.window_set_size(Vector2i(1920,1080))
		2:
			DisplayServer.window_set_size(Vector2i(1280,720))
			
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape"):
		hide()
		closed.emit()
