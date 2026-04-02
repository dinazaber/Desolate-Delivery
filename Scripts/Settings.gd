extends Control
signal closed

@onready var sclOpt = $ScrollContainer/VBoxContainer/Scale/ScaleOption
@onready var antAliOpt = $ScrollContainer/VBoxContainer/AntiAliasing/AntAliOp
@onready var antAliBtn = $ScrollContainer/VBoxContainer/AntiAliasing/CheckButton
@onready var width = $ScrollContainer/VBoxContainer/Resolution/WidthEdit
@onready var height = $ScrollContainer/VBoxContainer/Resolution/HeightEdit
@onready var resolution = $ScrollContainer/VBoxContainer/Resolution
@onready var fps = $ScrollContainer/VBoxContainer/Fps/MaxFpsEdit
@onready var windowBtn = $ScrollContainer/VBoxContainer/Window/CheckButton
@onready var vsyncBtn = $ScrollContainer/VBoxContainer/Vsync/CheckNutton

func _ready() -> void:
	
	get_tree().root.size_changed.connect(func(): on_window_size_changed())
	
	if !SettingsManager.settings.video.windowed: resolution.hide()
	
	# Set fps clamp to appear inside input line of max fps setting
	fps.text = str(SettingsManager.settings.video.max_fps)
	
	# Set render scale to be selected
	var renderScale = SettingsManager.settings.video.render_scale
	setSelected(sclOpt, str(renderScale))
	
	# Set anti aliasing to be selected
	var antAli = SettingsManager.settings.video.anti_aliasing
	if antAli == "None":
		antAliBtn.button_pressed = false
		antAliOpt.hide()
	else:
		setSelected(antAliOpt, antAli)
		antAliBtn.button_pressed = true
			
	# Set width/height values to appear inside input lines of resolution settings when game launches 
	width.text = str(SettingsManager.settings.video.image_size.x)
	height.text = str(SettingsManager.settings.video.image_size.y)
	
	windowBtn.button_pressed = SettingsManager.settings.video.windowed
	vsyncBtn.button_pressed = SettingsManager.settings.video.vsync

		

func setSelected(node: OptionButton, val: String):
	for i in range(node.item_count):
		if node.get_item_text(i) == val:
			node.select(i)
			return
		

func on_window_size_changed():
	if SettingsManager.settings.video.windowed:
		SettingsManager.settings.video.image_size = DisplayServer.window_get_size()
		width.text = str(DisplayServer.window_get_size().x)
		height.text = str(DisplayServer.window_get_size().y)
		SettingsManager.save_settings()
		

func _on_scale_option_item_selected(index: int) -> void:
	match index:
		0: SettingsManager.settings.video.render_scale = 2.0
		1: SettingsManager.settings.video.render_scale = 1.75
		2: SettingsManager.settings.video.render_scale = 1.5
		3: SettingsManager.settings.video.render_scale = 1.25
		4: SettingsManager.settings.video.render_scale = 1.0
		5: SettingsManager.settings.video.render_scale = 0.75
		6: SettingsManager.settings.video.render_scale = 0.5
		7: SettingsManager.settings.video.render_scale = 0.25
	
	
func _on_anti_aliasing_item_selected(index: int) -> void:
	match index:
		0: SettingsManager.settings.video.anti_aliasing = "MSAA X8"
		1: SettingsManager.settings.video.anti_aliasing = "MSAA X4"
		2: SettingsManager.settings.video.anti_aliasing = "MSAA X2"
		3: SettingsManager.settings.video.anti_aliasing = "FXAA"
		4: SettingsManager.settings.video.anti_aliasing = "SMAA"
			


func _on_apply_settings_pressed() -> void:
	
	SettingsManager.settings.video.windowed = windowBtn.button_pressed
	resolution.visible = SettingsManager.settings.video.windowed
	SettingsManager.settings.video.vsync = vsyncBtn.button_pressed
	
	if !antAliBtn.button_pressed:
		SettingsManager.settings.video.anti_aliasing = "None"
		antAliOpt.hide()
	else:
		if SettingsManager.settings.video.anti_aliasing == "None":
			antAliOpt.show()
			SettingsManager.settings.video.anti_aliasing = "FXAA"
			setSelected(antAliOpt, SettingsManager.settings.video.anti_aliasing)
		else: setSelected(antAliOpt, SettingsManager.settings.video.anti_aliasing)
	
	if fps.text.is_valid_int():
		if fps.text.to_int() >= 0:
			SettingsManager.settings.video.max_fps = fps.text.to_int()
	
	if width.text.is_valid_int():
		if width.text.to_int() > 0:
			SettingsManager.settings.video.image_size.x = width.text.to_int()
			
	if height.text.is_valid_int():
		if height.text.to_int() > 0:
			SettingsManager.settings.video.image_size.y = height.text.to_int()
		
		
	SettingsManager.save_settings()
	SettingsManager.apply_settings()
	
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape") and is_visible_in_tree():
		accept_event()
		hide()
		SettingsManager.save_settings()
		SettingsManager.apply_settings()
		closed.emit()
