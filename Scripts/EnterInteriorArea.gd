extends Area3D
signal interiorAreaData(metaData)


func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		var meta = get_meta("Interior")
		var mesh = get_node(meta)
		emit_signal("interiorAreaData",mesh)
		
		
