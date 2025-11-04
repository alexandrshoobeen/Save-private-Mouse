extends Node2D

@onready var predator_awaking: Area2D = $PredatorAwaking
@onready var get_up_area: Area2D = $"get up"
@onready var jump_area: Area2D = $jump_area
@onready var entering_room: Area2D = $entering_room
@onready var predator_node: Node2D = $predator
@onready var trash_node: Node2D = $Trash
@onready var match_box: Area2D = $MatchBox
@onready var threads_node: Node2D = $threads
var hero_mouse: CharacterBody2D = null
var predator_awakened: bool = false
var is_jumping_to_trash: bool = false
var dialog_window: Control = null
var house_gui: CanvasLayer = null
var pickup_label: Label = null
var pickup_label_layer: CanvasLayer = null
var is_near_matchbox: bool = false
var matchbox_item_data: ItemData = null
var current_matchbox: Area2D = null  # Currently active MatchBox for pickup
var is_near_threads: bool = false
var threads_item_data: ItemData = null
var current_threads: Area2D = null  # Currently active threads pickup area

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
	hero_mouse.position = Vector2(550.0, 620.0)
	hero_mouse.z_index = 2  # Ensure hero_mouse is above threads (1) and tumba (0)
	add_child(hero_mouse)
	print("Hero mouse created: ", hero_mouse.name)
	
	# Set up MatchBox collision detection for initial MatchBox
	if match_box:
		match_box.monitoring = true
		match_box.monitorable = true
		match_box.body_entered.connect(_on_matchbox_body_entered)
		match_box.body_exited.connect(_on_matchbox_body_exited)
		match_box.area_entered.connect(_on_matchbox_area_entered)
		match_box.area_exited.connect(_on_matchbox_area_exited)
		print("[HOUSE] MatchBox collision detection set up")
	
	# Also set up for any existing MatchBox in scene
	_setup_all_matchboxes()
	
	# Set up threads collision detection
	if threads_node:
		var threads_pickup_area = threads_node.find_child("PickupArea", true, false)
		if threads_pickup_area and threads_pickup_area is Area2D:
			threads_pickup_area.monitoring = true
			threads_pickup_area.monitorable = true
			threads_pickup_area.body_entered.connect(_on_threads_body_entered)
			threads_pickup_area.body_exited.connect(_on_threads_body_exited)
			threads_pickup_area.area_entered.connect(_on_threads_area_entered)
			threads_pickup_area.area_exited.connect(_on_threads_area_exited)
			print("[HOUSE] Threads collision detection set up")
	
	# Load item data
	matchbox_item_data = load("res://room/ItemsResources/MatchBox.tres")
	
	# Create threads item data programmatically (not using .tres file from room)
	threads_item_data = ItemData.new()
	threads_item_data.type = ItemData.Type.MAIN
	threads_item_data.name = "Threads"
	threads_item_data.description = "This is threads"
	threads_item_data.texture = load("res://house/ниточки.png")
	threads_item_data.width = 320
	threads_item_data.height = 226
	threads_item_data.size = Vector2i(1, 1)
	
	# Create house GUI
	house_gui = CanvasLayer.new()
	house_gui.set_script(load("res://house/house_gui.gd"))
	add_child(house_gui)
	
	# Create pickup label (initially hidden)
	_create_pickup_label()


# CharacterBody2D will trigger body_entered signal, so we don't need manual position check
# But keeping this as backup in case signals don't work
func _input(event: InputEvent) -> void:
	# Handle E key press for pickup (single press)
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if is_near_matchbox:
			_pickup_matchbox()
		elif is_near_threads:
			_pickup_threads()

