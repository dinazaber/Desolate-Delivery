extends Control
signal closed

func _on_resolution_item_selected(index: int) -> void:
	var viewport = get_tree().root
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	match index:
		0:
			viewport.scaling_3d_scale = 2
		1:
			viewport.scaling_3d_scale = 1.75
		2:
			viewport.scaling_3d_scale = 1.5
		3:
			viewport.scaling_3d_scale = 1.25
		4:
			viewport.scaling_3d_scale = 1
		5:
			viewport.scaling_3d_scale = 0.75
		6:
			viewport.scaling_3d_scale = 0.5
			
			
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape") and is_visible_in_tree():
		accept_event()
		hide()
		closed.emit()
