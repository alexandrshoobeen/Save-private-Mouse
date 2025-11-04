extends Node2D

func has_item(item_name: String) -> bool:
	for item in Global.inventory_data:
		if item.name == item_name:
			return true
	return false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var should_disable = has_item("Candy")

	# Hide the pickup area
	self.visible = not should_disable

	# Disable the collision shape inside this Area2D
	var collision = $CollisionShape2D
	if collision:
		collision.disabled = should_disable
	pass # Replace with function body.