func _process(_delta: float) -> void:
	# Update pickup label position (convert world to screen coordinates)
	var target_item = null
	if is_near_matchbox and current_matchbox:
		target_item = current_matchbox
	elif is_near_threads and current_threads:
		target_item = current_threads
	
	if target_item and pickup_label:
		var world_pos = target_item.global_position
		world_pos.y -= 130  # Position above item (was 80, now 130 for 50px higher)
		
		# Convert world position to screen coordinates
		var viewport = get_viewport()
		var camera = viewport.get_camera_2d()
		if camera:
			# Get canvas transform to convert world to screen
			var canvas_transform = viewport.get_canvas_transform()
			var screen_pos = canvas_transform * world_pos
			pickup_label.position = screen_pos
		else:
			# Fallback: try to get screen position directly
			var screen_pos = viewport.get_screen_transform() * world_pos
			pickup_label.position = screen_pos
	
	# Manual check as backup (works even if signals don't trigger)
	if hero_mouse and predator_awaking:
		var is_in_zone = false
		var mouse_pos = hero_mouse.global_position
		
		# Check all CollisionShape2D nodes in PredatorAwaking
		for child in predator_awaking.get_children():
			if child is CollisionShape2D and child.shape:
				var shape = child.shape
				var zone_transform = child.global_transform
				var zone_pos = zone_transform.origin
				
				# Handle different shape types
				if shape is RectangleShape2D:
					var rect_shape = shape as RectangleShape2D
					var zone_size = rect_shape.size
					var zone_rect = Rect2(
						zone_pos.x - zone_size.x / 2,
						zone_pos.y - zone_size.y / 2,
						zone_size.x,
						zone_size.y
					)
					if zone_rect.has_point(mouse_pos):
						is_in_zone = true
						print("Manual check: hero_mouse at ", mouse_pos, " is in rectangle zone at ", zone_rect)
						break
				elif shape is CircleShape2D:
					var circle_shape = shape as CircleShape2D
					var radius = circle_shape.radius
					var distance = mouse_pos.distance_to(zone_pos)
					if distance <= radius:
						is_in_zone = true
						print("Manual check: hero_mouse at ", mouse_pos, " is in circle zone at ", zone_pos, " radius ", radius)
						break
				elif shape is CapsuleShape2D:
					var capsule_shape = shape as CapsuleShape2D
					# Simplified check for capsule - treat as circle
					var radius = capsule_shape.radius
					var distance = mouse_pos.distance_to(zone_pos)
					if distance <= radius + capsule_shape.height / 2:
						is_in_zone = true
						print("Manual check: hero_mouse at ", mouse_pos, " is in capsule zone at ", zone_pos)
						break
		
		# Update predator state based on zone presence
		if is_in_zone and not predator_awakened:
			if predator_node and predator_node.has_method("wake_up"):
				predator_node.wake_up()
				predator_awakened = true
			# Start death animation for Camera2D
			_start_camera_death_anim()
		elif not is_in_zone and predator_awakened:
			print("Manual check: hero_mouse left zone")
			if predator_node and predator_node.has_method("fall_asleep"):
				predator_node.fall_asleep()
				predator_awakened = false
			# Stop death animation for Camera2D
			_stop_camera_death_anim()
	
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
			
			# Start death animation for Camera2D
			_start_camera_death_anim()


func _on_predator_awaking_body_exited(body: Node) -> void:
	print("Body exited PredatorAwaking zone: ", body.name, " | Path: ", body.get_path())
	# Check if the exiting body is the hero_mouse
	if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
		print("Hero mouse left zone, putting predator to sleep")
		if predator_node and predator_node.has_method("fall_asleep"):
			predator_node.fall_asleep()
			predator_awakened = false
			print("Predator fell asleep")
		
		# Stop death animation for Camera2D
		_stop_camera_death_anim()


func _on_predator_awaking_area_entered(area: Area2D) -> void:
	# Check if the entering area belongs to hero_mouse
	if not predator_awakened and "HeroMouse" in area.get_path().get_concatenated_names():
		if predator_node and predator_node.has_method("wake_up"):
			predator_node.wake_up()
			predator_awakened = true
		
		# Start death animation for Camera2D
		_start_camera_death_anim()


func _on_predator_awaking_area_exited(area: Area2D) -> void:
	# Check if the exiting area belongs to hero_mouse
	if "HeroMouse" in area.get_path().get_concatenated_names():
		if predator_node and predator_node.has_method("fall_asleep"):
			predator_node.fall_asleep()
			predator_awakened = false
		
		# Stop death animation for Camera2D
		_stop_camera_death_anim()


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
				await get_tree().create_timer(0.5).timeout
				match_box.visible = true
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


# MatchBox pickup functions
func _on_matchbox_body_entered(body: Node) -> void:
	# Try to find the MatchBox that triggered this
	var matchbox_area = null
	for child in get_children():
		if child is Area2D and child.name == "MatchBox":
			if child.get_overlapping_bodies().has(body):
				matchbox_area = child
				break
	
	if not matchbox_area:
		matchbox_area = find_child("MatchBox", true, false) as Area2D
	
	_on_matchbox_body_entered_with_source(body, matchbox_area)

