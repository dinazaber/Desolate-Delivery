extends Control
signal closed

func _ready() -> void:
	
	get_tree().root.size_changed.connect(func(): on_window_size_changed())
	
	if !SettingsManager.settings.video.windowed:
		$ScrollContainer/VBoxContainer/ResolutionOption.hide()
	
	# Set fps clamp to appear inside input line of max fps setting
	$ScrollContainer/VBoxContainer/MaxFpsEdit.text = str(SettingsManager.settings.video.max_fps)
	
	# Set render scale to appear inside input line of render scale setting
	var renderScale = SettingsManager.settings.video.render_scale
	for i in range($ScrollContainer/VBoxContainer/ScaleOption.item_count):
		if $ScrollContainer/VBoxContainer/ScaleOption.get_item_text(i) == str(renderScale):
			$ScrollContainer/VBoxContainer/ScaleOption.select(i)
			break
			
	# Set width/height values to appear inside input lines of resolution settings when game launches 
	$ScrollContainer/VBoxContainer/ResolutionOption/WidthEdit.text = str(SettingsManager.settings.video.image_size.x)
	$ScrollContainer/VBoxContainer/ResolutionOption/HeightEdit.text = str(SettingsManager.settings.video.image_size.y)
	
	$ScrollContainer/VBoxContainer/WindowedOption/WindowedButton.button_pressed = SettingsManager.settings.video.windowed
	$ScrollContainer/VBoxContainer/VsyncOption/VsyncButton.button_pressed = SettingsManager.settings.video.vsync

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
	
	if renderScale != null: SettingsManager.settings.video.render_scale = renderScale
			
			
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape") and is_visible_in_tree():
		accept_event()
		hide()
		SettingsManager.save_settings()
		SettingsManager.apply_settings()
		closed.emit()



func _on_max_fps_edit_text_submitted(new_text: String) -> void:
	if new_text.is_valid_int():
		if int(new_text)>=0:
			var value = new_text.to_int()
			SettingsManager.settings.video.max_fps = value
	else: $ScrollContainer/VBoxContainer/MaxFpsEdit.text = str(Engine.max_fps)


func _on_apply_settings_pressed() -> void:
	var fpsLabel: LineEdit = $ScrollContainer/VBoxContainer/MaxFpsEdit
	var widthLabel: LineEdit = $ScrollContainer/VBoxContainer/ResolutionOption/WidthEdit
	var heightLabel: LineEdit = $ScrollContainer/VBoxContainer/ResolutionOption/HeightEdit
	var windowBtn: CheckButton = $ScrollContainer/VBoxContainer/WindowedOption/WindowedButton
	var vsyncBtn: CheckButton = $ScrollContainer/VBoxContainer/VsyncOption/VsyncButton
	
	var fps = fpsLabel.text
	var width = widthLabel.text
	var height = heightLabel.text
	
	
	SettingsManager.settings.video.windowed = windowBtn.button_pressed
	if !SettingsManager.settings.video.windowed: $ScrollContainer/VBoxContainer/ResolutionOption.hide()
	else: $ScrollContainer/VBoxContainer/ResolutionOption.show()
	SettingsManager.settings.video.vsync = vsyncBtn.button_pressed
	
	if fps.is_valid_int():
		if fps.to_int() >= 0:
			fpsLabel.text = fps
			SettingsManager.settings.video.max_fps = fps.to_int()
	
	if width.is_valid_int():
		if width.to_int() > 0:
			widthLabel.text = width
			SettingsManager.settings.video.image_size.x = width.to_int()
			
	if height.is_valid_int():
		if height.to_int() > 0:
			heightLabel.text = height
			SettingsManager.settings.video.image_size.y = height.to_int()
		
		
	SettingsManager.save_settings()
	SettingsManager.apply_settings()
	
	
func on_window_size_changed():
	if SettingsManager.settings.video.windowed:
		var widthLabel: LineEdit = $ScrollContainer/VBoxContainer/ResolutionOption/WidthEdit
		var heightLabel: LineEdit = $ScrollContainer/VBoxContainer/ResolutionOption/HeightEdit
		SettingsManager.settings.video.image_size = DisplayServer.window_get_size()
		widthLabel.text = str(DisplayServer.window_get_size().x)
		heightLabel.text = str(DisplayServer.window_get_size().y)
		SettingsManager.save_settings()
