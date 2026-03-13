extends Control

const scene = preload("res://Scenes/test.tscn")

func _on_start_pressed() -> void:
	get_tree().change_scene_to_packed(scene)


func _on_settings_pressed() -> void:
	$MainMenu.hide()
	$Settings.show()


func _on_quit_pressed() -> void:
	get_tree().quit()
	

func _on_settings_closed() -> void:
	$MainMenu.show()
