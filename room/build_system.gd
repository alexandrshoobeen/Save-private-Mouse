extends Node2D

@export var tilemap_layer: TileMapLayer       # Your TileMapLayer node
@export var tile_width: int = 128
@export var tile_height: int = 74

var pickup_sound = preload("res://sound/My-Song-5.mp3")

var preview: Sprite2D = null
var current_item_data: ItemData = null

var can_click_preview: bool = false
var _click_delay_timer: Timer = null

var occupied_cells := {}

const ACTION_PLACE := "mouse_left"
const ACTION_CANCEL := "ui_cancel"

func _ready():
	rebuild_placed_object()
	_set_candle_occupied_cells()
	
func _set_candle_occupied_cells() -> void:
	set_cell_occupied(Vector2(10, 1), true)
	set_cell_occupied(Vector2(9, 1), true)
	set_cell_occupied(Vector2(10, 0), true)
	set_cell_occupied(Vector2(9, 0), true)
	
func get_iso_z_index(pos: Vector2) -> int:
	# Compute z_index
	return pos.y
	
		
func rebuild_placed_object() -> void:
	# Rebuild placed objects
	for obj_dict in Global.placed_objects:
		
		# Reconstruct ItemData
		var item_data = ItemData.new()
		item_data.name = obj_dict["item_name"]
		item_data.texture = load(obj_dict["texture_path"])
		item_data.size = obj_dict["size"]
		item_data.width = obj_dict["width"]
		item_data.height = obj_dict["height"]
		item_data.description = obj_dict.get("description", "")
		item_data.z_size = obj_dict["z_size"]
		item_data.sound = obj_dict["sound"]
	
		var cell: Vector2i = obj_dict["cell"]
		var area := Area2D.new()
		add_child(area)

		var obj := Sprite2D.new()
		obj.texture = load(obj_dict["texture_path"])
		obj.set_meta("item_data", item_data)
		obj.set_meta("cell", cell)
		area.add_child(obj)

		var shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = Vector2(obj_dict.width/2, obj_dict.height/2)
		shape.shape = rect_shape
		area.add_child(shape)

		area.connect("input_event", Callable(self, "_on_object_clicked").bind(area))
		area.connect("mouse_entered", Callable(self, "_on_object_hover_enter").bind(area))
		area.connect("mouse_exited", Callable(self, "_on_object_hover_exit").bind(area))

		var iso_pos = _cell_to_iso(cell) + Vector2(obj_dict.width / 2, obj_dict.height / 2)
		area.global_position = tilemap_layer.to_global(iso_pos)
		#obj.z_index = int(obj.global_position.y - obj_dict.height / 2)
		
		var size = obj_dict.size
		var c = get_check_cell(cell, size.x-1, size.y-1, size, obj_dict.z_size)
		obj.z_index = get_iso_z_index(c)
		
				# ------------------- FIX -------------------
		# Mark the cells occupied
		for y in range(item_data.size.y):
			for x in range(item_data.size.x):
				var occupied_cell = get_check_cell(cell, x, y,item_data.size, item_data.z_size)
				set_cell_occupied(occupied_cell, true)
		# ------------------- END FIX -------------------

# ------------------- Drag start -------------------
func start_preview(item_data: ItemData) -> void:
	print('StartPreview');
	play_sound(pickup_sound)
	current_item_data = item_data
	if preview:
		preview.queue_free()
	preview = Sprite2D.new()
	preview.texture = item_data.texture
	preview.modulate = Color(1,1,1,0.5)
	#preview.centered = true
	add_child(preview)
	preview.z_index = 100
	preview.z_as_relative = true
	
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	
		# Disable clicks initially
	can_click_preview = false

	# ✅ Start timer to enable clicks
	if not _click_delay_timer:
		_click_delay_timer = Timer.new()
		add_child(_click_delay_timer)
	_click_delay_timer.wait_time = 0.2  # delay in seconds
	_click_delay_timer.one_shot = true
	_click_delay_timer.start()
	_click_delay_timer.timeout.connect(_on_click_delay_timeout)
	
func _on_click_delay_timeout() -> void:
	can_click_preview = true
	print("Preview ready for clicks")


