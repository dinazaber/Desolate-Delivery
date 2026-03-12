extends Control

const scene = preload("res://Scenes/test.tscn")


func _on_start_pressed() -> void:
	get_tree().change_scene_to_packed(scene)


func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
