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

func _on_drag_started(item_data: ItemData) -> void:
	print("Drag started:", item_data.name)
	if %BuildSystem.has_method("start_preview"):
		%BuildSystem.start_preview(item_data)