# ------------------- Process preview -------------------
func _process(_delta: float) -> void:
	if not preview or not current_item_data or not tilemap_layer:
		return

	var local_mouse = tilemap_layer.to_local(get_global_mouse_position())
	var cell = tilemap_layer.local_to_map(local_mouse)
	var iso_pos = _cell_to_iso(cell) + Vector2(current_item_data.width/2, current_item_data.height / 2)
	
		# ✅ If mouse over occupied cell(s), hide preview
	#if _is_over_occupied(cell):
		#preview.visible = false
		#return
	#else:
		#preview.visible = true
	
	print(cell, 'CELL')

	preview.global_position = tilemap_layer.to_global(iso_pos)
	#preview.z_index = int(preview.global_position.y - current_item_data.height / 2)
	
	var size = current_item_data.size

	var c = get_check_cell(cell, size.x-1, size.y-1, size, current_item_data.z_size)
	#preview.z_index = get_iso_z_index(c)
	preview.z_index = 100000
	

	var can_place = _can_place(cell)
	preview.modulate = Color(0,1,0,0.5) if can_place else Color(1,0,0,0.5)

	if can_click_preview and can_place and Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT):
		_place_object(cell)
		_stop_preview()

	if Input.is_action_just_pressed(ACTION_CANCEL) or Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_RIGHT):
		_stop_preview()

# ------------------- Check placement -------------------	
func _can_place(cell: Vector2i) -> bool:
	var size = current_item_data.size  # e.g. Vector2i(width, height)
	
	for y in range(size.y):
		for x in range(size.x):
			var check_cell = get_check_cell(cell, x, y, size, current_item_data.z_size)
			print(cell, 'CELL')
			print(check_cell, 'CHECK_CELL')
			
			# ✅ Check if already occupied
			if is_cell_occupied(check_cell):
				return false
			
			# ✅ Also ensure tile exists on tilemap
			var cell_source_exists = tilemap_layer.get_cell_source_id(check_cell) != -1
			if not cell_source_exists:
				return false
				
	return true


# ------------------- Place object -------------------
func _place_object(cell: Vector2i) -> void:
	if not current_item_data or not tilemap_layer:
		return

	#var obj = Sprite2D.new()
	#obj.texture = current_item_data.texture
	#var iso_pos = _cell_to_iso(cell) + Vector2(current_item_data.width/2, current_item_data.height/2)
	#obj.global_position = tilemap_layer.to_global(iso_pos)
	#obj.z_index = int(obj.global_position.y - current_item_data.height / 2)
	#add_child(obj)
	
	# ✅ Create the Area2D as the parent
	var area := Area2D.new()
	add_child(area)
	play_sound(current_item_data.sound)

	# ✅ Create the sprite as a child
	var obj := Sprite2D.new()
	obj.texture = current_item_data.texture
	obj.set_meta("item_data", current_item_data)
	obj.set_meta("cell", cell)
	area.add_child(obj)

	var shape := CollisionShape2D.new() 
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(current_item_data.width/2, current_item_data.height/2) 
	shape.shape = rect_shape 
	area.add_child(shape)

	# ✅ Connect input signal on Area2D
	area.connect("input_event", Callable(self, "_on_object_clicked").bind(area))
	
	# ✅ Connect hover signals
	area.connect("mouse_entered", Callable(self, "_on_object_hover_enter").bind(area))
	area.connect("mouse_exited", Callable(self, "_on_object_hover_exit").bind(area))

	# ✅ Set the Area2D’s global position (not the sprite!)
	var iso_pos = _cell_to_iso(cell) + Vector2(current_item_data.width / 2, current_item_data.height / 2)
	area.global_position = tilemap_layer.to_global(iso_pos)

	# ✅ Sprite z-index relative to Area2D
	#obj.z_index = int(obj.global_position.y - current_item_data.height / 2)
	var size = current_item_data.size
	var c = get_check_cell(cell, size.x-1, size.y-1, size, current_item_data.z_size)
	obj.z_index = get_iso_z_index(c)
	
		# ✅ Mark occupied cells
	for y in range(size.y):
		for x in range(size.x):
			var check_cell = get_check_cell(cell, x, y, size, current_item_data.z_size)
			var occupied = check_cell
			set_cell_occupied(occupied, true)
			
	remove_item_from_inventory(current_item_data.name)
	
		# ✅ Save to global
	Global.placed_objects.append({
		"item_name": current_item_data.name,
		"cell": cell,
		"size": current_item_data.size,
		"texture_path": current_item_data.texture.resource_path,
		"width": current_item_data.width,
		"height": current_item_data.height,
		"z_size": current_item_data.z_size,
		"sound": current_item_data.sound
	})
		
