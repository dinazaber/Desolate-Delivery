extends Control
signal closed

@onready var nameInput = $LineEdit
@onready var saveList = $ScrollContainer/VBoxContainer

func _ready():
	refresh_list()
	


func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text != "":
		SaveManager.save_game(new_text)
		nameInput.clear()
		nameInput.hide()
		refresh_list()

func _on_save_pressed() -> void:
	nameInput.show()
		
func refresh_list():
	for i in saveList.get_children():
		i.queue_free()
	
	var dir = DirAccess.open(SaveManager.SAVEDIR)
	if dir:
		dir.list_dir_begin()
		var fileName = dir.get_next()
		
		while fileName != "":
			if not dir.current_is_dir() and fileName.ends_with(".bin"):
				create_save_row(fileName.replace(".bin", ""))
			fileName = dir.get_next()
			
func create_save_row(displayName: String):
	var hBox = HBoxContainer.new()
	
	var loadBtn = Button.new()
	loadBtn.text = "LOAD: " + displayName
	loadBtn.pressed.connect(func(): SaveManager.load_game(displayName))
	loadBtn.custom_minimum_size = Vector2(100, 40)
	loadBtn.add_theme_font_size_override("font_size", 15)
	loadBtn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var delBtn = Button.new()
	delBtn.text = "X"
	delBtn.modulate = Color.RED
	delBtn.pressed.connect(func(): 
		SaveManager.delete_game(displayName)
		refresh_list())
	
	
	hBox.add_child(loadBtn)
	hBox.add_child(delBtn)
	saveList.add_child(hBox)
	

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape") and is_visible_in_tree():
		accept_event()
		hide()
		nameInput.clear()
		nameInput.hide()
		closed.emit()
	
		
