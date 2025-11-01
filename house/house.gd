extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var hero_mouse_scene = preload("res://heroMouse/hero_mouse.tscn")
	var hero_mouse = hero_mouse_scene.instantiate()
	add_child(hero_mouse)
