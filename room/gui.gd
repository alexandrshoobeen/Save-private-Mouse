extends CanvasLayer

@onready var placement: Node2D = $"../../BuildSystem"

var InvSize = 4
var itemsLoad = ["res://room/ItemsResources/OneCube.tres", "res://room/ItemsResources/MatchBox.tres", "res://room/ItemsResources/Box.tres", "res://room/ItemsResources/TwoCubes.tres"]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in InvSize:
		var slot := InventorySlot.new()
		slot.init(ItemData.Type.MAIN, Vector2(64, 64))
		%Inv.add_child(slot)
		pass

	for i in itemsLoad.size():
		var item = InventoryItem.new()
		item.init(load(itemsLoad[i]))
		%Inv.get_child(i).add_child(item)
		# In Placement.gd
		item.connect("drag_started", Callable(self, "_on_drag_started"))
	
	# Create exit button
	_create_exit_button()


func _create_exit_button() -> void:
	var exit_button = Button.new()
	exit_button.text = "Выйти в комнату"
	exit_button.name = "ExitButton"
	
	# Position in top right corner using anchors
	exit_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	exit_button.offset_left = -220
	exit_button.offset_top = 20
	exit_button.offset_right = -20
	exit_button.offset_bottom = 60
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
