extends Node2D

@export var tilemap_layer: TileMapLayer       # Your TileMapLayer node
@export var tile_width: int = 128
@export var tile_height: int = 74

var preview: Sprite2D = null
var current_item_data: ItemData = null

const ACTION_PLACE := "mouse_left"
const ACTION_CANCEL := "ui_cancel"

# ------------------- Drag start -------------------
func start_preview(item_data: ItemData) -> void:
	print('StartPreview');
	current_item_data = item_data
	if preview:
		preview.queue_free()
	preview = Sprite2D.new()
	preview.texture = item_data.texture
	preview.modulate = Color(1,1,1,0.5)
	#preview.centered = true
	add_child(preview)
	preview.z_index = 10000

# ------------------- Process preview -------------------
func _process(_delta: float) -> void:
	if not preview or not current_item_data or not tilemap_layer:
		return

	var local_mouse = tilemap_layer.to_local(get_global_mouse_position())
	var cell = tilemap_layer.local_to_map(local_mouse)
	var iso_pos = _cell_to_iso(cell) + Vector2(current_item_data.width/2, current_item_data.height / 2)
	
	print(cell, 'CELL')

	preview.global_position = tilemap_layer.to_global(iso_pos)
	preview.z_index = int(preview.global_position.y)

	var can_place = _can_place(cell)
	preview.modulate = Color(0,1,0,0.5) if can_place else Color(1,0,0,0.5)

	if can_place and Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT):
		_place_object(cell)
		_stop_preview()

	if Input.is_action_just_pressed(ACTION_CANCEL) or Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_RIGHT):
		_stop_preview()

# ------------------- Check placement -------------------	
func _can_place(cell: Vector2i) -> bool:
	var size = current_item_data.size  # e.g. Vector2i(width, height)
	
	for y in range(size.y):
		for x in range(size.x):
			var offset = Vector2i(x + 1, y if size.y > 1 else y + 1)
			var check_cell = cell + offset
			print(check_cell, "CHECK CELL")
			
			var cell_source_exists = tilemap_layer.get_cell_source_id(check_cell) != -1
			if not cell_source_exists:
				return false
				
	return true


# ------------------- Place object -------------------
func _place_object(cell: Vector2i) -> void:
	if not current_item_data or not tilemap_layer:
		return

	var obj = Sprite2D.new()
	obj.texture = current_item_data.texture
	var iso_pos = _cell_to_iso(cell) + Vector2(current_item_data.width/2, current_item_data.height/2)
	obj.global_position = tilemap_layer.to_global(iso_pos)
	obj.z_index = int(obj.global_position.y)
	add_child(obj)

# ------------------- Stop preview -------------------
func _stop_preview() -> void:
	if preview:
		preview.queue_free()
	preview = null
	current_item_data = null

# ------------------- Helper: cell → isometric coordinates -------------------
func _cell_to_iso(cell: Vector2i) -> Vector2:
	var x = (cell.x - cell.y) * (tile_width / 2)
	var y = (cell.x + cell.y) * (tile_height / 2)
	return Vector2(x, y)