func _on_matchbox_body_entered_with_source(body: Node, matchbox_area: Area2D) -> void:
	print("[HOUSE] Body entered MatchBox area: ", body.name)
	if matchbox_area and (body.name == "HeroMouse" or "HeroMouse" in str(body.get_path())):
		current_matchbox = matchbox_area
		is_near_matchbox = true
		_show_pickup_label()
		print("[HOUSE] ✅ Hero mouse near MatchBox - showing pickup label")


func _on_matchbox_body_exited(body: Node) -> void:
	# Try to find the MatchBox that triggered this
	var matchbox_area = null
	for child in get_children():
		if child is Area2D and child.name == "MatchBox":
			if not child.get_overlapping_bodies().has(body):
				# Check if this was the one we were near
				if child == current_matchbox:
					matchbox_area = child
					break
	
	_on_matchbox_body_exited_with_source(body, matchbox_area)

func _on_matchbox_body_exited_with_source(body: Node, _matchbox_area: Area2D) -> void:
	print("[HOUSE] Body exited MatchBox area: ", body.name)
	if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
		# Check if we're still near any MatchBox
		var still_near = false
		for child in get_children():
			if child is Area2D and child.name == "MatchBox":
				if child.get_overlapping_bodies().has(body):
					current_matchbox = child
					still_near = true
					break
		
		if not still_near:
			is_near_matchbox = false
			current_matchbox = null
			_hide_pickup_label()
			print("[HOUSE] ✅ Hero mouse left MatchBox area")


func _on_matchbox_area_entered(area: Area2D) -> void:
	if "HeroMouse" in area.get_path().get_concatenated_names():
		# Find which MatchBox triggered this signal
		var matchbox_area = null
		for child in get_children():
			if child is Area2D and child.name == "MatchBox":
				if child.get_overlapping_areas().has(area):
					matchbox_area = child
					break
		
		_on_matchbox_area_entered_with_source(area, matchbox_area)

func _on_matchbox_area_entered_with_source(area: Area2D, matchbox_area: Area2D) -> void:
	if matchbox_area and "HeroMouse" in area.get_path().get_concatenated_names():
		current_matchbox = matchbox_area
		is_near_matchbox = true
		_show_pickup_label()
		print("[HOUSE] ✅ Hero mouse area entered MatchBox - showing pickup label")


func _on_matchbox_area_exited(area: Area2D) -> void:
	if "HeroMouse" in area.get_path().get_concatenated_names():
		# Find which MatchBox triggered this signal
		var matchbox_area = null
		for child in get_children():
			if child is Area2D and child.name == "MatchBox":
				if not child.get_overlapping_areas().has(area):
					if child == current_matchbox:
						matchbox_area = child
						break
		
		_on_matchbox_area_exited_with_source(area, matchbox_area)

func _on_matchbox_area_exited_with_source(area: Area2D, _matchbox_area: Area2D) -> void:
	if "HeroMouse" in area.get_path().get_concatenated_names():
		# Check if we're still near any MatchBox
		var still_near = false
		for child in get_children():
			if child is Area2D and child.name == "MatchBox":
				if child.get_overlapping_areas().has(area):
					current_matchbox = child
					still_near = true
					break
		
		if not still_near:
			is_near_matchbox = false
			current_matchbox = null
			_hide_pickup_label()
			print("[HOUSE] ✅ Hero mouse area exited MatchBox")


func _create_pickup_label() -> void:
	# Create CanvasLayer for pickup label
	pickup_label_layer = CanvasLayer.new()
	pickup_label_layer.name = "PickupLabelLayer"
	add_child(pickup_label_layer)
	
	# Create Label
	pickup_label = Label.new()
	pickup_label.name = "PickupLabel"
	pickup_label.text = "взять 'E'"
	pickup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pickup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pickup_label.add_theme_font_size_override("font_size", 24)
	pickup_label.modulate = Color.WHITE
	# Add outline effect using add_theme_color_override
	pickup_label.add_theme_color_override("font_color", Color.WHITE)
	pickup_label.add_theme_color_override("font_outline_color", Color.BLACK)
	pickup_label.add_theme_constant_override("outline_size", 4)
	pickup_label.visible = false
	pickup_label_layer.add_child(pickup_label)
	print("[HOUSE] Pickup label created")


func _setup_all_matchboxes() -> void:
	# Set up collision detection for all MatchBox instances in scene
	for child in get_children():
		if child is Area2D and child.name == "MatchBox":
			if not child.body_entered.is_connected(_on_matchbox_body_entered):
				child.monitoring = true
				child.monitorable = true
				child.body_entered.connect(_on_matchbox_body_entered)
				child.body_exited.connect(_on_matchbox_body_exited)
				child.area_entered.connect(_on_matchbox_area_entered)
				child.area_exited.connect(_on_matchbox_area_exited)
				print("[HOUSE] MatchBox collision detection set up for: ", child.name)

