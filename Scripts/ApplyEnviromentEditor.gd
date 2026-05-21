@tool
extends EditorScript

# PATH TO YOUR ENVIRONMENT RESOURCE
const ENV_PATH = "res://assets/Enviroment.tres"

func _run():
	if not ResourceLoader.exists(ENV_PATH):
		printerr("Editor Environment Loader: Cannot find resource at ", ENV_PATH)
		return
		
	var target_env = load(ENV_PATH)
	
	var editor_interface = EditorInterface.get_editor_viewport_3d()
	
	if editor_interface:
		_apply_environment_to_children(editor_interface, target_env)
		print("Editor Environment Loader: Successfully applied glow environment to editor viewport!")

func _apply_environment_to_children(node: Node, custom_env: Environment):
	if node.get_class() == "SubViewport":
		var vp = node as SubViewport
		if vp.world_3d:
			vp.world_3d.fallback_environment = custom_env
	
	for child in node.get_children():
		_apply_environment_to_children(child, custom_env)
