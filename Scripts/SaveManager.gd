extends Control
	
# Note: This can be called from anywhere inside the tree. This function is
# path independent.
# Go through everything in the persist category and ask them to return a
# dict of relevant variables.
func save_game():
	print("save game")
	var save_file = FileAccess.open("user://savegame.bin", FileAccess.WRITE)
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
	print("save file closed")

# Note: This can be called from anywhere inside the tree. This function
# is path independent.
func load_game():
	if not FileAccess.file_exists("user://savegame.bin"):
		print("Error! Missing save file")
		return # Error! We don't have a save to load.

	# We need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	# For our example, we will accomplish this by deleting saveable objects.
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for i in save_nodes:
		i.queue_free()

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_file = FileAccess.open("user://savegame.bin", FileAccess.READ)
	while save_file.get_position() < save_file.get_length():

		# Get the data from the JSON object.
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
