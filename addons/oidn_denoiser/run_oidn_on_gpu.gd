@tool
extends EditorPlugin

# --- CONFIGURATION ---
# Use the environment variables you set up
const MAGICK_EXE = "magick" 
const OIDN_EXE = "oidnDenoise"

var file_system_dock: FileSystemDock

func _enter_tree():
	file_system_dock = get_editor_interface().get_file_system_dock()
	# Add the custom menu option
	add_tool_menu_item("Denoise Lightmap", _run_denoise_flow)
	

func _exit_tree():
	remove_tool_menu_item("Denoise Lightmap")

func _run_denoise_flow():
	var paths = get_editor_interface().get_selected_paths()
	if paths.is_empty(): return
	
	for path in paths:
		if path.ends_with(".exr"):
			_process_file(path)

func _process_file(godot_path: String):
	var start_time = Time.get_ticks_msec()
	
	var global_path = ProjectSettings.globalize_path(godot_path)
	var temp_pfm = OS.get_environment("TEMP") + "\\temp_lightmap.pfm"
	
	print("--- Starting Denoise for: ", godot_path, " ---")
	
	var cmd_chain = "magick \"{in}\" -endian LSB \"{tmp}\" && " + \
					"oidnDenoise --device cuda --filter RTLightmap --hdr \"{tmp}\" --output \"{tmp}\" && " + \
					"magick \"{tmp}\" \"{in}\""
	
	var final_command = cmd_chain.format({
		"in": global_path,
		"tmp": temp_pfm
	})
	
	var device = _get_device()
	print("Auto Detected OIDN Device Type: ", device)
	
	print("--- Denoising... ---")
	
	var cmd_output = []
	var exit_code = OS.execute("cmd.exe", ["/c", final_command], cmd_output, true)
	
	if exit_code == 0:
		var end_time = Time.get_ticks_msec()
		var total_time = end_time - start_time
		total_time /= 1000.0
		print("--- Success! ---")
		print("Total Time: ", total_time, " seconds")
	
	else:
		printerr("Execution failed with exit code: ", exit_code)
		if not cmd_output.is_empty(): print("Error Details: ", cmd_output[0])
	
	EditorInterface.get_resource_filesystem().scan()


func _get_device() -> String:
	var device = RenderingServer.get_video_adapter_name()
	print("Auto Detected GPU: ", device)
	device = device.to_lower()
	if "nvidia" in device: return "cuda"
	elif "amd" in device: return "hip"
	elif "intel" in device: return "sycl"
	else: return "cpu"
