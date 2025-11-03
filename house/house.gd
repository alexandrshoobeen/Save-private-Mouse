extends Node2D

@onready var predator_awaking: Area2D = $PredatorAwaking
@onready var get_up_area: Area2D = $"get up"
@onready var jump_area: Area2D = $jump_area
@onready var entering_room: Area2D = $entering_room
@onready var predator_node: Node2D = $predator
@onready var trash_node: Node2D = $Trash
var hero_mouse: CharacterBody2D = null
var predator_awakened: bool = false
var is_jumping_to_trash: bool = false
var dialog_window: Control = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ensure Area2D is monitoring
	if predator_awaking:
		predator_awaking.monitoring = true
		predator_awaking.monitorable = false
		# Connect signals BEFORE adding hero_mouse
		predator_awaking.body_entered.connect(_on_predator_awaking_body_entered)
		predator_awaking.body_exited.connect(_on_predator_awaking_body_exited)
		predator_awaking.area_entered.connect(_on_predator_awaking_area_entered)
		predator_awaking.area_exited.connect(_on_predator_awaking_area_exited)
		print("PredatorAwaking area set up and monitoring: ", predator_awaking.monitoring)
	
	# Set up "get up" area
	if get_up_area:
		get_up_area.monitoring = true
		get_up_area.monitorable = false
		get_up_area.body_entered.connect(_on_get_up_area_body_entered)
		get_up_area.body_exited.connect(_on_get_up_area_body_exited)
		print("[HOUSE] Get up area set up and monitoring: ", get_up_area.monitoring)
		print("[HOUSE] Get up area position: ", get_up_area.global_position)
		var shape_node = get_up_area.get_node("CollisionShape2D")
		if shape_node:
			print("[HOUSE] Get up area CollisionShape2D position: ", shape_node.global_position)
	else:
		print("[HOUSE] ERROR: get_up_area is null!")
	
	# Set up "jump_area"
	if jump_area:
		jump_area.monitoring = true
		jump_area.monitorable = false
		jump_area.body_entered.connect(_on_jump_area_body_entered)
		print("[HOUSE] Jump area set up and monitoring: ", jump_area.monitoring)
	else:
		print("[HOUSE] ERROR: jump_area is null!")
	
	# Set up "entering_room" area
	if entering_room:
		entering_room.monitoring = true
		entering_room.monitorable = false
		entering_room.body_entered.connect(_on_entering_room_body_entered)
		print("[HOUSE] Entering room area set up and monitoring: ", entering_room.monitoring)
	else:
		print("[HOUSE] ERROR: entering_room is null!")
	
	# Create and add hero_mouse
	var hero_mouse_scene = preload("res://heroMouse/hero_mouse.tscn")
	hero_mouse = hero_mouse_scene.instantiate()
	hero_mouse.position = Vector2(550.0, 550.0)
	add_child(hero_mouse)
	print("Hero mouse created: ", hero_mouse.name)


