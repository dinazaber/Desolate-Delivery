extends Control

@onready var fpsLabel = $VBoxContainer/FPS
@onready var drawCallsLabel = $VBoxContainer/DrawCalls
@onready var vramLabel = $VBoxContainer/VRAM

func _process(_delta: float) -> void:
	var fps = Engine.get_frames_per_second()
	fpsLabel.text = "FPS: " + str(fps)
	
	var drawCalls = Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME
	drawCalls = Performance.get_monitor(drawCalls)
	drawCallsLabel.text = "Draw Calls: " + str(drawCalls)
	
	var tex_mem = Performance.RENDER_TEXTURE_MEM_USED
	tex_mem = Performance.get_monitor(tex_mem)
	
	var buf_mem = Performance.RENDER_BUFFER_MEM_USED
	buf_mem = Performance.get_monitor(buf_mem)
	var vram = tex_mem + buf_mem
	vram = vram / pow(1024,2) as int
	vramLabel.text = "VRAM: " + str(vram) + "MB"
	