# ------------------- Remove item from inventory by name -------------------
func remove_item_from_inventory(item_name: String) -> void:
	print(item_name, "REMOVE ITEM")
	var item_to_remove: Node = null

	# Iterate through all slots in %Inv
	for slot in %Inv.get_children():  
		for child in slot.get_children(): 
			# Check if this child has metadata "item_name" matching the target
			if child.has_meta("item_name") and child.get_meta("item_name") == item_name:
				item_to_remove = child
				break
		if item_to_remove:
			break

	# Remove the found item
	if item_to_remove:
		item_to_remove.get_parent().remove_child(item_to_remove)
		item_to_remove.queue_free()
		print("Removed placed item from inventory:", item_name)
		
			## Remove from global
	#for i in range(Global.inventory_data.size()):
		#if Global.inventory_data[i]["name"] == item_name:
			#Global.inventory_data.remove_at(i)
			#break

# ------------------- Helper: Check if area overlaps occupied cells -------------------
func _is_over_occupied(cell: Vector2i) -> bool:
	if not current_item_data:
		return false
	var size = current_item_data.size
	for y in range(size.y):
		for x in range(size.x):
			var check_cell = get_check_cell(cell, x, y, size, current_item_data.z_size)
			if is_cell_occupied(check_cell):
				return true
	return false
	
# ------------------- Helper: Get check cell position -------------------
func get_check_cell(cell: Vector2i, x: int, y: int, size: Vector2i, z_size: int) -> Vector2i:
	var offset_x = x + 1
	var offset_y = y if size.y > 1 else y + 1
	return cell + Vector2i(offset_x+z_size, offset_y + z_size)

# ------------------- Stop preview -------------------
func _stop_preview() -> void:
	if preview:
		preview.queue_free()
	preview = null
	current_item_data = null
	
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

# ------------------- Helper: cell → isometric coordinates -------------------
func _cell_to_iso(cell: Vector2i) -> Vector2:
	var x = (cell.x - cell.y) * (tile_width / 2)
	var y = (cell.x + cell.y) * (tile_height / 2)
	return Vector2(x, y)
	
# ✅ Set cell occupied state
func set_cell_occupied(cell: Vector2i, occupied: bool) -> void:
	if occupied:
		occupied_cells[cell] = true
	else:
		occupied_cells.erase(cell)

# ✅ Check if cell is occupied
func is_cell_occupied(cell: Vector2i) -> bool:
	return occupied_cells.has(cell)
	
func _on_object_clicked(viewport: Node, event: InputEvent, shape_idx: int, area: Area2D) -> void:
	if current_item_data:
		return
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT and event.pressed:
		print("Picked up object:", area)

		var obj: Sprite2D = area.get_child(0)
		var cell: Vector2i = obj.get_meta("cell")
		var item_data: ItemData = obj.get_meta("item_data")

		# Free cells
		var size = item_data.size
		for y in range(size.y):
			for x in range(size.x):
				var check_cell = get_check_cell(cell, x, y, size, item_data.z_size)
				set_cell_occupied(check_cell, false)
				
		# Remove from global placed objects
		for i in range(Global.placed_objects.size()):
			if Global.placed_objects[i]["cell"] == cell:
				Global.placed_objects.remove_at(i)
				break
		
		# Remove placed area and sprite
		area.queue_free()
		
		# Start preview again with same item data
		start_preview(item_data)
		
func _on_object_hover_enter(area: Area2D) -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_object_hover_exit(area: Area2D) -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		
func play_sound(sound: AudioStream):
	if sound:
		var player = AudioStreamPlayer.new()
		player.stream = sound
		player.volume_db = -10
		get_tree().current_scene.add_child(player)
		player.play()
		player.connect("finished", player.queue_free)
