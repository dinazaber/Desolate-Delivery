extends Node

const SAVE_PATH = "user://settings.cfg"
var config = ConfigFile.new()
var player
var world_enviroment: WorldEnvironment

var settings = {
	"video": {
		"max_fps": 60,
		"vsync": true,
		"render_scale": 1.0,
		"image_size_width": 1152,
		"image_size_height": 648,
		"windowed": false,
		"anti_aliasing_type": "None",
		"brightness": 1.0,
		"received_shadow_quality": "Medium",
		"glow": true
	},
	"audio": {
		"master_volume": 1.0
	},
	"controls": {
		"mouse_sensitivity": 0.005
	}#,
	#"game": {
	#} Section is empty and on new device it fails to load config
}

func _ready():
	
	load_settings()
	
	if settings.video.windowed: 
		@warning_ignore("integer_division")
		DisplayServer.window_set_position(DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2 - DisplayServer.window_get_size() / 2)
		

func isConfigValid() -> bool:
	for section in settings.keys():
		if not config.has_section(section): return false
		for key in settings[section].keys():
			if not config.has_section_key(section, key): return false
	return true
	
	
func save_settings():
	for section in settings.keys():
		for key in settings[section].keys():
			config.set_value(section, key, settings[section][key])
	config.save(SAVE_PATH)
	
func load_settings():
	var error = config.load(SAVE_PATH)
	
	if error != OK:
		print("Error! Missing config file!")
		print("Creating new config...")
		save_settings()
		return
		
	if !isConfigValid():
		print("Error! Config file isn't updated!")
		print("Creating new config...")
		save_settings()
		return
		
	for section in settings.keys():
		for key in settings[section].keys():
			settings[section][key] = config.get_value(section, key, settings[section])
	
	
func apply_settings():
	
	# Max fps
	Engine.max_fps = settings.video.max_fps
	
	# Vsync
	var vsync = DisplayServer.VSYNC_ENABLED if settings.video.vsync else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vsync)
	
	# Render Scale(3D)
	var viewport = get_tree().root
	viewport.scaling_3d_scale = settings.video.render_scale
	
	# Fullscreen/Windowed
	if settings.video.windowed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var size = Vector2(settings.video.image_size_width, settings.video.image_size_height)
		DisplayServer.window_set_size(size)
	else: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Anti Aliasing
	var string = settings.video.anti_aliasing_type
	if string != "None":
		if "MSAA" in string:
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			get_viewport().use_taa = false
			var n = string[string.length() - 2].to_int()
			match n:
				2: get_viewport().msaa_3d = Viewport.MSAA_2X
				4: get_viewport().msaa_3d = Viewport.MSAA_4X
				8: get_viewport().msaa_3d = Viewport.MSAA_8X
	
		elif "FXAA" == string:
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			get_viewport().use_taa = false
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		
		elif "SMAA" == string:
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_SMAA
			get_viewport().use_taa = false
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		
	else:
		get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		get_viewport().use_taa = false
	
	
	# Received Shadow Quality
	string = settings.video.received_shadow_quality
	var shadow_size
	var filter
	match string:
		"Ultra":
			shadow_size = 4096
			filter = RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM
			
		
		"High":
			shadow_size = 2048
			filter = RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM
		
		"Medium":
			shadow_size = 1024
			filter = RenderingServer.SHADOW_QUALITY_SOFT_LOW
		
		"Low":
			shadow_size = 512
			filter = RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW
		
		"Very Low":
			shadow_size = 256
			filter = RenderingServer.SHADOW_QUALITY_HARD
			
	RenderingServer.directional_shadow_atlas_set_size(shadow_size, false)
	RenderingServer.directional_soft_shadow_filter_set_quality(filter)
	
	# Player Parameters
	if player:
		player.cam_speed = SettingsManager.settings.controls.mouse_sensitivity
	
	if world_enviroment: world_enviroment.environment.glow_enabled = settings.video.glow
	