# CharacterBody2D will trigger body_entered signal, so we don't need manual position check
# But keeping this as backup in case signals don't work
func _process(_delta: float) -> void:
	# Manual check as backup (works even if signals don't trigger)
	if hero_mouse and predator_awaking:
		var zone_shape_node = predator_awaking.get_node("CollisionShape2D")
		if zone_shape_node and zone_shape_node.shape is RectangleShape2D:
			var rect_shape = zone_shape_node.shape as RectangleShape2D
			# Get the global transform of the collision shape
			var zone_transform = zone_shape_node.global_transform
			var zone_pos = zone_transform.origin
			var zone_size = rect_shape.size
			
			# Create rectangle centered at zone position
			var zone_rect = Rect2(
				zone_pos.x - zone_size.x / 2,
				zone_pos.y - zone_size.y / 2,
				zone_size.x,
				zone_size.y
			)
			
			# Check if hero_mouse position is in the zone
			var mouse_pos = hero_mouse.global_position
			var is_in_zone = zone_rect.has_point(mouse_pos)
			
			# Update predator state based on zone presence
			if is_in_zone and not predator_awakened:
				print("Manual check: hero_mouse at ", mouse_pos, " is in zone at ", zone_rect)
				if predator_node and predator_node.has_method("wake_up"):
					predator_node.wake_up()
					predator_awakened = true
			elif not is_in_zone and predator_awakened:
				print("Manual check: hero_mouse left zone")
				if predator_node and predator_node.has_method("fall_asleep"):
					predator_node.fall_asleep()
					predator_awakened = false
	
	# Manual check for "get up" area (backup check)
	if hero_mouse and get_up_area:
		var zone_shape_node = get_up_area.get_node("CollisionShape2D")
		if zone_shape_node and zone_shape_node.shape is RectangleShape2D:
			var rect_shape = zone_shape_node.shape as RectangleShape2D
			var zone_transform = zone_shape_node.global_transform
			var zone_pos = zone_transform.origin
			var zone_size = rect_shape.size
			
			var zone_rect = Rect2(
				zone_pos.x - zone_size.x / 2,
				zone_pos.y - zone_size.y / 2,
				zone_size.x,
				zone_size.y
			)
			
			var mouse_pos = hero_mouse.global_position
			var is_in_get_up_zone = zone_rect.has_point(mouse_pos)
			var current_vertical_state = false
			if "can_move_vertically" in hero_mouse:
				current_vertical_state = hero_mouse.can_move_vertically
			
			if is_in_get_up_zone and not current_vertical_state:
				print("[HOUSE] 🔵 MANUAL CHECK: hero_mouse at ", mouse_pos, " is in get_up zone!")
				print("[HOUSE] Current can_move_vertically: ", current_vertical_state)
				if hero_mouse.has_method("enable_vertical_movement"):
					hero_mouse.enable_vertical_movement()
			elif not is_in_get_up_zone and current_vertical_state == true:
				print("[HOUSE] 🔴 MANUAL CHECK: hero_mouse left get_up zone!")
				if hero_mouse.has_method("disable_vertical_movement"):
					hero_mouse.disable_vertical_movement()


func _on_predator_awaking_body_entered(body: Node) -> void:
	print("Body entered PredatorAwaking zone: ", body.name, " | Path: ", body.get_path())
	# Check if the entering body is the hero_mouse (CharacterBody2D will trigger this)
	if not predator_awakened:
		if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
			print("Hero mouse detected in zone, waking up predator")
			if predator_node:
				if predator_node.has_method("wake_up"):
					predator_node.wake_up()
					predator_awakened = true
					print("Predator awakened successfully!")
				else:
					print("ERROR: predator_node doesn't have wake_up method")
			else:
				print("ERROR: predator_node is null")


func _on_predator_awaking_body_exited(body: Node) -> void:
	print("Body exited PredatorAwaking zone: ", body.name, " | Path: ", body.get_path())
	# Check if the exiting body is the hero_mouse
	if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
		print("Hero mouse left zone, putting predator to sleep")
		if predator_node and predator_node.has_method("fall_asleep"):
			predator_node.fall_asleep()
			predator_awakened = false
			print("Predator fell asleep")


func _on_predator_awaking_area_entered(area: Area2D) -> void:
	# Check if the entering area belongs to hero_mouse
	if not predator_awakened and "HeroMouse" in area.get_path().get_concatenated_names():
		if predator_node and predator_node.has_method("wake_up"):
			predator_node.wake_up()
			predator_awakened = true


func _on_predator_awaking_area_exited(area: Area2D) -> void:
	# Check if the exiting area belongs to hero_mouse
	if "HeroMouse" in area.get_path().get_concatenated_names():
		if predator_node and predator_node.has_method("fall_asleep"):
			predator_node.fall_asleep()
			predator_awakened = false


