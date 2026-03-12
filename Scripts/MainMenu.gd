extends Control

const scene = preload("res://Scenes/test.tscn")
const settings = preload("res://Scenes/Settings.tscn")

func _on_start_pressed() -> void:
	get_tree().change_scene_to_packed(scene)


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_packed(settings)


func _on_quit_pressed() -> void:
	get_tree().quit()
