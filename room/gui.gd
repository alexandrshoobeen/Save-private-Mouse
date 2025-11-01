extends CanvasLayer

var InvSize = 16
var itemsLoad = ["res://room/ItemsResources/Bow.tres", "res://room/ItemsResources/Sword.tres"]
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
