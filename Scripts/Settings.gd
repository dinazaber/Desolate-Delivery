extends Control


func _on_resolution_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(3440,1440))
		1:
			DisplayServer.window_set_size(Vector2i(1920,1080))
		2:
			DisplayServer.window_set_size(Vector2i(1280,720))
			
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Escape"):
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
