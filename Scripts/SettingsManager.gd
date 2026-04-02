extends Node

const SAVE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

var settings = {
	"video": {
		"max_fps": 60,
		"vsync": false,
		"render_scale": 1.0,
		"image_size": DisplayServer.screen_get_size(),
		"windowed": false
	},
	"audio": {
		"master_volume": 1.0
	}
}

func _ready():
	
	#save_settings() # When you add parameters to config, remove the hash. After first launch, return the hash.
	
	load_settings()
	
	if settings.video.windowed: 
		@warning_ignore("integer_division")
		DisplayServer.window_set_position(DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2 - DisplayServer.window_get_size() / 2)
	
	
func save_settings():
	for section in settings.keys():
		for key in settings[section].keys():
			config.set_value(section, key, settings[section][key])
	config.save(SAVE_PATH)
	
func load_settings():
	var error = config.load(SAVE_PATH)
	
	if error != OK:
		print("Error! Missing config file!")
		save_settings()
		return
		
	for section in settings.keys():
		for key in settings[section].keys():
			settings[section][key] = config.get_value(section, key, settings[section])
	
	apply_settings()
	
func apply_settings():
	Engine.max_fps = settings.video.max_fps
	
	var vsync = DisplayServer.VSYNC_ENABLED if settings.video.vsync else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vsync)
	
	var viewport = get_tree().root
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR 
	viewport.scaling_3d_scale = settings.video.render_scale
	
	
	if settings.video.windowed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(settings.video.image_size)
	
	else: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	 
		
