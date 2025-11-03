extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Запускаем анимацию при загрузке сцены
	animation_player.play("catscene_two")
	# Подключаемся к сигналу окончания анимации
	animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: String):
	if anim_name == "catscene_two":
		# Когда анимация catscene_two закончилась, переходим на blocks
		get_tree().change_scene_to_file("res://room/blocks.tscn")