func _on_get_up_area_body_entered(body: Node) -> void:
	print("[HOUSE] 🔵 Body entered get up area: ", body.name, " | Path: ", body.get_path())
	print("[HOUSE] Body type: ", body.get_class())
	if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
		print("[HOUSE] ✅ Hero mouse detected! Checking for enable_vertical_movement method...")
		if body.has_method("enable_vertical_movement"):
			print("[HOUSE] ✅ Method found! Calling enable_vertical_movement()...")
			body.enable_vertical_movement()
			print("[HOUSE] ✅ Method called successfully")
		else:
			print("[HOUSE] ❌ ERROR: enable_vertical_movement method NOT FOUND!")
			print("[HOUSE] Available methods:", body.get_method_list())
	else:
		print("[HOUSE] Body is not HeroMouse. Body name: '", body.name, "' | Path contains 'HeroMouse': ", "HeroMouse" in str(body.get_path()))


func _on_get_up_area_body_exited(body: Node) -> void:
	print("[HOUSE] 🔴 Body exited get up area: ", body.name, " | Path: ", body.get_path())
	if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
		print("[HOUSE] ✅ Hero mouse left! Checking for disable_vertical_movement method...")
		if body.has_method("disable_vertical_movement"):
			print("[HOUSE] ✅ Method found! Calling disable_vertical_movement()...")
			body.disable_vertical_movement()
			print("[HOUSE] ✅ Method called successfully")
		else:
			print("[HOUSE] ❌ ERROR: disable_vertical_movement method NOT FOUND!")
	else:
		print("[HOUSE] Body is not HeroMouse")


func _on_jump_area_body_entered(body: Node) -> void:
	print("[HOUSE] 🦘 Body entered jump_area: ", body.name, " | Path: ", body.get_path())
	if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
		if not is_jumping_to_trash:
			print("[HOUSE] ✅ Hero mouse detected in jump_area! Starting jump animation...")
			_start_jump_to_trash_animation(body)


func _start_jump_to_trash_animation(mouse: CharacterBody2D) -> void:
	if is_jumping_to_trash:
		return  # Already animating
	
	is_jumping_to_trash = true
	print("[HOUSE] Starting jump animation...")
	
	# Disable physics for hero_mouse
	mouse.set_physics_process(false)
	print("[HOUSE] Physics disabled for hero_mouse")
	
	# Get positions
	var start_pos = mouse.global_position
	var trash_pos = trash_node.global_position
	print("[HOUSE] Mouse start position: ", start_pos)
	print("[HOUSE] Trash position: ", trash_pos)
	
	# Create Tween for animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_method(
		func(pos): mouse.global_position = pos,
		start_pos,
		trash_pos,
		1.0  # Animation duration in seconds
	)
	
	# Wait for animation to complete, then hide mouse and start trash animation
	tween.tween_callback(func(): _on_jump_animation_complete(mouse))


func _on_jump_animation_complete(mouse: CharacterBody2D) -> void:
	print("[HOUSE] Jump animation completed!")
	
	# Hide hero_mouse
	mouse.visible = false
	print("[HOUSE] Hero mouse hidden")
	
	# Start falling animation for trash
	if trash_node:
		var animation_tree = trash_node.get_node_or_null("AnimationTree")
		if animation_tree:
			# Try to get state machine playback (it should exist automatically for state machines)
			var state_machine = animation_tree.get("parameters/playback")
			if state_machine:
				state_machine.travel("falling")
				print("[HOUSE] ✅ Falling animation started for trash (via AnimationTree)")
			else:
				# Fallback to AnimationPlayer if state machine doesn't work
				var animation_player = trash_node.get_node_or_null("AnimationPlayer")
				if animation_player:
					animation_player.play("falling")
					print("[HOUSE] ✅ Falling animation started for trash (via AnimationPlayer fallback)")
				else:
					print("[HOUSE] ❌ ERROR: Could not start falling animation")
		else:
			# Fallback: try AnimationPlayer directly
			var animation_player = trash_node.get_node_or_null("AnimationPlayer")
			if animation_player:
				animation_player.play("falling")
				print("[HOUSE] ✅ Falling animation started for trash (via AnimationPlayer direct)")
			else:
				print("[HOUSE] ❌ ERROR: No AnimationTree or AnimationPlayer found in trash")
	else:
		print("[HOUSE] ❌ ERROR: trash_node is null")
	
	is_jumping_to_trash = false


