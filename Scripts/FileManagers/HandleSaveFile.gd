extends Node

@onready var sun = $DirectionalLight3D

func _ready():
	if !SaveManager.curSave: SaveManager.save_game("AutoSave1")
	SaveManager.load_game(SaveManager.curSave)
	
	if sun!=null: 
		var sunDir = -sun.global_transform.basis.z
		RenderingServer.global_shader_parameter_set("sun_direction", sunDir)
	
