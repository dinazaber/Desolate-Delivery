extends Control

@onready var fpsLabel = $VBoxContainer/FPS
@onready var drawCallsLabel = $VBoxContainer/DrawCalls

func _process(delta: float) -> void:
	var fps = Engine.get_frames_per_second()
	fpsLabel.text = "FPS: " + str(fps)
	var drawCalls = Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME
	drawCalls = Performance.get_monitor(drawCalls)
	drawCallsLabel.text = "Draw Calls: " + str(drawCalls)