func _show_pickup_label() -> void:
	if pickup_label:
		pickup_label.visible = true
		# Position will be updated in _process
		# Show label if near any item
		if is_near_matchbox or is_near_threads:
			pickup_label.visible = true


func _hide_pickup_label() -> void:
	if pickup_label:
		# Hide label only if not near any item
		if not is_near_matchbox and not is_near_threads:
			pickup_label.visible = false

# Threads pickup functions
func _on_threads_body_entered(body: Node) -> void:
	# Try to find threads node
	var threads_node_found = threads_node
	if not threads_node_found:
		threads_node_found = find_child("threads", true, false) as Node2D
	
	_on_threads_body_entered_with_source(body, threads_node_found)

func _on_threads_body_entered_with_source(body: Node, threads_node_source: Node2D) -> void:
	print("[HOUSE] Body entered Threads area: ", body.name)
	if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
		# Find threads pickup area
		var threads_area = null
		if threads_node_source:
			threads_area = threads_node_source.find_child("PickupArea", true, false) as Area2D
		else:
			# Try to find any threads in scene
			var threads_nodes = []
			for child in get_children():
				if child is Node2D and child.name == "threads":
					threads_nodes.append(child)
			if threads_nodes.size() > 0:
				threads_area = threads_nodes[0].find_child("PickupArea", true, false) as Area2D
				threads_node = threads_nodes[0]
		
		if threads_area:
			current_threads = threads_area
			is_near_threads = true
			_show_pickup_label()
			print("[HOUSE] ✅ Hero mouse near Threads - showing pickup label")

func _on_threads_body_exited(body: Node) -> void:
	# Try to find threads node
	var threads_node_found = threads_node
	if not threads_node_found:
		threads_node_found = find_child("threads", true, false) as Node2D
	
	_on_threads_body_exited_with_source(body, threads_node_found)

func _on_threads_body_exited_with_source(body: Node, threads_node_source: Node2D) -> void:
	print("[HOUSE] Body exited Threads area: ", body.name)
	if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
		# Check if we're still near threads
		var still_near = false
		if threads_node_source:
			var threads_area = threads_node_source.find_child("PickupArea", true, false) as Area2D
			if threads_area and threads_area.get_overlapping_bodies().has(body):
				current_threads = threads_area
				still_near = true
		
		if not still_near:
			# Check all threads in scene
			for child in get_children():
				if child is Node2D and child.name == "threads":
					var threads_area = child.find_child("PickupArea", true, false) as Area2D
					if threads_area and threads_area.get_overlapping_bodies().has(body):
						current_threads = threads_area
						threads_node = child
						still_near = true
						break
		
		if not still_near:
			is_near_threads = false
			current_threads = null
			_hide_pickup_label()
			print("[HOUSE] ✅ Hero mouse left Threads area")

func _on_threads_area_entered(area: Area2D) -> void:
	# Try to find threads node
	var threads_node_found = threads_node
	if not threads_node_found:
		threads_node_found = find_child("threads", true, false) as Node2D
	
	_on_threads_area_entered_with_source(area, threads_node_found)

func _on_threads_area_entered_with_source(area: Area2D, threads_node_source: Node2D) -> void:
	if "HeroMouse" in area.get_path().get_concatenated_names():
		# Find threads pickup area
		var threads_area = null
		if threads_node_source:
			threads_area = threads_node_source.find_child("PickupArea", true, false) as Area2D
		
		if threads_area:
			current_threads = threads_area
			is_near_threads = true
			_show_pickup_label()
			print("[HOUSE] ✅ Hero mouse area entered Threads - showing pickup label")

func _on_threads_area_exited(area: Area2D) -> void:
	# Try to find threads node
	var threads_node_found = threads_node
	if not threads_node_found:
		threads_node_found = find_child("threads", true, false) as Node2D
	
	_on_threads_area_exited_with_source(area, threads_node_found)

