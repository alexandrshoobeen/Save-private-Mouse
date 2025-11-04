extends CanvasLayer

var InvSize = 1  # Only 1 slot
var inventory_slots: Array = []
var drop_dialog: Control = null
var item_to_drop: InventoryItem = null
var house_scene: Node2D = null  # Reference to house scene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_create_inventory_ui()

func _create_inventory_ui() -> void:
	# Create main inventory panel (left top)
	var panel = Panel.new()
	panel.name = "InventoryPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 20
	panel.offset_top = 20
	panel.offset_right = 94  # Width: 74 (1 slot * 64 + padding)
	panel.offset_bottom = 94  # Height: 74 (1 slot * 64 + padding)
	add_child(panel)
	
	# Create single slot container (no grid needed for 1 slot)
	var container = Control.new()
	container.name = "Inv"
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Add margins
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	margin.add_child(container)
	
	# Create single inventory slot
	var slot := InventorySlot.new()
	slot.init(ItemData.Type.MAIN, Vector2(64, 64))
	# Enable mouse input for right-click detection
	slot.mouse_filter = Control.MOUSE_FILTER_PASS
	container.add_child(slot)
	inventory_slots.append(slot)
	
	print("[HOUSE_GUI] Inventory UI created with ", InvSize, " slot (left top)")

func add_item_to_inventory(item_data: ItemData) -> bool:
	# Check if inventory is already full (only 1 slot)
	if inventory_slots.size() > 0:
		var slot = inventory_slots[0]
		if slot.get_child_count() > 0:
			print("[HOUSE_GUI] Inventory is full! Only one item allowed.")
			return false
		
		# Add item to the single slot
		var item = InventoryItem.new()
		item.init(item_data)
		slot.add_child(item)
		
		# Enable mouse input on item for right-click detection
		item.mouse_filter = Control.MOUSE_FILTER_STOP
		
		print("[HOUSE_GUI] Item added to inventory: ", item_data.name)
		return true
	
	print("[HOUSE_GUI] No inventory slot available!")
	return false

func _input(event: InputEvent) -> void:
	# Handle right-click on inventory item
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		# Check if click is on inventory item
		if inventory_slots.size() > 0:
			var slot = inventory_slots[0]
			if slot.get_child_count() > 0:
				var item = slot.get_child(0) as InventoryItem
				if item:
					# Get mouse position in viewport coordinates
					var mouse_pos = get_viewport().get_mouse_position()
					
					# Get panel and item positions
					var panel = get_node("InventoryPanel")
					if panel:
						var panel_rect = panel.get_global_rect()
						if panel_rect.has_point(mouse_pos):
							# Mouse is over panel, check if it's over the item
							# Item is inside slot, which is inside panel
							var slot_rect = slot.get_global_rect()
							if slot_rect.has_point(mouse_pos):
								item_to_drop = item
								_show_drop_dialog()
								get_viewport().set_input_as_handled()

func _show_drop_dialog() -> void:
	if drop_dialog:
		drop_dialog.queue_free()
	
	# Create dialog window
	drop_dialog = Control.new()
	drop_dialog.name = "DropDialog"
	drop_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	drop_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Create semi-transparent background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.5)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	drop_dialog.add_child(background)
	
	# Create dialog panel
	var panel = Panel.new()
	panel.name = "DialogPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(300, 150)
	panel.position = Vector2(-150, -75)
	drop_dialog.add_child(panel)
	
	# Create VBoxContainer for layout
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	# Add margins
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(inner_vbox)
	
	# Add label with question
	var label = Label.new()
	label.text = "выкинуть?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	inner_vbox.add_child(label)
	
	# Add buttons container
	var buttons_container = HBoxContainer.new()
	buttons_container.add_theme_constant_override("separation", 20)
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_vbox.add_child(buttons_container)
	
	# Add "Yes" button
	var yes_button = Button.new()
	yes_button.text = "Да"
	yes_button.custom_minimum_size = Vector2(100, 40)
	yes_button.pressed.connect(_on_drop_dialog_yes)
	buttons_container.add_child(yes_button)
	
	# Add "No" button
	var no_button = Button.new()
	no_button.text = "Нет"
	no_button.custom_minimum_size = Vector2(100, 40)
	no_button.pressed.connect(_on_drop_dialog_no)
	buttons_container.add_child(no_button)
	
	# Add dialog to GUI layer
	add_child(drop_dialog)
	print("[HOUSE_GUI] Drop dialog created")

