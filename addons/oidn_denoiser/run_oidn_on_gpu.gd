@tool
extends EditorPlugin

# --- CONFIGURATION ---
# Use the environment variables you set up
const MAGICK = "magick"
const OIDN = "oidnDenoise"

var context_menu_plugin: EditorContextMenuPlugin

func _enter_tree():
	# Add the custom menu option
	context_menu_plugin = EXRContextMenuPlugin.new(self)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, context_menu_plugin)
	

func _exit_tree():
	if context_menu_plugin: remove_context_menu_plugin(context_menu_plugin)

func _run_denoise_flow(paths: Array):
	if paths.is_empty(): return
	
	for path in paths:
		if path.ends_with(".exr"):
			_process_file(path)

func _process_file(godot_path: String):
	var start_time = Time.get_ticks_msec()
	
	var global_path = ProjectSettings.globalize_path(godot_path)
	var temp_pfm = OS.get_environment("TEMP") + "\\temp_lightmap.pfm"
	
	print("------------------------------------------\n")
	print("--- Starting Denoise for: ", godot_path, " ---\n")
	
	var device = _get_device()
	print("     Auto Detected OIDN Device Type: ", device, "\n")
	
	print("--- Converting .exr to .pfm format... ---")
	
	var res1 = OS.execute(MAGICK, [global_path, "-endian", "LSB", temp_pfm])
	if res1 != 0: 
		printerr("     Convertation from .exr to .pfm failed\n")
		print("------------------------------------------\n")
		return
	else: print("     Convertation from .exr to .pfm succeed!\n")
	
	print("--- Denoising... ---")
		
	var oidnArgs = ["--device", device, "--filter", "RTLightmap", "--hdr", temp_pfm, "--output", temp_pfm]
	var res2 = OS.execute(OIDN, oidnArgs)
	if res2 != 0:
		printerr("     OIDN denoising failed\n")
		print("------------------------------------------\n")
		return
	else: print("     OIDN denoising succeed!\n")
	
	print("--- Converting .pfm to .exr format... ---")
	
	var res3 = OS.execute(MAGICK, [temp_pfm, global_path])
	if res3 !=0:
		printerr("     Convertation from .pfm to .exr failed\n")
		print("------------------------------------------\n")
		return
	else: print("     Convertation from .pfm to .exr succeed!\n")
	
	print("--- Compressing... ---")
	
	var compressArgs = [global_path, "-depth", "16", "-define", "exr:color-type=RGB", "-compress", "ZIP", global_path]
	var res4 = OS.execute(MAGICK, compressArgs)
	if res4 != 0:
		printerr("     Compression failed\n")
		print("------------------------------------------\n")
		return
	else: print("     Compression succeed!\n")
	
		
	var end_time = Time.get_ticks_msec()
	var total_time = end_time - start_time
	total_time /= 1000.0
	print("--- Success! ---")
	print("     Total Time: ", total_time, " seconds\n")
	print("------------------------------------------\n")
	
	
	EditorInterface.get_resource_filesystem().scan()


func _get_device() -> String:
	var device = RenderingServer.get_video_adapter_name()
	print("     Auto Detected GPU: ", device)
	device = device.to_lower()
	if "nvidia" in device: return "cuda"
	elif "amd" in device: return "hip"
	elif "intel" in device: return "sycl"
	else: return "cpu"
	
	
#--- Helper Class: Manages The Context Menu Interaction ---

class EXRContextMenuPlugin extends EditorContextMenuPlugin:
	var main_plugin: EditorPlugin
	
	func _init(m_plugin: EditorPlugin) -> void:
		main_plugin = m_plugin
	
	func _popup_menu(paths: PackedStringArray) -> void:
		var isExr = false
		for path in paths:
			if path.ends_with(".exr"):
				isExr = true
				break
		
		if isExr:
			add_context_menu_item(
			"Denoise Lightmap",
			Callable(main_plugin, "_run_denoise_flow")
			)
