extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Start final_anim animation when scene loads
	if animation_player:
		animation_player.play("final_anim")
		print("[FINAL] ✅ Final animation 'final_anim' started")
	else:
		print("[FINAL] ⚠️ AnimationPlayer not found in final scene")

