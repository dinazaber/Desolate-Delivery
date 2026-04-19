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
@onready var brightBar = $ScrollContainer/VBoxContainer/Brighness/HSlider

var settings

func _ready() -> void:
	
	settings = SettingsManager.settings.duplicate(true)
	uiRefresh()
	
	get_tree().root.size_changed.connect(func(): on_window_size_changed())
	

		

func setSelected(node, val) -> void:
	if node is OptionButton:
		for i in range(node.item_count):
			if node.get_item_text(i) == val:
				node.select(i)
				return
	elif node is HSlider:
		node.set("value", val)
			

func buildSettings() -> void:
	settings.video.windowed = windowBtn.button_pressed
	settings.video.vsync = vsyncBtn.button_pressed
	settings.video.anti_aliasing_enabled = antAliBtn.button_pressed
	if fps.text.is_valid_int():
		if fps.text.to_int() >= 0: settings.video.max_fps = fps.text.to_int()
	
	if width.text.is_valid_int():
		if width.text.to_int() > 0: settings.video.image_size.x = width.text.to_int()
			
	if height.text.is_valid_int():
		if height.text.to_int() > 0: settings.video.image_size.y = height.text.to_int()
	
	settings.video.brightness = brightBar.value
	
	
	print("Duplicate: " + str(settings))
	print("Config: " + str(SettingsManager.settings))
	

func isEqualToConfig() -> bool:
	for section in settings.keys():
		for key in settings[section].keys():
			if settings[section][key] != SettingsManager.settings[section][key]:
				print("aaaa")
				return false
	return true

func copyToConfig() -> void:
	for section in settings.keys():
		for key in settings[section].keys():
			SettingsManager.settings[section][key] = settings[section][key]
			
	SettingsManager.save_settings()
	SettingsManager.apply_settings()
			

func uiRefresh():
	resolution.visible = SettingsManager.settings.video.windowed
	antAliOpt.visible = SettingsManager.settings.video.anti_aliasing_enabled
	windowBtn.button_pressed = SettingsManager.settings.video.windowed
	vsyncBtn.button_pressed = SettingsManager.settings.video.vsync
	antAliBtn.button_pressed = SettingsManager.settings.video.anti_aliasing_enabled
	
	# Set width/height values to appear inside input lines of resolution settings when game launches 
	width.text = str(SettingsManager.settings.video.image_size.x)
	height.text = str(SettingsManager.settings.video.image_size.y)
	
	# Set fps clamp to appear inside input line of max fps setting
	fps.text = str(Engine.max_fps)
	
	# Set render scale to be selected
	setSelected.call_deferred(sclOpt, str(SettingsManager.settings.video.render_scale))
	
	# Set anti aliasing to be selected
	setSelected.call_deferred(antAliOpt, SettingsManager.settings.video.anti_aliasing_type)
	
	# Adjust brightness slider
	setSelected.call_deferred(brightBar, SettingsManager.settings.video.brightness)
	$ScrollContainer/VBoxContainer/Brighness/Label2.text = str(SettingsManager.settings.video.brightness)
			
		

func on_window_size_changed():
	if SettingsManager.settings.video.windowed:
		SettingsManager.settings.video.image_size = DisplayServer.window_get_size()
		width.text = str(DisplayServer.window_get_size().x)
		height.text = str(DisplayServer.window_get_size().y)
		SettingsManager.save_settings()
		

func _on_scale_option_item_selected(index: int) -> void:
	match index:
		0: settings.video.render_scale = 2.0
		1: settings.video.render_scale = 1.75
		2: settings.video.render_scale = 1.5
		3: settings.video.render_scale = 1.25
		4: settings.video.render_scale = 1.0
		5: settings.video.render_scale = 0.75
		6: settings.video.render_scale = 0.5
		7: settings.video.render_scale = 0.25
	
	
func _on_anti_aliasing_item_selected(index: int) -> void:
	match index:
		0: settings.video.anti_aliasing_type = "MSAA 8x"
		1: settings.video.anti_aliasing_type = "MSAA 4x"
		2: settings.video.anti_aliasing_type = "MSAA 2x"
		3: settings.video.anti_aliasing_type = "FXAA"
		4: settings.video.anti_aliasing_type = "SMAA"
		


func _on_apply_settings_pressed() -> void:
	buildSettings()
	copyToConfig()
	uiRefresh()
	
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape") and is_visible_in_tree():
		accept_event()
		buildSettings()
		if !isEqualToConfig():
			$Panel.show()
			$ScrollContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			_on_discard_pressed()


func _on_discard_pressed() -> void:
		settings = SettingsManager.settings.duplicate(true)
		$Panel.hide()
		uiRefresh()
		hide()
		closed.emit()


func _on_back_pressed() -> void:
	$Panel.hide()
	$ScrollContainer.mouse_filter = Control.MOUSE_FILTER_PASS


func _on_brightness_slider_value_changed(value: float) -> void:
	$ScrollContainer/VBoxContainer/Brighness/Label2.text = str(value)
	if value < 1.0:
		PostProcessLayer.get_node("Black").show()
		PostProcessLayer.get_node("White").hide()
		PostProcessLayer.get_node("Black").modulate.a = 1.0 - value
	else: 
		PostProcessLayer.get_node("White").show()
		PostProcessLayer.get_node("Black").hide()
		PostProcessLayer.get_node("White").modulate.a = value - 1.0
