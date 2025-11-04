extends CanvasLayer

@onready var placement: Node2D = $"../../BuildSystem"

var InvSize = 3
var itemsLoad = ["res://room/ItemsResources/Spool.tres","res://room/ItemsResources/Candy.tres", "res://room/ItemsResources/MatchBox.tres"]
# Called when the node enters the scene tree for the first time.
	
func is_item_not_placed(item_name: String) -> bool:
	# Check if the item_name exists in any placed object
	for placed_obj in Global.placed_objects:
		if item_name == placed_obj.item_name:
			return false
	return true


func _ready() -> void:
	# Create a Label for tooltips
	tooltip_label = Label.new()
	tooltip_label.visible = false
	add_child(tooltip_label)
	print(Global.inventory_data, "Inventory data")
	
	for i in InvSize:
		var slot := InventorySlot.new()
		slot.init(ItemData.Type.MAIN, Vector2(64, 64))
		%Inv.add_child(slot)
		pass
		
	
	for i in range(itemsLoad.size()):
		var res = load(itemsLoad[i])
		for inv in range(Global.inventory_data.size()):
			if(Global.placed_objects.size() > 0):
				for obj in range(Global.placed_objects.size()):
					print(Global.placed_objects, "placed")
					if res.name == Global.inventory_data[inv].name and is_item_not_placed(res.name):
						var item = InventoryItem.new()
						item.init(res)
						%Inv.get_child(i).add_child(item)
						## In Placement.gd
						if res.name != "Candy":
							item.connect("drag_started", Callable(self, "_on_drag_started"))
						else:
							item.connect("gui_input", Callable(self, "_on_candy_click"))
							#item.connect("mouse_entered", Callable(self, "_on_candy_hovered"))
							#item.connect("mouse_exited", Callable(self, "_on_candy_unhovered"))
			else:
				if res.name == Global.inventory_data[inv].name:
					var item = InventoryItem.new()
					item.init(res)
					%Inv.get_child(i).add_child(item)
					## In Placement.gd
					if res.name != "Candy":
						item.connect("drag_started", Callable(self, "_on_drag_started"))
					else:
						item.connect("gui_input", Callable(self, "_on_candy_click"))
						#item.connect("mouse_entered", Callable(self, "_on_candy_hovered"))
						#item.connect("mouse_exited", Callable(self, "_on_candy_unhovered"))

	#for i in itemsLoad.size():
		#var item = InventoryItem.new()
		#item.init(load(itemsLoad[i]))
		#%Inv.get_child(i).add_child(item)
		### In Placement.gd
		#item.connect("drag_started", Callable(self, "_on_drag_started"))
	
	# Create exit button
	_create_exit_button()


func _create_exit_button() -> void:
	var exit_button = Button.new()
	exit_button.text = "Выйти в комнату"
	exit_button.name = "ExitButton"
	
	# Position in top right corner using anchors
	exit_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	#exit_button.offset_left = -220
	#exit_button.offset_top = 20
	exit_button.offset_left = 5
	exit_button.offset_top = 80
	exit_button.custom_minimum_size = Vector2(200, 40)
	
	# Connect signal
	exit_button.pressed.connect(_on_exit_button_pressed)
	
	# Add to GUI layer
	add_child(exit_button)
	print("[GUI] Exit button created in top right corner")


func _on_exit_button_pressed() -> void:
	print("[GUI] Exit button pressed - loading house scene")
	var house_scene_path = "res://house/house.tscn"
	
	if ResourceLoader.exists(house_scene_path):
		get_tree().change_scene_to_file(house_scene_path)
		print("[GUI] ✅ Scene changed to house successfully")
	else:
		print("[GUI] ❌ ERROR: Scene file not found at path: ", house_scene_path)

func _on_drag_started(item_data: ItemData) -> void:
	print("Drag started:", item_data.name)
	if %BuildSystem.has_method("start_preview"):
		%BuildSystem.start_preview(item_data)
		
func _on_candy_click(event) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if %BuildSystem.has_method("remove_item_from_inventory"):
			%BuildSystem.remove_item_from_inventory("Candy")
		Global.current_inv_item = "Candy"
	
func _on_candy_hovered():
	# Use viewport mouse position for Control nodes
	var mouse_pos = get_viewport().get_mouse_position()
	show_tooltip("Yummy Candy! 🍬", mouse_pos)

func _on_candy_unhovered():
	hide_tooltip()
	
# In your main UI or CanvasLayer
var tooltip_label: Label

func show_tooltip(text: String, position: Vector2):
	tooltip_label.text = text
	tooltip_label.position = position
	tooltip_label.visible = true

func hide_tooltip():
	tooltip_label.visible = false
