extends Control

@export var hud: Control
var block: bool = false

func _ready():
	$SaveMenu/Add.show()


func _unhandled_input(event: InputEvent) -> void:
	if block: return
	if event.is_action_pressed("Escape"):
		if is_visible_in_tree():
			_on_resume_pressed()
		else:
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			hud.hide()
			show()

func _on_resume_pressed() -> void:
	hide()
	get_tree().paused = false
	hud.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_settings_pressed() -> void:
	$PauseMenu.hide()
	$Settings.show()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")


func _on_settings_closed() -> void:
	$PauseMenu.show()


func _on_save_menu_pressed() -> void:
	$PauseMenu.hide()
	$SaveMenu.show()


func _on_save_menu_closed() -> void:
	$PauseMenu.show()


func _on_player_player_dead() -> void:
	block = true
