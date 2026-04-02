extends Control

const SAVEDIR = "user://saves/" #Folder with all save files
var curSave: String

#The methods can be called from every script using global variable SaveManager

func _ready() -> void:
	# Create the folder if it doesn't exist
	if not DirAccess.dir_exists_absolute(SAVEDIR):
		DirAccess.make_dir_absolute(SAVEDIR)

func save_game(slotName: String):
	var path = SAVEDIR + slotName + ".bin"
	var save_file = FileAccess.open(path, FileAccess.WRITE)
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for node in save_nodes:
		# Check the node is an instanced scene so it can be instanced again during load.
		if node.scene_file_path.is_empty() or !node.has_method("save"):
			print("skipped" + node.name)
			continue

		# Call the node's save function.
		var node_data = node.save()

		# Store the save dictionary as a new line in the save file.
		save_file.store_var(node_data)
		
		
	save_file.close()
	print("Saved to: "+path)

# Note: This can be called from anywhere inside the tree. This function
# is path independent.
func load_game(slotName: String):
	var path = SAVEDIR + slotName + ".bin"
	if not FileAccess.file_exists(path):
		print("Error! Missing save file")
		return # Error! We don't have a save to load.
		
	curSave = slotName
	get_tree().paused = false

	# Remove original objects from Persist group to avoid duplicates
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for i in save_nodes:
		i.queue_free()

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_file = FileAccess.open(path, FileAccess.READ)
	var targetLevel = save_file.get_var()["level_scene"]
	save_file.seek(0)
	
	if get_tree().current_scene.scene_file_path != targetLevel:
		get_tree().change_scene_to_file(targetLevel)
		return
	
	while save_file.get_position() < save_file.get_length():

		# Get the data
		var node_data = save_file.get_var()

		# Firstly, we need to create the object and add it to the tree and set its position.
		var new_object = load(node_data["filename"]).instantiate()
		get_node(node_data["parent"]).add_child(new_object)
		new_object.global_transform = node_data["transform"]

		# Now we set the remaining variables.
		for key in node_data.keys():
			if key in ["filename", "parent", "transform"]:
				continue
			new_object.set(key, node_data[key])
			
	save_file.close()
	
			
			
func delete_game(slotName: String):
	var path = SAVEDIR + slotName + ".bin"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("Deleted: " + path)
	
