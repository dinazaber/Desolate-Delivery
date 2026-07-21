extends Control

@export var parent_menu: Control

var settings

func _ready() -> void:
	
	settings = SettingsManager.settings.duplicate(true)
	SettingsManager.apply_settings()
	uiRefresh()
	
	get_tree().root.size_changed.connect(func(): on_window_size_changed())
	
# This function gets value from SettingsManager's dictionary
func update_option_ui(node) -> void:
	var section = node.get_meta("section")
	var key = node.get_meta("key")
	var val = SettingsManager.settings[section][key]
	
	if node is OptionButton:
		for i in range(node.item_count):
			if node.get_item_text(i) == str(val):
				node.select(i)
				return
				
	elif node is HSlider: node.set("value", val)
	
	elif node is LineEdit: node.text = str(val)
	
	elif node is CheckBox: node.button_pressed = val

func get_option_val(node) -> void:
	var section = node.get_meta("section")
	var key = node.get_meta("key")
	var val
	
	if node is OptionButton:
		var i = node.selected
		val = node.get_item_text(i)
		if val.is_valid_float(): val = val.to_float()
				
	elif node is HSlider: val = node.value
	
	elif node is LineEdit:
		if node.text.is_valid_int():
			if node.text.to_int() >= 0: val = node.text.to_int()
			else:
				node.text = "0"
				val = node.text.to_int()
		else: 
			node.text = "0"
			val = node.text.to_int()
	
	elif node is CheckBox: val = node.button_pressed
	
	settings[section][key] = val
			
func buildSettings() -> void:
	var nodes = get_tree().get_nodes_in_group("UpdatedNodes")
	for node in nodes:
		get_option_val(node)

func isEqualToConfig() -> bool:
	for section in settings.keys():
		for key in settings[section].keys():
			if settings[section][key] != SettingsManager.settings[section][key]: return false
	return true

func copyToConfig() -> void:
	for section in settings.keys():
		for key in settings[section].keys():
			SettingsManager.settings[section][key] = settings[section][key]
			
	SettingsManager.save_settings()
			
func uiRefresh():
	for node in get_tree().get_nodes_in_group("UpdatedNodes"):
		update_option_ui(node)
		
func _on_apply_settings_pressed() -> void:
	buildSettings()
	copyToConfig()
	SettingsManager.apply_settings()
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

func on_window_size_changed():
	if SettingsManager.settings.video.windowed:
		$ScrollContainer/VBoxContainer/Resolution/WidthEdit.text = str(DisplayServer.window_get_size().x)
		$ScrollContainer/VBoxContainer/Resolution/HeightEdit.text = str(DisplayServer.window_get_size().y)

func _on_discard_pressed() -> void:
		settings = SettingsManager.settings.duplicate(true)
		$Panel.hide()
		uiRefresh()
		SettingsManager.apply_settings()
		hide()
		parent_menu.show()

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

func _on_mousSens_slider_value_changed(value: float) -> void:
	$ScrollContainer/VBoxContainer/MouseSens/Label2.text = str(value)
