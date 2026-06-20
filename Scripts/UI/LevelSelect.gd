extends Control

@export var parent_menu: Control

func _on_level_button_pressed(button: NodePath) -> void:
	var button_node = get_node(button)
	var level_path = button_node.get_meta("level_path")
	
	#----------------------
	#Maybe some kind of transit effect here between main menu and level scenes
	#----------------------
	
	if level_path: get_tree().change_scene_to_file(level_path)
	else: printerr("No level path found!")
	

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape") and is_visible_in_tree():
		accept_event()
		hide()
		parent_menu.show()