func _on_drop_dialog_yes() -> void:
	if item_to_drop and item_to_drop.data:
		# Get hero_mouse from house scene
		var hero_mouse = _get_hero_mouse()
		if hero_mouse:
			# Get current animation state
			var current_animation = _get_hero_mouse_animation_state(hero_mouse)
			
			# Calculate drop position based on hero_mouse direction
			var drop_position = hero_mouse.position  # Use local position relative to house scene
			if current_animation == "idle_left":
				drop_position.x -= 100
			elif current_animation == "idle_right":
				drop_position.x += 100
			else:
				# Default to right if not idle
				drop_position.x += 100
			
			# Create item on scene at drop position
			_create_item_on_scene(item_to_drop.data, drop_position)
		
		# Remove item from Global.inventory_data
		if item_to_drop.data:
			var item_name = item_to_drop.data.name
			print("[HOUSE_GUI] 📦 Global.inventory_data contents before drop: ", Global.inventory_data)
			for i in range(Global.inventory_data.size() - 1, -1, -1):
				if Global.inventory_data[i].has("name") and Global.inventory_data[i]["name"] == item_name:
					Global.inventory_data.remove_at(i)
					print("[HOUSE_GUI] Item '", item_name, "' removed from Global.inventory_data")
					print("[HOUSE_GUI] 📦 Global.inventory_data contents after drop: ", Global.inventory_data)
					break
		
		# Remove item from inventory
		var slot = item_to_drop.get_parent()
		if slot:
			item_to_drop.queue_free()
			print("[HOUSE_GUI] Item dropped from inventory")
	
	_close_drop_dialog()

func _on_drop_dialog_no() -> void:
	_close_drop_dialog()

func _close_drop_dialog() -> void:
	if drop_dialog:
		drop_dialog.queue_free()
		drop_dialog = null
	item_to_drop = null
	print("[HOUSE_GUI] Drop dialog closed")

func _get_hero_mouse() -> CharacterBody2D:
	# Get house scene (parent of this CanvasLayer)
	if not house_scene:
		house_scene = get_parent() as Node2D
	
	if house_scene:
		# Try to get hero_mouse directly from house script variable
		if "hero_mouse" in house_scene:
			var hero = house_scene.get("hero_mouse")
			if hero:
				return hero as CharacterBody2D
		
		# Alternative: find by name in children
		var hero_mouse = house_scene.find_child("HeroMouse", true, false)
		if hero_mouse and hero_mouse is CharacterBody2D:
			return hero_mouse as CharacterBody2D
		
		# Another alternative: iterate through children
		for child in house_scene.get_children():
			if child is CharacterBody2D and (child.name == "HeroMouse" or "HeroMouse" in child.name):
				return child as CharacterBody2D
	
	return null

func _get_hero_mouse_animation_state(hero_mouse: CharacterBody2D) -> String:
	if not hero_mouse:
		return "idle_right"
	
	# Try to get animation_tree property
	var animation_tree = null
	if "animation_tree" in hero_mouse:
		animation_tree = hero_mouse.animation_tree
	elif hero_mouse.has_node("AnimationTree"):
		animation_tree = hero_mouse.get_node("AnimationTree")
	
	if animation_tree:
		var state_machine = animation_tree.get("parameters/playback")
		if state_machine:
			var current_node = state_machine.get_current_node()
			print("[HOUSE_GUI] Hero mouse current animation: ", current_node)
			return current_node
	
	return "idle_right"  # Default

