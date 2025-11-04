class_name InventoryItem
extends TextureRect

@export var data: ItemData

signal drag_started(item_data: ItemData)

func init(d: ItemData) -> void:
	data = d
	
func _ready() -> void:
	if data == null:
		return  # Exit if no data assigned yet
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture = data.texture
	tooltip_text = data.description
	pivot_offset = data.pivot_offset
	set_meta("item_name", data.name) 
	
#func _get_drag_data(at_position: Vector2) -> Variant:
	##set_drag_preview(make_drag_preview(at_position))
	#print("DRAG STARTED")
	#emit_signal("drag_started", data)
	#return self
	
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("CLICK STARTED")
		emit_signal("drag_started", data)

	
func make_drag_preview(at_position: Vector2):
	var t = TextureRect.new()
	t.texture = texture
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = size
	t.modulate.a = 0.5
	t.position = Vector2(-at_position)
	
	var c := Control.new()
	c.add_child(t)
	
	return c
	
