extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Запускаем анимацию при загрузке сцены
	animation_player.play("open_scene_one")
	# Подключаемся к сигналу окончания анимации
	animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: String):
	if anim_name == "open_scene_one":
		# Когда анимация open_scene_one закончилась, переходим на catscene_two
		get_tree().change_scene_to_file("res://catscenes/catscene_two.tscn")