func _create_item_on_scene(item_data: ItemData, position: Vector2) -> void:
	# Get house scene
	if not house_scene:
		house_scene = get_parent() as Node2D
	
	if not house_scene:
		print("[HOUSE_GUI] ERROR: Cannot find house scene!")
		return
	
	# Create item based on item_data name
	var item_scene = null
	if item_data.name == "MatchBox":
		item_scene = preload("res://house/match_box.tscn")
	elif item_data.name == "Threads":
		item_scene = preload("res://house/threads.tscn")
	else:
		# Default to MatchBox
		item_scene = preload("res://house/match_box.tscn")
	
	if item_scene:
		var item_node = item_scene.instantiate()
		item_node.position = position  # Use local position relative to house scene
		
		# Set z_index based on item type
		# Threads should be above tumba (z_index 0) but below hero_mouse (z_index 2)
		# MatchBox should be behind hero_mouse
		if item_data.name == "Threads":
			# Set threads z_index to be between tumba (0) and hero_mouse (2)
			item_node.z_index = 1  # Above tumba (0), below hero_mouse (2)
			
			# Ensure hero_mouse has correct z_index (must be 2 or higher)
			var hero_mouse = _get_hero_mouse()
			if hero_mouse:
				hero_mouse.z_index = 2  # Always ensure hero_mouse is above threads
				# Also check Sprite2D children of hero_mouse
				for child in hero_mouse.get_children():
					if child is Sprite2D:
						child.z_index = 2  # Ensure sprites are also above threads
		else:
			item_node.z_index = -1  # Behind hero_mouse
		
		# Also set z_index for Sprite2D inside item to ensure proper rendering order
		var sprite = item_node.find_child("Sprite2D", true, false)
		if sprite:
			if item_data.name == "Threads":
				sprite.z_index = 1  # Above tumba (0) but below hero_mouse (2)
				sprite.z_as_relative = false  # Use absolute z_index, not relative to parent
			else:
				sprite.z_index = -1  # Behind hero_mouse
		
		# Add item to scene, but ensure proper z_index order
		# Add threads before hero_mouse in tree to ensure correct rendering order
		if item_data.name == "Threads":
			# Find hero_mouse position in children to insert threads before it
			var hero_mouse = _get_hero_mouse()
			if hero_mouse and hero_mouse.get_parent() == house_scene:
				var hero_index = hero_mouse.get_index()
				house_scene.add_child(item_node)
				house_scene.move_child(item_node, hero_index)  # Move threads before hero_mouse
			else:
				house_scene.add_child(item_node)
		else:
			house_scene.add_child(item_node)
		
		# Set up collision detection based on item type
		if item_data.name == "MatchBox" and item_node is Area2D:
			item_node.monitoring = true
			item_node.monitorable = true
			
			# Connect signals using lambda to pass the item reference
			if house_scene.has_method("_on_matchbox_body_entered"):
				item_node.body_entered.connect(func(body): house_scene._on_matchbox_body_entered_with_source(body, item_node))
			if house_scene.has_method("_on_matchbox_body_exited"):
				item_node.body_exited.connect(func(body): house_scene._on_matchbox_body_exited_with_source(body, item_node))
			if house_scene.has_method("_on_matchbox_area_entered"):
				item_node.area_entered.connect(func(area): house_scene._on_matchbox_area_entered_with_source(area, item_node))
			if house_scene.has_method("_on_matchbox_area_exited"):
				item_node.area_exited.connect(func(area): house_scene._on_matchbox_area_exited_with_source(area, item_node))
		
		elif item_data.name == "Threads" and item_node is Node2D:
			# Threads is Node2D with PickupArea inside
			var pickup_area = item_node.find_child("PickupArea", true, false)
			if pickup_area and pickup_area is Area2D:
				pickup_area.monitoring = true
				pickup_area.monitorable = true
				
				# Connect signals for threads using lambda to pass item_node reference
				if house_scene.has_method("_on_threads_body_entered"):
					pickup_area.body_entered.connect(func(body): house_scene._on_threads_body_entered_with_source(body, item_node))
				if house_scene.has_method("_on_threads_body_exited"):
					pickup_area.body_exited.connect(func(body): house_scene._on_threads_body_exited_with_source(body, item_node))
				if house_scene.has_method("_on_threads_area_entered"):
					pickup_area.area_entered.connect(func(area): house_scene._on_threads_area_entered_with_source(area, item_node))
				if house_scene.has_method("_on_threads_area_exited"):
					pickup_area.area_exited.connect(func(area): house_scene._on_threads_area_exited_with_source(area, item_node))
	
	print("[HOUSE_GUI] Item created on scene at position: ", position, " (item: ", item_data.name, ")")