func _on_entering_room_body_entered(body: Node) -> void:
	print("[HOUSE] 🚪 Body entered entering_room: ", body.name, " | Path: ", body.get_path())
	if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
		print("[HOUSE] ✅ Hero mouse detected in entering_room! Showing dialog...")
		if not dialog_window:
			_show_enter_dialog()


func _show_enter_dialog() -> void:
	print("[HOUSE] Creating dialog window...")
	
	# Disable hero_mouse control and set idle_left animation
	if hero_mouse:
		if hero_mouse.has_method("disable_control"):
			hero_mouse.disable_control()
			print("[HOUSE] Hero mouse control disabled")
		if hero_mouse.has_method("set_idle_left"):
			hero_mouse.set_idle_left()
			print("[HOUSE] Hero mouse animation set to idle_left")
	
	# Create main dialog container
	dialog_window = Control.new()
	dialog_window.name = "EnterDialog"
	dialog_window.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_window.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Create semi-transparent background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.5)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_window.add_child(background)
	
	# Create dialog panel
	var panel = Panel.new()
	panel.name = "DialogPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(400, 200)
	panel.position = Vector2(-200, -100)
	dialog_window.add_child(panel)
	
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
	label.text = "Хотите войти в норку?"
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
	yes_button.pressed.connect(_on_dialog_yes)
	buttons_container.add_child(yes_button)
	
	# Add "No" button
	var no_button = Button.new()
	no_button.text = "Нет"
	no_button.custom_minimum_size = Vector2(100, 40)
	no_button.pressed.connect(_on_dialog_no)
	buttons_container.add_child(no_button)
	
	# Add dialog to scene tree
	get_tree().root.add_child(dialog_window)
	print("[HOUSE] ✅ Dialog window created")


func _on_dialog_yes() -> void:
	print("[HOUSE] ✅ User clicked 'Да' - loading blocks scene")
	_close_dialog()
	_load_blocks_scene()


func _on_dialog_no() -> void:
	print("[HOUSE] ❌ User clicked 'Нет' - reloading house scene")
	_close_dialog()
	_load_house_scene()


func _close_dialog() -> void:
	if dialog_window:
		dialog_window.queue_free()
		dialog_window = null
		print("[HOUSE] Dialog window closed")
	
	# Note: Control will be enabled automatically when new scene loads
	# But if we need to re-enable without scene change, we can do:
	# if hero_mouse and hero_mouse.has_method("enable_control"):
	# 	hero_mouse.enable_control()


func _load_blocks_scene() -> void:
	var blocks_scene_path = "res://room/blocks.tscn"
	print("[HOUSE] Loading scene: ", blocks_scene_path)
	
	# Check if file exists
	if ResourceLoader.exists(blocks_scene_path):
		get_tree().change_scene_to_file(blocks_scene_path)
		print("[HOUSE] ✅ Scene changed to blocks successfully")
	else:
		print("[HOUSE] ❌ ERROR: Scene file not found at path: ", blocks_scene_path)


func _load_house_scene() -> void:
	var house_scene_path = "res://house/house.tscn"
	print("[HOUSE] Loading scene: ", house_scene_path)
	
	# Check if file exists
	if ResourceLoader.exists(house_scene_path):
		get_tree().change_scene_to_file(house_scene_path)
		print("[HOUSE] ✅ Scene changed to house successfully")
	else:
		print("[HOUSE] ❌ ERROR: Scene file not found at path: ", house_scene_path)
