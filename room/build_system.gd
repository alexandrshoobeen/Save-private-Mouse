extends Node2D

@export var tilemap_layer: TileMapLayer
@export var object_scene: PackedScene
@export var tile_width := 32
@export var tile_height := 16

var itemsLoad = ["res://room/ItemsResources/Bow.tres", "res://room/ItemsResources/Sword.tres"]

var preview: Node2D

func _ready() -> void:
	preview = object_scene.instantiate()
	add_child(preview)
	preview.modulate = Color(1,1,1,0.5)  # Полупрозрачный
	preview.z_index = 100

func _process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var cell = tilemap_layer.local_to_map(mouse_pos)
	var iso_pos = _cell_to_iso(cell) + Vector2(tile_width/2, 0)

	# Превью точно над тайлом
	preview.global_position = iso_pos
	preview.z_index = int(iso_pos.y)

	var can_build = _can_place(cell)
	preview.modulate = Color(0,1,0,0.5) if can_build else Color(0.011, 0.277, 1.0, 0.5)

	if Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT) and can_build:
		_place_object(iso_pos)

func _cell_to_iso(cell: Vector2i) -> Vector2:
	return Vector2(
		(cell.x - cell.y) * (tile_width / 2),
		(cell.x + cell.y) * (tile_height / 2)
	)

func _can_place(cell: Vector2i) -> bool:
	return tilemap_layer.get_cell_source_id(cell) != -1

func _place_object(pos: Vector2) -> void:
	var obj = object_scene.instantiate()
	obj.global_position = pos
	obj.z_index = int(pos.y)  # Ставим поверх тайлов
	add_child(obj)
