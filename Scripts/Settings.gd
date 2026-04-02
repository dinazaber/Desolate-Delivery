extends Control
signal closed

@export var selectedTexture: Texture2D

func _ready() -> void:
	$MarginContainer/VBoxContainer/MaxFpsEdit.text = str(SettingsManager.settings.video.max_fps)
	var renderScale = SettingsManager.settings.video.render_scale
	for i in range($MarginContainer/VBoxContainer/ResolutionOption.item_count):
		if $MarginContainer/VBoxContainer/ResolutionOption.get_item_text(i) == str(renderScale):
			$MarginContainer/VBoxContainer/ResolutionOption.select(i)
			break
	

func _on_resolution_item_selected(index: int) -> void:
	var renderScale
	match index:
		0:
			renderScale = 2.0
		1:
			renderScale = 1.75
		2:
			renderScale = 1.5
		3:
			renderScale = 1.25
		4:
			renderScale = 1.0
		5:
			renderScale = 0.75
		6:
			renderScale = 0.5
		7:
			renderScale = 0.25
	
	if renderScale != null:
		SettingsManager.settings.video.render_scale = renderScale
	
	SettingsManager.save_settings()
	SettingsManager.apply_settings()
			
			
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape") and is_visible_in_tree():
		accept_event()
		hide()
		closed.emit()



func _on_max_fps_edit_text_submitted(new_text: String) -> void:
	if new_text.is_valid_int():
		var value = new_text.to_int()
		SettingsManager.settings.video.max_fps = value
		SettingsManager.save_settings()
		SettingsManager.apply_settings()
	else: $MarginContainer/VBoxContainer/MaxFpsEdit.text = str(Engine.max_fps)
