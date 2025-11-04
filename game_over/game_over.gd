extends Control

@onready var restart_button = $VBoxContainer/RestartButton
@onready var exit_button = $VBoxContainer/ExitButton

func _ready():
	restart_button.pressed.connect(_on_restart_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)

func _on_restart_button_pressed():
	# Restart game from the beginning (catscene_one)
	get_tree().change_scene_to_file("res://catscenes/catscene_one.tscn")

func _on_exit_button_pressed():
	get_tree().quit()