func _on_threads_area_exited_with_source(area: Area2D, threads_node_source: Node2D) -> void:
	if "HeroMouse" in area.get_path().get_concatenated_names():
		# Check if we're still near threads
		var still_near = false
		if threads_node_source:
			var threads_area = threads_node_source.find_child("PickupArea", true, false) as Area2D
			if threads_area and threads_area.get_overlapping_areas().has(area):
				current_threads = threads_area
				still_near = true
		
		if not still_near:
			# Check all threads in scene
			for child in get_children():
				if child is Node2D and child.name == "threads":
					var threads_area = child.find_child("PickupArea", true, false) as Area2D
					if threads_area and threads_area.get_overlapping_areas().has(area):
						current_threads = threads_area
						threads_node = child
						still_near = true
						break
		
		if not still_near:
			is_near_threads = false
			current_threads = null
			_hide_pickup_label()
			print("[HOUSE] ✅ Hero mouse area exited Threads")

# Camera2D death animation functions
func _start_camera_death_anim() -> void:
	if hero_mouse:
		var camera = hero_mouse.find_child("Camera2D", true, false)
		if camera:
			var animation_player = camera.find_child("AnimationPlayer", true, false)
			if animation_player and animation_player.has_animation("death_anim"):
				animation_player.play("death_anim")
				print("[HOUSE] ✅ Camera2D death animation started")
			else:
				print("[HOUSE] ❌ Camera2D AnimationPlayer or death_anim not found")

func _stop_camera_death_anim() -> void:
	if hero_mouse:
		var camera = hero_mouse.find_child("Camera2D", true, false)
		if camera:
			var animation_player = camera.find_child("AnimationPlayer", true, false)
			if animation_player:
				if animation_player.has_animation("RESET"):
					animation_player.play("RESET")
				else:
					animation_player.stop()
				print("[HOUSE] ✅ Camera2D death animation stopped")
			else:
				print("[HOUSE] ❌ Camera2D AnimationPlayer not found")


func _pickup_matchbox() -> void:
	if not is_near_matchbox or not current_matchbox or not matchbox_item_data:
		return
	
	print("[HOUSE] ✅ Picking up MatchBox...")
	
	# Add item to inventory
	if house_gui and house_gui.has_method("add_item_to_inventory"):
		if house_gui.add_item_to_inventory(matchbox_item_data):
			# Add to Global.inventory_data
			Global.inventory_data.append({
				"name": matchbox_item_data.name,
				"texture_path": matchbox_item_data.texture.resource_path if matchbox_item_data.texture else "",
				"size": matchbox_item_data.size,
				"description": matchbox_item_data.description
			})
			print("[HOUSE] ✅ MatchBox added to Global.inventory_data")
			print("[HOUSE] 📦 Global.inventory_data contents after pickup: ", Global.inventory_data)
			
			# Remove MatchBox from scene
			var matchbox_to_remove = current_matchbox
			current_matchbox = null
			matchbox_to_remove.queue_free()
			is_near_matchbox = false
			_hide_pickup_label()
			print("[HOUSE] ✅ MatchBox picked up and added to inventory!")
		else:
			print("[HOUSE] ❌ Inventory is full! Only one item allowed.")
			# Можно показать сообщение игроку, что инвентарь полон
	else:
		print("[HOUSE] ❌ ERROR: house_gui or add_item_to_inventory method not found!")

func _pickup_threads() -> void:
	if not is_near_threads or not current_threads or not threads_item_data:
		return
	
	print("[HOUSE] ✅ Picking up Threads...")
	
	# Add item to inventory
	if house_gui and house_gui.has_method("add_item_to_inventory"):
		if house_gui.add_item_to_inventory(threads_item_data):
			# Add to Global.inventory_data
			Global.inventory_data.append({
				"name": threads_item_data.name,
				"texture_path": threads_item_data.texture.resource_path if threads_item_data.texture else "",
				"size": threads_item_data.size,
				"description": threads_item_data.description
			})
			print("[HOUSE] ✅ Threads added to Global.inventory_data")
			print("[HOUSE] 📦 Global.inventory_data contents after pickup: ", Global.inventory_data)
			
			# Find and remove threads from scene
			var threads_to_remove = threads_node
			if not threads_to_remove:
				# Try to find threads by current_threads parent
				if current_threads:
					threads_to_remove = current_threads.get_parent() as Node2D
				if not threads_to_remove:
					threads_to_remove = find_child("threads", true, false) as Node2D
			
			if threads_to_remove:
				threads_to_remove.queue_free()
				if threads_to_remove == threads_node:
					threads_node = null
			
			current_threads = null
			is_near_threads = false
			_hide_pickup_label()
			print("[HOUSE] ✅ Threads picked up and added to inventory!")
		else:
			print("[HOUSE] ❌ Inventory is full! Only one item allowed.")
	else:
		print("[HOUSE] ❌ ERROR: house_gui or add_item_to_inventory method not found!")
