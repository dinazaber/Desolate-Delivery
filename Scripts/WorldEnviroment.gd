@tool
extends WorldEnvironment

@export var editor_fog: bool = true:
	set(value):
		editor_fog = value
		environment.fog_enabled = editor_fog

func _ready():
	if not Engine.is_editor_hint():
		# Always enable fog when the actual game starts
		environment.fog_enabled = true
