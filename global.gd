extends Node


# Inventory items: array of dictionaries {name, id, texture_path, size, description}
var inventory_data: Array = []

# Placed objects: array of dictionaries {item_name, item_id, cell, size, texture_path}
var placed_objects: Array = []

var current_inv_item: String

# Track if trash falling animation has been played
var trash_falling_completed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
