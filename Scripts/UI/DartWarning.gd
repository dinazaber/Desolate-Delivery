extends Control


@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer


var is_showing: bool = false


func _ready() -> void:
	anim.animation_set_next("fade", "inline")


func start() -> void:
	timer.start()
	if !is_showing:
		anim.play("fade")
	is_showing = true

func _on_timer_timeout() -> void:
	anim.play_backwards("fade")
	await anim.animation_finished
	is_showing = false
