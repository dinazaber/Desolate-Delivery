@tool #Changing door mesh in the future
extends Node3D

@onready var anim: AnimationPlayer = $AnimationPlayer
var isOpen: bool = false
var type = "Door"

func _ready() -> void:
	anim.play("RESET")
	isOpen = false

func open():
	if !isOpen:
		anim.play("Open")
		await anim.animation_finished
		isOpen = true
	

func close():
	if isOpen:
		anim.play("Close")
		await anim.animation_finished
		isOpen = false

func getOpenStatus(): return isOpen

func getType(): return type
