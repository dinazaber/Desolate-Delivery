extends Node

const SAVE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

var settings = {
	"video": {
		"max_fps": 60,
		"vsync": false,
		"render_scale": 1.0
	},
	"audio": {
		"master_volume": 1.0
	}
}

func _ready():
	# Set screen resolution as window resolution(should fix black bars)
	var screenSize = DisplayServer.screen_get_size()
	DisplayServer.window_set_size(screenSize)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	load_settings()
	
	
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
	var renderScale: float = settings.video.render_scale
	viewport.scaling_3d_scale = renderScale
	 
		
