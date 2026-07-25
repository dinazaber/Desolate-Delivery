extends ProgressBar


var def_color: Color = self.self_modulate

var beeped: bool = false
var beepawait: float = 0.1 # half of time between beeps


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if value >= 99.9:
		if !beeped:
			beeped = true
			beep()
	else:
		beeped = false

func beep() -> void:
	var tween = get_tree().create_tween()
	for i in range(0,3):
		tween.tween_property(self, "self_modulate", def_color + 0.3*Color.WHITE, beepawait)
		tween.tween_property(self, "self_modulate", def_color, beepawait)
