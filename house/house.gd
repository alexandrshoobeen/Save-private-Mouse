extends Node2D

@onready var predator_awaking: Area2D = $PredatorAwaking
@onready var get_up_area: Area2D = $"get up"
@onready var jump_area: Area2D = $jump_area
@onready var throw_area: Area2D = $throw_area
@onready var entering_room: Area2D = $entering_room
@onready var predator_node: Node2D = $predator
@onready var trash_node: Node2D = $Trash
@onready var trash_detected_area: Area2D = $Trash/detected
@onready var match_box: Area2D = $MatchBox
@onready var threads_node: Node2D = $threads
@onready var candy_node: Area2D = $candy
var hero_mouse: CharacterBody2D = null
var predator_awakened: bool = false
var is_jumping_to_trash: bool = false
var dialog_window: CanvasLayer = null
var house_gui: CanvasLayer = null
var pickup_label: Label = null
var pickup_label_layer: CanvasLayer = null
var jump_label: Label = null
var jump_label_layer: CanvasLayer = null
var is_near_jump_area: bool = false
var throw_warning_label: Label = null
var throw_warning_label_layer: CanvasLayer = null
var throw_candy_label: Label = null
var throw_candy_label_layer: CanvasLayer = null
var is_near_throw_area: bool = false
var is_throwing_candy: bool = false
var trash_jump_label: Label = null
var trash_jump_label_layer: CanvasLayer = null
var is_near_trash_detected: bool = false
var is_near_matchbox: bool = false
var matchbox_item_data: ItemData = null
var current_matchbox: Area2D = null  # Currently active MatchBox for pickup
var is_near_threads: bool = false
var threads_item_data: ItemData = null
var current_threads: Area2D = null  # Currently active threads pickup area
var is_near_candy: bool = false
var candy_item_data: ItemData = null
var current_candy: Area2D = null  # Currently active candy for pickup
var is_near_princess_mouse: bool = false
var princess_mouse_item_data: ItemData = null
var current_princess_mouse: Area2D = null  # Currently active princess_mouse for pickup
var death_anim_continuous_start_time: float = 0.0  # Time when current continuous playback started
var death_anim_animation_player: AnimationPlayer = null
var death_anim_control_disabled: bool = false
var death_anim_is_playing: bool = false  # Track if animation is currently playing

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set up collisions (StaticBody2D) for physical obstacles
	var collisions_node = find_child("collisions", true, false)
	if collisions_node:
		# If it's Area2D, we need to convert it or ensure it's StaticBody2D
		# For now, let's set collision_layer = 2 for obstacles
		if collisions_node is Area2D:
			# Convert Area2D to StaticBody2D for physical collisions
			var collision_shapes = []
			for child in collisions_node.get_children():
				if child is CollisionShape2D:
					collision_shapes.append(child)
			
			# Create StaticBody2D
			var static_body = StaticBody2D.new()
			static_body.name = "collisions"
			static_body.collision_layer = 2  # Layer 2 for obstacles
			static_body.collision_mask = 0    # StaticBody doesn't need mask
			
			# Move collision shapes to StaticBody2D
			for shape_node in collision_shapes:
				collisions_node.remove_child(shape_node)
				static_body.add_child(shape_node)
			
			# Replace Area2D with StaticBody2D
			var parent = collisions_node.get_parent()
			var index = collisions_node.get_index()
			collisions_node.queue_free()
			parent.add_child(static_body)
			parent.move_child(static_body, index)
			print("[HOUSE] ✅ Converted collisions Area2D to StaticBody2D for physical collisions")
		elif collisions_node is StaticBody2D:
			collisions_node.collision_layer = 2  # Layer 2 for obstacles
			collisions_node.collision_mask = 0
			print("[HOUSE] ✅ Set collisions StaticBody2D collision_layer = 2")
	
	# Ensure Area2D is monitoring
	if predator_awaking:
		predator_awaking.monitoring = true
		predator_awaking.monitorable = false
		# Set collision mask to detect hero_mouse on layer 1
		predator_awaking.collision_mask = 1  # Layer 1
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
		# Set collision mask to detect hero_mouse on layer 1
		get_up_area.collision_mask = 1  # Layer 1
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
		# Set collision mask to detect hero_mouse on layer 1
		jump_area.collision_mask = 1  # Layer 1
		jump_area.body_entered.connect(_on_jump_area_body_entered)
		jump_area.body_exited.connect(_on_jump_area_body_exited)
		jump_area.area_entered.connect(_on_jump_area_area_entered)
		jump_area.area_exited.connect(_on_jump_area_area_exited)
		print("[HOUSE] Jump area set up and monitoring: ", jump_area.monitoring)
	else:
		print("[HOUSE] ERROR: jump_area is null!")
	
	# Set up "throw_area"
	if throw_area:
		throw_area.monitoring = true
		throw_area.monitorable = false
		# Set collision mask to detect hero_mouse on layer 1
		throw_area.collision_mask = 1  # Layer 1
		throw_area.body_entered.connect(_on_throw_area_body_entered)
		throw_area.body_exited.connect(_on_throw_area_body_exited)
		throw_area.area_entered.connect(_on_throw_area_area_entered)
		throw_area.area_exited.connect(_on_throw_area_area_exited)
		print("[HOUSE] Throw area set up and monitoring: ", throw_area.monitoring)
	else:
		print("[HOUSE] ERROR: throw_area is null!")
	
	# Set up "trash_detected_area" (Area2D inside Trash)
	if trash_detected_area:
		trash_detected_area.monitoring = true
		trash_detected_area.monitorable = false
		# Set collision mask to detect hero_mouse on layer 1
		trash_detected_area.collision_mask = 1  # Layer 1
		trash_detected_area.body_entered.connect(_on_trash_detected_body_entered)
		trash_detected_area.body_exited.connect(_on_trash_detected_body_exited)
		trash_detected_area.area_entered.connect(_on_trash_detected_area_entered)
		trash_detected_area.area_exited.connect(_on_trash_detected_area_exited)
		print("[HOUSE] Trash detected area set up and monitoring: ", trash_detected_area.monitoring)
	else:
		print("[HOUSE] ERROR: trash_detected_area is null!")
	
	# Set up "entering_room" area
	if entering_room:
		entering_room.monitoring = true
		entering_room.monitorable = false
		# Set collision mask to detect hero_mouse on layer 1
		entering_room.collision_mask = 1  # Layer 1
		entering_room.body_entered.connect(_on_entering_room_body_entered)
		print("[HOUSE] Entering room area set up and monitoring: ", entering_room.monitoring)
	else:
		print("[HOUSE] ERROR: entering_room is null!")
	
	# Create and add hero_mouse
	var hero_mouse_scene = preload("res://heroMouse/hero_mouse.tscn")
	hero_mouse = hero_mouse_scene.instantiate()
	hero_mouse.position = Vector2(550.0, 560.0)
	hero_mouse.z_index = 2  # Ensure hero_mouse is above threads (1) and tumba (0)
	
	# Set collision layer for hero_mouse (layer 1 = bit 0)
	# This allows Area2D to detect it
	hero_mouse.collision_layer = 1  # Layer 1
	# Set collision_mask to collide with obstacles (layer 2) and for Area2D detection (layer 1)
	hero_mouse.collision_mask = 1 | 2  # Can collide with layer 1 (Area2D) and layer 2 (StaticBody2D obstacles)
	
	add_child(hero_mouse)
	print("Hero mouse created: ", hero_mouse.name)
	
	# Set up MatchBox collision detection for initial MatchBox
	if match_box:
		match_box.monitoring = true
		match_box.monitorable = true
		# Set collision mask to detect hero_mouse on layer 1
		match_box.collision_mask = 1  # Layer 1
		match_box.body_entered.connect(_on_matchbox_body_entered)
		match_box.body_exited.connect(_on_matchbox_body_exited)
		match_box.area_entered.connect(_on_matchbox_area_entered)
		match_box.area_exited.connect(_on_matchbox_area_exited)
		print("[HOUSE] MatchBox collision detection set up")
	
	# Also set up for any existing MatchBox in scene
	_setup_all_matchboxes()
	
	# Also set up for any existing candy in scene
	_setup_all_candies()
	
	# Set up threads collision detection
	if threads_node:
		var threads_pickup_area = threads_node.find_child("PickupArea", true, false)
		if threads_pickup_area and threads_pickup_area is Area2D:
			threads_pickup_area.monitoring = true
			threads_pickup_area.monitorable = true
			# Set collision mask to detect hero_mouse on layer 1
			threads_pickup_area.collision_mask = 1  # Layer 1
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
	
	# Create candy item data programmatically (not using .tres file from room)
	candy_item_data = ItemData.new()
	candy_item_data.type = ItemData.Type.MAIN
	candy_item_data.name = "Candy"
	candy_item_data.description = "This is candy"
	candy_item_data.texture = load("res://house/конфеточька.png")
	candy_item_data.width = 320
	candy_item_data.height = 250
	candy_item_data.size = Vector2i(1, 1)
	
	# Create princess_mouse item data programmatically
	princess_mouse_item_data = ItemData.new()
	princess_mouse_item_data.type = ItemData.Type.MAIN
	princess_mouse_item_data.name = "PrincessMouse"
	princess_mouse_item_data.description = "This is princess mouse"
	princess_mouse_item_data.texture = load("res://house/мышочька.png")
	princess_mouse_item_data.width = 320
	princess_mouse_item_data.height = 250
	princess_mouse_item_data.size = Vector2i(1, 1)
	
	# Create house GUI
	house_gui = CanvasLayer.new()
	house_gui.set_script(load("res://house/house_gui.gd"))
	add_child(house_gui)
	
	# Create pickup label (initially hidden)
	_create_pickup_label()
	
	# Create jump label (initially hidden)
	_create_jump_label()
	
	# Create throw warning label (initially hidden)
	_create_throw_warning_label()
	
	# Create throw candy label (initially hidden)
	_create_throw_candy_label()
	
	# Create trash jump label (initially hidden)
	_create_trash_jump_label()


# CharacterBody2D will trigger body_entered signal, so we don't need manual position check
# But keeping this as backup in case signals don't work
func _input(event: InputEvent) -> void:
	# Handle E key press for pickup (single press)
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if is_near_throw_area and _has_candy_in_inventory() and not is_throwing_candy:
			_throw_candy()
		elif is_near_matchbox:
			_pickup_matchbox()
		elif is_near_threads:
			_pickup_threads()
		elif is_near_candy:
			_pickup_candy()
		elif is_near_princess_mouse:
			_pickup_princess_mouse()
	
	# Handle SPACE key press for jump
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if is_near_jump_area and not is_jumping_to_trash and hero_mouse:
			print("[HOUSE] ✅ SPACE pressed in jump_area! Starting jump animation...")
			_hide_jump_label()
			_start_jump_to_trash_animation(hero_mouse)

func _process(_delta: float) -> void:
	# Update pickup label position (convert world to screen coordinates)
	var target_item = null
	if is_near_matchbox and current_matchbox and current_matchbox.visible:
		target_item = current_matchbox
	elif is_near_threads and current_threads:
		target_item = current_threads
	elif is_near_candy and current_candy:
		target_item = current_candy
	elif is_near_princess_mouse and current_princess_mouse:
		target_item = current_princess_mouse
	
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
	
	# Update jump label position
	if is_near_jump_area and jump_area and jump_label:
		# Find CollisionShape2D inside jump_area
		var collision_shape = jump_area.find_child("CollisionShape2D", true, false)
		var world_pos: Vector2
		if collision_shape:
			# Use CollisionShape2D global position
			world_pos = collision_shape.global_position
			# Get shape bounds to position label at top
			if collision_shape.shape:
				if collision_shape.shape is RectangleShape2D:
					var rect_shape = collision_shape.shape as RectangleShape2D
					world_pos.y -= rect_shape.size.y / 2 + 20  # 20px above CollisionShape2D
				elif collision_shape.shape is CircleShape2D:
					var circle_shape = collision_shape.shape as CircleShape2D
					world_pos.y -= circle_shape.radius + 20  # 20px above CollisionShape2D
				else:
					world_pos.y -= 20  # Fallback: 20px above center
			else:
				world_pos.y -= 20  # Fallback: 20px above center
		else:
			# Fallback: use jump_area position if CollisionShape2D not found
			world_pos = jump_area.global_position
			world_pos.y -= 20
		
		# Convert world position to screen coordinates
		var viewport = get_viewport()
		var camera = viewport.get_camera_2d()
		if camera:
			var canvas_transform = viewport.get_canvas_transform()
			var screen_pos = canvas_transform * world_pos
			jump_label.position = screen_pos
		else:
			var screen_pos = viewport.get_screen_transform() * world_pos
			jump_label.position = screen_pos
	
	# Update throw area labels position and check candy status
	if is_near_throw_area and throw_area:
		var has_candy = _has_candy_in_inventory()
		
		# Find CollisionShape2D inside throw_area for positioning
		var collision_shape = throw_area.find_child("CollisionShape2D", true, false)
		var world_pos: Vector2
		if collision_shape:
			# Use CollisionShape2D global position
			world_pos = collision_shape.global_position
			# Get shape bounds to position label at top
			if collision_shape.shape:
				if collision_shape.shape is RectangleShape2D:
					var rect_shape = collision_shape.shape as RectangleShape2D
					world_pos.y -= rect_shape.size.y / 2 + 20  # 20px above CollisionShape2D
				elif collision_shape.shape is CircleShape2D:
					var circle_shape = collision_shape.shape as CircleShape2D
					world_pos.y -= circle_shape.radius + 20  # 20px above CollisionShape2D
				else:
					world_pos.y -= 20  # Fallback: 20px above center
			else:
				world_pos.y -= 20  # Fallback: 20px above center
		else:
			# Fallback: use throw_area position if CollisionShape2D not found
			world_pos = throw_area.global_position
			world_pos.y -= 20
		
		# Convert world position to screen coordinates
		var viewport = get_viewport()
		var camera = viewport.get_camera_2d()
		var screen_pos: Vector2
		if camera:
			var canvas_transform = viewport.get_canvas_transform()
			screen_pos = canvas_transform * world_pos
		else:
			screen_pos = viewport.get_screen_transform() * world_pos
		
		# Show appropriate label based on candy status
		if has_candy:
			# Show throw candy label
			if throw_candy_label:
				throw_candy_label.position = screen_pos
			if throw_warning_label:
				throw_warning_label.visible = false
			# Enable left movement if candy is available
			if hero_mouse and hero_mouse.has_method("enable_left_movement"):
				hero_mouse.enable_left_movement()
		else:
			# Show warning label
			if throw_warning_label:
				throw_warning_label.position = screen_pos
			if throw_candy_label:
				throw_candy_label.visible = false
	
	# Update trash jump label position
	if is_near_trash_detected and trash_detected_area and trash_jump_label:
		# Find CollisionShape2D inside trash_detected_area
		var collision_shape = trash_detected_area.find_child("CollisionShape2D", true, false)
		var world_pos: Vector2
		if collision_shape:
			# Use CollisionShape2D global position
			world_pos = collision_shape.global_position
			# Get shape bounds to position label at top
			if collision_shape.shape:
				if collision_shape.shape is RectangleShape2D:
					var rect_shape = collision_shape.shape as RectangleShape2D
					world_pos.y -= rect_shape.size.y / 2 + 20  # 20px above CollisionShape2D
				elif collision_shape.shape is CircleShape2D:
					var circle_shape = collision_shape.shape as CircleShape2D
					world_pos.y -= circle_shape.radius + 20  # 20px above CollisionShape2D
				else:
					world_pos.y -= 20  # Fallback: 20px above center
			else:
				world_pos.y -= 20  # Fallback: 20px above center
		else:
			# Fallback: use trash_detected_area position if CollisionShape2D not found
			world_pos = trash_detected_area.global_position
			world_pos.y -= 20
		
		# Convert world position to screen coordinates
		var viewport = get_viewport()
		var camera = viewport.get_camera_2d()
		if camera:
			var canvas_transform = viewport.get_canvas_transform()
			var screen_pos = canvas_transform * world_pos
			trash_jump_label.position = screen_pos
		else:
			var screen_pos = viewport.get_screen_transform() * world_pos
			trash_jump_label.position = screen_pos
	
	# Check death animation continuous duration
	if death_anim_animation_player and death_anim_continuous_start_time > 0.0:
		var current_time = Time.get_ticks_msec() / 1000.0
		var is_currently_playing = (death_anim_animation_player.is_playing() and 
									death_anim_animation_player.current_animation == "death_anim")
		
		if is_currently_playing:
			# Animation is playing - check if it's been playing for 4.5+ seconds continuously
			var continuous_duration = current_time - death_anim_continuous_start_time
			
			if continuous_duration >= 4.5:
				# Animation has been playing continuously for 4.5+ seconds
				if not death_anim_control_disabled:
					# Disable control and load game over scene
					if hero_mouse and hero_mouse.has_method("disable_control"):
						hero_mouse.disable_control()
						death_anim_control_disabled = true
						print("[HOUSE] ⚠️ Death animation playing continuously for 4.5+ seconds - control disabled")
					
					# Load game over scene with delay
					_load_game_over_with_delay()
		else:
			# Animation stopped or changed - reset continuous timer
			if death_anim_is_playing:
				death_anim_continuous_start_time = 0.0
				death_anim_is_playing = false
				print("[HOUSE] Death animation stopped - continuous timer reset")
	
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
						break
				elif shape is CircleShape2D:
					var circle_shape = shape as CircleShape2D
					var radius = circle_shape.radius
					var distance = mouse_pos.distance_to(zone_pos)
					if distance <= radius:
						is_in_zone = true
						break
				elif shape is CapsuleShape2D:
					var capsule_shape = shape as CapsuleShape2D
					# Simplified check for capsule - treat as circle
					var radius = capsule_shape.radius
					var distance = mouse_pos.distance_to(zone_pos)
					if distance <= radius + capsule_shape.height / 2:
						is_in_zone = true
						break
		
		# Update predator state based on zone presence
		if is_in_zone and not predator_awakened:
			if predator_node and predator_node.has_method("wake_up"):
				predator_node.wake_up()
				predator_awakened = true
			# Start death animation for Camera2D
			_start_camera_death_anim()
		elif not is_in_zone and predator_awakened:
			if predator_node and predator_node.has_method("fall_asleep"):
				predator_node.fall_asleep()
				predator_awakened = false
			# Stop death animation for Camera2D
			_stop_camera_death_anim()
	
	# Manual check for "get up" areas is disabled
	# We rely on signals (body_entered/exited) for state changes
	# This is more efficient and avoids constant state checks every frame
	# Signals will handle state changes automatically when hero_mouse enters/exits zones


func _on_predator_awaking_body_entered(body: Node) -> void:
	# Check if the entering body is the hero_mouse (CharacterBody2D will trigger this)
	if not predator_awakened:
		if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
			if predator_node:
				if predator_node.has_method("wake_up"):
					predator_node.wake_up()
					predator_awakened = true
				else:
					print("[HOUSE] ERROR: predator_node doesn't have wake_up method")
			else:
				print("[HOUSE] ERROR: predator_node is null")
			
			# Start death animation for Camera2D
			_start_camera_death_anim()


func _on_predator_awaking_body_exited(body: Node) -> void:
	# Check if the exiting body is the hero_mouse
	if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
		if predator_node and predator_node.has_method("fall_asleep"):
			predator_node.fall_asleep()
			predator_awakened = false
		
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
	# Check if it's hero_mouse (by name, path, or direct comparison)
	var is_hero = (body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()) or body == hero_mouse)
	if is_hero:
		if not is_jumping_to_trash:
			print("[HOUSE] ✅ Hero mouse detected in jump_area! Showing jump prompt...")
			is_near_jump_area = true
			_show_jump_label()
			# Disable right movement when entering jump_area
			if body.has_method("disable_right_movement"):
				body.disable_right_movement()
				print("[HOUSE] ✅ Right movement disabled for hero_mouse")
			if jump_label:
				print("[HOUSE] Jump label visible: ", jump_label.visible)
			else:
				print("[HOUSE] Jump label is null!")


func _on_jump_area_body_exited(body: Node) -> void:
	print("[HOUSE] 🦘 Body exited jump_area: ", body.name, " | Path: ", body.get_path())
	if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
		# Check if we're still in jump_area (via area detection)
		var still_near = false
		if jump_area:
			# Check if hero_mouse is still overlapping via area
			for area in jump_area.get_overlapping_areas():
				if "HeroMouse" in area.get_path().get_concatenated_names():
					still_near = true
					break
		
		if not still_near:
			print("[HOUSE] ✅ Hero mouse left jump_area!")
			is_near_jump_area = false
			_hide_jump_label()
			# Re-enable right movement when leaving jump_area
			if body.has_method("enable_right_movement"):
				body.enable_right_movement()
				print("[HOUSE] ✅ Right movement enabled for hero_mouse")


func _on_jump_area_area_entered(area: Area2D) -> void:
	print("[HOUSE] 🦘 Area entered jump_area: ", area.get_path())
	if "HeroMouse" in area.get_path().get_concatenated_names():
		if not is_jumping_to_trash:
			print("[HOUSE] ✅ Hero mouse area detected in jump_area! Showing jump prompt...")
			is_near_jump_area = true
			_show_jump_label()
			# Disable right movement when entering jump_area
			if hero_mouse and hero_mouse.has_method("disable_right_movement"):
				hero_mouse.disable_right_movement()
				print("[HOUSE] ✅ Right movement disabled for hero_mouse")
			if jump_label:
				print("[HOUSE] Jump label visible: ", jump_label.visible)
			else:
				print("[HOUSE] Jump label is null!")


func _on_jump_area_area_exited(area: Area2D) -> void:
	print("[HOUSE] 🦘 Area exited jump_area: ", area.get_path())
	if "HeroMouse" in area.get_path().get_concatenated_names():
		# Check if we're still in jump_area (via body detection)
		var still_near = false
		if jump_area and hero_mouse:
			# Check if hero_mouse body is still overlapping
			for body in jump_area.get_overlapping_bodies():
				if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
					still_near = true
					break
		
		if not still_near:
			print("[HOUSE] ✅ Hero mouse area left jump_area!")
			is_near_jump_area = false
			_hide_jump_label()
			# Re-enable right movement when leaving jump_area
			if hero_mouse and hero_mouse.has_method("enable_right_movement"):
				hero_mouse.enable_right_movement()
				print("[HOUSE] ✅ Right movement enabled for hero_mouse")


func _on_throw_area_body_entered(body: Node) -> void:
	print("[HOUSE] 🎯 Body entered throw_area: ", body.name, " | Path: ", body.get_path())
	# Check if it's hero_mouse (by name, path, or direct comparison)
	var is_hero = (body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()) or body == hero_mouse)
	if is_hero:
		is_near_throw_area = true
		# Check if candy is in inventory
		if _has_candy_in_inventory():
			print("[HOUSE] ✅ Hero mouse detected in throw_area with candy! Showing throw prompt...")
			_hide_throw_warning_label()
			_show_throw_candy_label()
		else:
			print("[HOUSE] ✅ Hero mouse detected in throw_area without candy! Showing warning...")
			_hide_throw_candy_label()
			_show_throw_warning_label()
			# Disable left movement when entering throw_area without candy
			if body.has_method("disable_left_movement"):
				body.disable_left_movement()
				print("[HOUSE] ✅ Left movement disabled for hero_mouse")


func _on_throw_area_body_exited(body: Node) -> void:
	print("[HOUSE] 🎯 Body exited throw_area: ", body.name, " | Path: ", body.get_path())
	if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
		# Check if we're still in throw_area (via area detection)
		var still_near = false
		if throw_area:
			# Check if hero_mouse is still overlapping via area
			for area in throw_area.get_overlapping_areas():
				if "HeroMouse" in area.get_path().get_concatenated_names():
					still_near = true
					break
		
		if not still_near:
			print("[HOUSE] ✅ Hero mouse left throw_area!")
			is_near_throw_area = false
			_hide_throw_warning_label()
			_hide_throw_candy_label()
			# Re-enable left movement when leaving throw_area
			if body.has_method("enable_left_movement"):
				body.enable_left_movement()
				print("[HOUSE] ✅ Left movement enabled for hero_mouse")


func _on_throw_area_area_entered(area: Area2D) -> void:
	print("[HOUSE] 🎯 Area entered throw_area: ", area.get_path())
	if "HeroMouse" in area.get_path().get_concatenated_names():
		is_near_throw_area = true
		# Check if candy is in inventory
		if _has_candy_in_inventory():
			print("[HOUSE] ✅ Hero mouse area detected in throw_area with candy! Showing throw prompt...")
			_hide_throw_warning_label()
			_show_throw_candy_label()
		else:
			print("[HOUSE] ✅ Hero mouse area detected in throw_area without candy! Showing warning...")
			_hide_throw_candy_label()
			_show_throw_warning_label()
			# Disable left movement when entering throw_area without candy
			if hero_mouse and hero_mouse.has_method("disable_left_movement"):
				hero_mouse.disable_left_movement()
				print("[HOUSE] ✅ Left movement disabled for hero_mouse")


func _on_throw_area_area_exited(area: Area2D) -> void:
	print("[HOUSE] 🎯 Area exited throw_area: ", area.get_path())
	if "HeroMouse" in area.get_path().get_concatenated_names():
		# Check if we're still in throw_area (via body detection)
		var still_near = false
		if throw_area and hero_mouse:
			# Check if hero_mouse body is still overlapping
			for body in throw_area.get_overlapping_bodies():
				if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
					still_near = true
					break
		
		if not still_near:
			print("[HOUSE] ✅ Hero mouse area left throw_area!")
			is_near_throw_area = false
			_hide_throw_warning_label()
			_hide_throw_candy_label()
			# Re-enable left movement when leaving throw_area
			if hero_mouse and hero_mouse.has_method("enable_left_movement"):
				hero_mouse.enable_left_movement()
				print("[HOUSE] ✅ Left movement enabled for hero_mouse")


func _on_trash_detected_body_entered(body: Node) -> void:
	print("[HOUSE] 🗑️ Body entered trash_detected_area: ", body.name, " | Path: ", body.get_path())
	# Check if it's hero_mouse (by name, path, or direct comparison)
	var is_hero = (body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()) or body == hero_mouse)
	if is_hero:
		print("[HOUSE] ✅ Hero mouse detected in trash_detected_area! Showing jump message...")
		is_near_trash_detected = true
		_show_trash_jump_label()


func _on_trash_detected_body_exited(body: Node) -> void:
	print("[HOUSE] 🗑️ Body exited trash_detected_area: ", body.name, " | Path: ", body.get_path())
	if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
		# Check if we're still in trash_detected_area (via area detection)
		var still_near = false
		if trash_detected_area:
			# Check if hero_mouse is still overlapping via area
			for area in trash_detected_area.get_overlapping_areas():
				if "HeroMouse" in area.get_path().get_concatenated_names():
					still_near = true
					break
		
		if not still_near:
			print("[HOUSE] ✅ Hero mouse left trash_detected_area!")
			is_near_trash_detected = false
			_hide_trash_jump_label()


func _on_trash_detected_area_entered(area: Area2D) -> void:
	print("[HOUSE] 🗑️ Area entered trash_detected_area: ", area.get_path())
	if "HeroMouse" in area.get_path().get_concatenated_names():
		print("[HOUSE] ✅ Hero mouse area detected in trash_detected_area! Showing jump message...")
		is_near_trash_detected = true
		_show_trash_jump_label()


func _on_trash_detected_area_exited(area: Area2D) -> void:
	print("[HOUSE] 🗑️ Area exited trash_detected_area: ", area.get_path())
	if "HeroMouse" in area.get_path().get_concatenated_names():
		# Check if we're still in trash_detected_area (via body detection)
		var still_near = false
		if trash_detected_area and hero_mouse:
			# Check if hero_mouse body is still overlapping
			for body in trash_detected_area.get_overlapping_bodies():
				if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
					still_near = true
					break
		
		if not still_near:
			print("[HOUSE] ✅ Hero mouse area left trash_detected_area!")
			is_near_trash_detected = false
			_hide_trash_jump_label()


func _start_jump_to_trash_animation(mouse: CharacterBody2D) -> void:
	if is_jumping_to_trash:
		return  # Already animating
	
	is_jumping_to_trash = true
	print("[HOUSE] Starting jump animation...")
	
	# Disable control and physics for hero_mouse
	if mouse.has_method("disable_control"):
		mouse.disable_control()
		print("[HOUSE] Control disabled for hero_mouse")
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
	#mouse.visible = false
	print("[HOUSE] Hero mouse hidden")
	
	# Start falling animation for trash
	if trash_node:
		var animation_tree = trash_node.get_node_or_null("AnimationTree")
		var animation_player = trash_node.get_node_or_null("AnimationPlayer")
		
		if animation_tree:
			# Try to get state machine playback (it should exist automatically for state machines)
			var state_machine = animation_tree.get("parameters/playback")
			if state_machine:
				state_machine.travel("falling")
				print("[HOUSE] ✅ Falling animation started for trash (via AnimationTree)")
				# Wait for animation to complete (0.5 seconds based on trash.tscn)
				await get_tree().create_timer(0.5).timeout
				match_box.visible = true
				# Disable detected area after animation completes
				_disable_trash_detected_area()
			else:
				# Fallback to AnimationPlayer if state machine doesn't work
				if animation_player:
					# Connect to animation finished signal
					if not animation_player.animation_finished.is_connected(_on_trash_falling_finished):
						animation_player.animation_finished.connect(_on_trash_falling_finished)
					animation_player.play("falling")
					print("[HOUSE] ✅ Falling animation started for trash (via AnimationPlayer fallback)")
				else:
					print("[HOUSE] ❌ ERROR: Could not start falling animation")
		else:
			# Fallback: try AnimationPlayer directly
			if animation_player:
				# Connect to animation finished signal
				if not animation_player.animation_finished.is_connected(_on_trash_falling_finished):
					animation_player.animation_finished.connect(_on_trash_falling_finished)
				animation_player.play("falling")
				print("[HOUSE] ✅ Falling animation started for trash (via AnimationPlayer direct)")
			else:
				print("[HOUSE] ❌ ERROR: No AnimationTree or AnimationPlayer found in trash")
	else:
		print("[HOUSE] ❌ ERROR: trash_node is null")
	
	# Restore hero_mouse state after animation
	if mouse:
		# Re-enable physics
		mouse.set_physics_process(true)
		print("[HOUSE] Physics re-enabled for hero_mouse")
		
		# Re-enable control
		if mouse.has_method("enable_control"):
			mouse.enable_control()
			print("[HOUSE] Control re-enabled for hero_mouse")
		
		# Set to idle_right animation
		if mouse.has_method("set_idle_right"):
			mouse.set_idle_right()
			print("[HOUSE] Hero mouse animation set to idle_right")
		elif mouse.has_method("set_idle_left"):
			# Fallback: try to access state_machine directly
			var animation_tree = mouse.find_child("AnimationTree", true, false)
			if animation_tree:
				var state_machine = animation_tree.get("parameters/playback")
				if state_machine:
					state_machine.travel("idle_right")
					print("[HOUSE] Hero mouse animation set to idle_right (via AnimationTree)")
	
	is_jumping_to_trash = false


func _on_trash_falling_finished(anim_name: String) -> void:
	if anim_name == "falling":
		print("[HOUSE] ✅ Trash falling animation finished")
		match_box.visible = true
		# Disable detected area after animation completes
		_disable_trash_detected_area()
		# Disconnect signal to avoid multiple calls
		if trash_node:
			var animation_player = trash_node.get_node_or_null("AnimationPlayer")
			if animation_player and animation_player.animation_finished.is_connected(_on_trash_falling_finished):
				animation_player.animation_finished.disconnect(_on_trash_falling_finished)


func _disable_trash_detected_area() -> void:
	if trash_detected_area:
		trash_detected_area.monitoring = false
		# Hide label if it's showing
		if is_near_trash_detected:
			is_near_trash_detected = false
			_hide_trash_jump_label()
		print("[HOUSE] ✅ Trash detected area disabled after falling animation")
	else:
		print("[HOUSE] ❌ ERROR: trash_detected_area is null")


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
	
	# Create CanvasLayer for dialog to ensure it's on top of all layers
	dialog_window = CanvasLayer.new()
	dialog_window.name = "EnterDialogLayer"
	dialog_window.layer = 100  # High layer value to ensure it's above everything
	
	# Create main dialog container
	var dialog_container = Control.new()
	dialog_container.name = "EnterDialog"
	dialog_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Create semi-transparent background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.5)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_container.add_child(background)
	
	# Create dialog panel
	var panel = Panel.new()
	panel.name = "DialogPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(400, 200)
	panel.position = Vector2(-200, -100)
	dialog_container.add_child(panel)
	
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
	
	# Add dialog container to CanvasLayer and add layer to scene tree
	dialog_window.add_child(dialog_container)
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
		# dialog_window is now a CanvasLayer, so we can queue_free it directly
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
		# Only allow pickup if MatchBox is visible
		if matchbox_area.visible:
			current_matchbox = matchbox_area
			is_near_matchbox = true
			_show_pickup_label()
			print("[HOUSE] ✅ Hero mouse near MatchBox - showing pickup label")
		else:
			print("[HOUSE] ⚠️ MatchBox is not visible yet, pickup disabled")


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
		# Check if we're still near any visible MatchBox
		var still_near = false
		for child in get_children():
			if child is Area2D and child.name == "MatchBox":
				if child.get_overlapping_bodies().has(body) and child.visible:
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
		# Only allow pickup if MatchBox is visible
		if matchbox_area.visible:
			current_matchbox = matchbox_area
			is_near_matchbox = true
			_show_pickup_label()
			print("[HOUSE] ✅ Hero mouse area entered MatchBox - showing pickup label")
		else:
			print("[HOUSE] ⚠️ MatchBox is not visible yet, pickup disabled")


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
		# Check if we're still near any visible MatchBox
		var still_near = false
		for child in get_children():
			if child is Area2D and child.name == "MatchBox":
				if child.get_overlapping_areas().has(area) and child.visible:
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


func _create_jump_label() -> void:
	# Create CanvasLayer for jump label
	jump_label_layer = CanvasLayer.new()
	jump_label_layer.name = "JumpLabelLayer"
	jump_label_layer.layer = 10  # Ensure it's above other layers
	add_child(jump_label_layer)
	
	# Create Label
	jump_label = Label.new()
	jump_label.name = "JumpLabel"
	jump_label.text = "спрыгнуть 'SPACE'"
	jump_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	jump_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	jump_label.add_theme_font_size_override("font_size", 24)
	jump_label.modulate = Color.WHITE
	# Add outline effect using add_theme_color_override
	jump_label.add_theme_color_override("font_color", Color.WHITE)
	jump_label.add_theme_color_override("font_outline_color", Color.BLACK)
	jump_label.add_theme_constant_override("outline_size", 4)
	jump_label.visible = false
	jump_label_layer.add_child(jump_label)
	print("[HOUSE] Jump label created")
	print("[HOUSE] Jump label layer: ", jump_label_layer.layer)
	print("[HOUSE] Jump label layer visible: ", jump_label_layer.visible)


func _show_jump_label() -> void:
	if jump_label:
		jump_label.visible = true
		if jump_label_layer:
			jump_label_layer.visible = true
		print("[HOUSE] Jump label shown")
		print("[HOUSE] Jump label visible: ", jump_label.visible)
		print("[HOUSE] Jump label position: ", jump_label.position)
		if jump_label_layer:
			print("[HOUSE] Jump label layer visible: ", jump_label_layer.visible)
			print("[HOUSE] Jump label layer layer: ", jump_label_layer.layer)
		else:
			print("[HOUSE] Jump label layer is null!")
	else:
		print("[HOUSE] ❌ ERROR: jump_label is null!")


func _hide_jump_label() -> void:
	if jump_label:
		jump_label.visible = false
		print("[HOUSE] Jump label hidden")


func _create_throw_warning_label() -> void:
	# Create CanvasLayer for throw warning label
	throw_warning_label_layer = CanvasLayer.new()
	throw_warning_label_layer.name = "ThrowWarningLabelLayer"
	throw_warning_label_layer.layer = 10  # Ensure it's above other layers
	add_child(throw_warning_label_layer)
	
	# Create Label
	throw_warning_label = Label.new()
	throw_warning_label.name = "ThrowWarningLabel"
	throw_warning_label.text = "Я попаду в лапы зверя, если спрыгну отсюда"
	throw_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	throw_warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	throw_warning_label.add_theme_font_size_override("font_size", 24)
	throw_warning_label.modulate = Color.WHITE
	# Add outline effect using add_theme_color_override
	throw_warning_label.add_theme_color_override("font_color", Color.WHITE)
	throw_warning_label.add_theme_color_override("font_outline_color", Color.BLACK)
	throw_warning_label.add_theme_constant_override("outline_size", 4)
	throw_warning_label.visible = false
	throw_warning_label_layer.add_child(throw_warning_label)
	print("[HOUSE] Throw warning label created")


func _show_throw_warning_label() -> void:
	if throw_warning_label:
		throw_warning_label.visible = true
		if throw_warning_label_layer:
			throw_warning_label_layer.visible = true
		print("[HOUSE] Throw warning label shown")
	else:
		print("[HOUSE] ❌ ERROR: throw_warning_label is null!")


func _hide_throw_warning_label() -> void:
	if throw_warning_label:
		throw_warning_label.visible = false
		print("[HOUSE] Throw warning label hidden")


func _create_throw_candy_label() -> void:
	# Create CanvasLayer for throw candy label
	throw_candy_label_layer = CanvasLayer.new()
	throw_candy_label_layer.name = "ThrowCandyLabelLayer"
	throw_candy_label_layer.layer = 10  # Ensure it's above other layers
	add_child(throw_candy_label_layer)
	
	# Create Label
	throw_candy_label = Label.new()
	throw_candy_label.name = "ThrowCandyLabel"
	throw_candy_label.text = "Бросить конфету 'E'"
	throw_candy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	throw_candy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	throw_candy_label.add_theme_font_size_override("font_size", 24)
	throw_candy_label.modulate = Color.WHITE
	# Add outline effect using add_theme_color_override
	throw_candy_label.add_theme_color_override("font_color", Color.WHITE)
	throw_candy_label.add_theme_color_override("font_outline_color", Color.BLACK)
	throw_candy_label.add_theme_constant_override("outline_size", 4)
	throw_candy_label.visible = false
	throw_candy_label_layer.add_child(throw_candy_label)
	print("[HOUSE] Throw candy label created")


func _show_throw_candy_label() -> void:
	if throw_candy_label:
		throw_candy_label.visible = true
		if throw_candy_label_layer:
			throw_candy_label_layer.visible = true
		print("[HOUSE] Throw candy label shown")
	else:
		print("[HOUSE] ❌ ERROR: throw_candy_label is null!")


func _hide_throw_candy_label() -> void:
	if throw_candy_label:
		throw_candy_label.visible = false
		print("[HOUSE] Throw candy label hidden")


func _has_candy_in_inventory() -> bool:
	# Check if candy is in Global.inventory_data
	for item in Global.inventory_data:
		if item.has("name") and item["name"] == "Candy":
			return true
	return false


func _create_trash_jump_label() -> void:
	# Create CanvasLayer for trash jump label
	trash_jump_label_layer = CanvasLayer.new()
	trash_jump_label_layer.name = "TrashJumpLabelLayer"
	trash_jump_label_layer.layer = 10  # Ensure it's above other layers
	add_child(trash_jump_label_layer)
	
	# Create Label
	trash_jump_label = Label.new()
	trash_jump_label.name = "TrashJumpLabel"
	trash_jump_label.text = "я смогу запрыгнуть сверху"
	trash_jump_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trash_jump_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	trash_jump_label.add_theme_font_size_override("font_size", 24)
	trash_jump_label.modulate = Color.WHITE
	# Add outline effect using add_theme_color_override
	trash_jump_label.add_theme_color_override("font_color", Color.WHITE)
	trash_jump_label.add_theme_color_override("font_outline_color", Color.BLACK)
	trash_jump_label.add_theme_constant_override("outline_size", 4)
	trash_jump_label.visible = false
	trash_jump_label_layer.add_child(trash_jump_label)
	print("[HOUSE] Trash jump label created")


func _show_trash_jump_label() -> void:
	if trash_jump_label:
		trash_jump_label.visible = true
		if trash_jump_label_layer:
			trash_jump_label_layer.visible = true
		print("[HOUSE] Trash jump label shown")
	else:
		print("[HOUSE] ❌ ERROR: trash_jump_label is null!")


func _hide_trash_jump_label() -> void:
	if trash_jump_label:
		trash_jump_label.visible = false
		print("[HOUSE] Trash jump label hidden")


func _setup_all_matchboxes() -> void:
	# Set up collision detection for all MatchBox instances in scene
	for child in get_children():
		if child is Area2D and child.name == "MatchBox":
			if not child.body_entered.is_connected(_on_matchbox_body_entered):
				child.monitoring = true
				child.monitorable = true
				# Set collision mask to detect hero_mouse on layer 1
				child.collision_mask = 1  # Layer 1
				child.body_entered.connect(_on_matchbox_body_entered)
				child.body_exited.connect(_on_matchbox_body_exited)
				child.area_entered.connect(_on_matchbox_area_entered)
				child.area_exited.connect(_on_matchbox_area_exited)
				print("[HOUSE] MatchBox collision detection set up for: ", child.name)

func _setup_all_candies() -> void:
	# Set up collision detection for all candy instances in scene
	for child in get_children():
		if child is Area2D and child.name == "candy":
			if not child.body_entered.is_connected(_on_candy_body_entered):
				child.monitoring = true
				child.monitorable = true
				# Set collision mask to detect hero_mouse on layer 1
				child.collision_mask = 1  # Layer 1
				child.body_entered.connect(_on_candy_body_entered)
				child.body_exited.connect(_on_candy_body_exited)
				child.area_entered.connect(_on_candy_area_entered)
				child.area_exited.connect(_on_candy_area_exited)
				print("[HOUSE] Candy collision detection set up for: ", child.name)

func _show_pickup_label() -> void:
	if pickup_label:
		# Position will be updated in _process
		# Show label if near any visible item
		var should_show = false
		if is_near_matchbox and current_matchbox and current_matchbox.visible:
			should_show = true
		elif is_near_threads:
			should_show = true
		elif is_near_candy:
			should_show = true
		elif is_near_princess_mouse:
			should_show = true
		
		if should_show:
			pickup_label.visible = true
		else:
			pickup_label.visible = false


func _hide_pickup_label() -> void:
	if pickup_label:
		# Hide label only if not near any item
		if not is_near_matchbox and not is_near_threads and not is_near_candy:
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
				# Store animation player
				death_anim_animation_player = animation_player
				
				# Connect to animation finished signal
				if not animation_player.animation_finished.is_connected(_on_death_anim_finished):
					animation_player.animation_finished.connect(_on_death_anim_finished)
				
				# Check if animation is currently playing the death_anim
				var was_playing_death_anim = (animation_player.is_playing() and 
											 animation_player.current_animation == "death_anim")
				
				# Start animation
				animation_player.play("death_anim")
				print("[HOUSE] ✅ Camera2D death animation started")
				
				# If animation wasn't playing death_anim before, start continuous timer
				# This ensures we only track continuous time from the start of this playback
				if not was_playing_death_anim:
					death_anim_continuous_start_time = Time.get_ticks_msec() / 1000.0
					death_anim_is_playing = true
					death_anim_control_disabled = false
					print("[HOUSE] Continuous timer started for death animation at: ", death_anim_continuous_start_time)
				else:
					# Animation was already playing death_anim, don't reset timer
					# This means it's a continuous playback
					death_anim_is_playing = true
					print("[HOUSE] Death animation was already playing, continuing to track time")
			else:
				print("[HOUSE] ❌ Camera2D AnimationPlayer or death_anim not found")

func _load_game_over_with_delay() -> void:
	# Wait 1 second before loading game over scene
	await get_tree().create_timer(1.0).timeout
	
	# Load game over scene
	var game_over_scene_path = "res://game_over/game_over.tscn"
	if ResourceLoader.exists(game_over_scene_path):
		get_tree().change_scene_to_file(game_over_scene_path)
		print("[HOUSE] ✅ Game over scene loaded (with 1s delay)")
	else:
		print("[HOUSE] ❌ ERROR: Game over scene not found at: ", game_over_scene_path)

func _stop_camera_death_anim() -> void:
	if hero_mouse:
		var camera = hero_mouse.find_child("Camera2D", true, false)
		if camera:
			var animation_player = camera.find_child("AnimationPlayer", true, false)
			if animation_player:
				# Disconnect from animation finished signal if connected
				if animation_player.animation_finished.is_connected(_on_death_anim_finished):
					animation_player.animation_finished.disconnect(_on_death_anim_finished)
				
				if animation_player.has_animation("RESET"):
					animation_player.play("RESET")
				else:
					animation_player.stop()
				print("[HOUSE] ✅ Camera2D death animation stopped")
			else:
				print("[HOUSE] ❌ Camera2D AnimationPlayer not found")
	
	# Reset death animation tracking
	death_anim_animation_player = null
	death_anim_continuous_start_time = 0.0
	death_anim_control_disabled = false
	death_anim_is_playing = false

func _on_death_anim_finished(anim_name: String) -> void:
	if anim_name == "death_anim":
		# Reset continuous timer when animation finishes
		death_anim_continuous_start_time = 0.0
		death_anim_is_playing = false
		
		# Only load game over scene if control wasn't already disabled (meaning it wasn't loaded in _process)
		if not death_anim_control_disabled:
			print("[HOUSE] ✅ Death animation finished - loading game over scene")
			# Load game over scene with delay
			_load_game_over_with_delay()
		else:
			print("[HOUSE] Death animation finished, but game over already triggered")


func _pickup_matchbox() -> void:
	if not is_near_matchbox or not current_matchbox or not matchbox_item_data:
		return
	
	# Check if MatchBox is visible before allowing pickup
	if not current_matchbox.visible:
		print("[HOUSE] ⚠️ Cannot pickup MatchBox - it's not visible yet")
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

# Candy pickup functions
func _on_candy_body_entered(body: Node) -> void:
	# Try to find the candy that triggered this
	var candy_area = null
	for child in get_children():
		if child is Area2D and child.name == "candy":
			if child.get_overlapping_bodies().has(body):
				candy_area = child
				break
	
	if not candy_area:
		candy_area = find_child("candy", true, false) as Area2D
	
	_on_candy_body_entered_with_source(body, candy_area)

func _on_candy_body_entered_with_source(body: Node, candy_area: Area2D) -> void:
	print("[HOUSE] Body entered Candy area: ", body.name)
	if candy_area and (body.name == "HeroMouse" or "HeroMouse" in str(body.get_path())):
		current_candy = candy_area
		is_near_candy = true
		_show_pickup_label()
		print("[HOUSE] ✅ Hero mouse near Candy - showing pickup label")


func _on_candy_body_exited(body: Node) -> void:
	# Try to find the candy that triggered this
	var candy_area = null
	for child in get_children():
		if child is Area2D and child.name == "candy":
			if not child.get_overlapping_bodies().has(body):
				# Check if this was the one we were near
				if child == current_candy:
					candy_area = child
					break
	
	_on_candy_body_exited_with_source(body, candy_area)

func _on_candy_body_exited_with_source(body: Node, _candy_area: Area2D) -> void:
	print("[HOUSE] Body exited Candy area: ", body.name)
	if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
		# Check if we're still near any candy
		var still_near = false
		for child in get_children():
			if child is Area2D and child.name == "candy":
				if child.get_overlapping_bodies().has(body):
					current_candy = child
					still_near = true
					break
		
		if not still_near:
			is_near_candy = false
			current_candy = null
			_hide_pickup_label()
			print("[HOUSE] ✅ Hero mouse left Candy area")


func _on_candy_area_entered(area: Area2D) -> void:
	if "HeroMouse" in area.get_path().get_concatenated_names():
		# Find which candy triggered this signal
		var candy_area = null
		for child in get_children():
			if child is Area2D and child.name == "candy":
				if child.get_overlapping_areas().has(area):
					candy_area = child
					break
		
		_on_candy_area_entered_with_source(area, candy_area)

func _on_candy_area_entered_with_source(area: Area2D, candy_area: Area2D) -> void:
	if candy_area and "HeroMouse" in area.get_path().get_concatenated_names():
		current_candy = candy_area
		is_near_candy = true
		_show_pickup_label()
		print("[HOUSE] ✅ Hero mouse area entered Candy - showing pickup label")


func _on_candy_area_exited(area: Area2D) -> void:
	if "HeroMouse" in area.get_path().get_concatenated_names():
		# Find which candy triggered this signal
		var candy_area = null
		for child in get_children():
			if child is Area2D and child.name == "candy":
				if not child.get_overlapping_areas().has(area):
					if child == current_candy:
						candy_area = child
						break
		
		_on_candy_area_exited_with_source(area, candy_area)

func _on_candy_area_exited_with_source(area: Area2D, _candy_area: Area2D) -> void:
	if "HeroMouse" in area.get_path().get_concatenated_names():
		# Check if we're still near any candy
		var still_near = false
		for child in get_children():
			if child is Area2D and child.name == "candy":
				if child.get_overlapping_areas().has(area):
					current_candy = child
					still_near = true
					break
		
		if not still_near:
			is_near_candy = false
			current_candy = null
			_hide_pickup_label()
			print("[HOUSE] ✅ Hero mouse area exited Candy")

func _throw_candy() -> void:
	if is_throwing_candy or not _has_candy_in_inventory():
		return
	
	is_throwing_candy = true
	print("[HOUSE] ✅ Throwing candy...")
	
	# Remove candy from inventory
	for i in range(Global.inventory_data.size() - 1, -1, -1):
		if Global.inventory_data[i].has("name") and Global.inventory_data[i]["name"] == "Candy":
			Global.inventory_data.remove_at(i)
			print("[HOUSE] ✅ Candy removed from Global.inventory_data")
			break
	
	# Remove candy from GUI inventory
	if house_gui and house_gui.inventory_slots.size() > 0:
		var slot = house_gui.inventory_slots[0]
		if slot.get_child_count() > 0:
			var item = slot.get_child(0)
			if item and ("data" in item):
				var item_data = item.data
				if item_data and item_data.name == "Candy":
					item.queue_free()
					print("[HOUSE] ✅ Candy removed from GUI inventory")
	
	# Hide throw candy label
	_hide_throw_candy_label()
	
	# Get hero_mouse position as start position
	var start_pos = hero_mouse.global_position if hero_mouse else Vector2.ZERO
	
	# Find мильпопс position in PredatorAwaking
	var milpop_pos = Vector2.ZERO
	if predator_awaking:
		var milpop = predator_awaking.find_child("Мильпопс", true, false)
		if milpop:
			milpop_pos = milpop.global_position
			print("[HOUSE] ✅ Found мильпопс position: ", milpop_pos)
		else:
			print("[HOUSE] ❌ ERROR: Мильпопс not found in PredatorAwaking")
			# Fallback: use position from house.tscn (4399, 477.99997)
			milpop_pos = predator_awaking.global_position + Vector2(4399, 477.99997)
	else:
		print("[HOUSE] ❌ ERROR: predator_awaking is null")
		is_throwing_candy = false
		return
	
	# Create or find candy visual node for animation
	var candy_visual: Node2D = null
	var original_scale: Vector2 = Vector2(1, 1)
	if candy_node and candy_node.visible:
		# Use existing candy node if visible
		candy_visual = candy_node
		# Save original scale to preserve it during animation
		original_scale = candy_visual.scale
		candy_visual.global_position = start_pos
	else:
		# Create a temporary candy sprite for animation
		candy_visual = Node2D.new()
		candy_visual.name = "ThrownCandy"
		add_child(candy_visual)
		# Try to load candy texture if available
		if candy_item_data and candy_item_data.texture:
			var sprite = Sprite2D.new()
			sprite.texture = candy_item_data.texture
			# Set scale to match original candy.tscn (0.2, 0.2)
			sprite.scale = Vector2(0.2, 0.2)
			sprite.rotation = 0.4886922  # Match original rotation from candy.tscn
			candy_visual.add_child(sprite)
		candy_visual.global_position = start_pos
		original_scale = candy_visual.scale
	
	# Create Tween for candy movement animation
	# Ensure scale is preserved during animation
	if candy_visual.scale != original_scale:
		candy_visual.scale = original_scale
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_method(
		func(pos): candy_visual.global_position = pos,
		start_pos,
		milpop_pos,
		1.5  # Animation duration in seconds
	)
	
	# Wait for animation to complete
	await tween.finished
	
	# Hide candy and disable pickup after reaching target
	if candy_visual:
		candy_visual.visible = false
		# Disable monitoring if it's an Area2D
		if candy_visual is Area2D:
			var candy_area = candy_visual as Area2D
			candy_area.monitoring = false
			candy_area.monitorable = false
			# Also update current_candy if it was the one thrown
			if current_candy == candy_area:
				current_candy = null
				is_near_candy = false
				_hide_pickup_label()
		# If it's a temporary node, remove it
		if candy_visual.name == "ThrownCandy":
			candy_visual.queue_free()
		print("[HOUSE] ✅ Candy reached мильпопс - disabled visibility and pickup")
	
	# Hide predator after candy is thrown
	if predator_node:
		predator_node.visible = false
		print("[HOUSE] ✅ Predator hidden after candy throw")
	
	# Remove CollisionShape2D2 from PredatorAwaking
	if predator_awaking:
		var collision_shape2 = null
		# Try to get directly by name
		if predator_awaking.has_node("CollisionShape2D2"):
			collision_shape2 = predator_awaking.get_node("CollisionShape2D2")
		else:
			# Try to find by iterating children
			for child in predator_awaking.get_children():
				if child is CollisionShape2D and child.name == "CollisionShape2D2":
					collision_shape2 = child
					break
		
		if collision_shape2:
			predator_awaking.remove_child(collision_shape2)
			collision_shape2.queue_free()
			print("[HOUSE] ✅ CollisionShape2D2 removed from PredatorAwaking")
		else:
			print("[HOUSE] ❌ ERROR: CollisionShape2D2 not found in PredatorAwaking")
			# Debug: list all children
			print("[HOUSE] PredatorAwaking children: ", predator_awaking.get_children())
	
	# Spawn princess_mouse at position (3817.0, 542.0)
	var princess_mouse_scene = load("res://house/princess_mouse.tscn")
	if princess_mouse_scene:
		var princess_mouse = princess_mouse_scene.instantiate()
		princess_mouse.position = Vector2(3817.0, 542.0)
		add_child(princess_mouse)
		# Set up collision detection for princess_mouse
		if princess_mouse is Area2D:
			princess_mouse.monitoring = true
			princess_mouse.monitorable = true
			princess_mouse.collision_mask = 1  # Layer 1
			princess_mouse.body_entered.connect(_on_princess_mouse_body_entered)
			princess_mouse.body_exited.connect(_on_princess_mouse_body_exited)
			princess_mouse.area_entered.connect(_on_princess_mouse_area_entered)
			princess_mouse.area_exited.connect(_on_princess_mouse_area_exited)
			print("[HOUSE] ✅ Princess mouse spawned at position (3817.0, 542.0) with collision detection")
		else:
			print("[HOUSE] ❌ ERROR: Princess mouse is not Area2D")
	else:
		print("[HOUSE] ❌ ERROR: Could not load princess_mouse.tscn")
	
	is_throwing_candy = false
	print("[HOUSE] ✅ Candy throwing animation completed!")


func _pickup_candy() -> void:
	if not is_near_candy or not current_candy or not candy_item_data:
		return
	
	# Check if candy is visible and can be picked up
	if not current_candy.visible or (current_candy is Area2D and not (current_candy as Area2D).monitoring):
		print("[HOUSE] ⚠️ Cannot pickup Candy - it's disabled or not visible")
		return
	
	print("[HOUSE] ✅ Picking up Candy...")
	
	# Add item to inventory
	if house_gui and house_gui.has_method("add_item_to_inventory"):
		if house_gui.add_item_to_inventory(candy_item_data):
			# Add to Global.inventory_data
			Global.inventory_data.append({
				"name": candy_item_data.name,
				"texture_path": candy_item_data.texture.resource_path if candy_item_data.texture else "",
				"size": candy_item_data.size,
				"description": candy_item_data.description
			})
			print("[HOUSE] ✅ Candy added to Global.inventory_data")
			print("[HOUSE] 📦 Global.inventory_data contents after pickup: ", Global.inventory_data)
			
			# Remove Candy from scene
			var candy_to_remove = current_candy
			current_candy = null
			candy_to_remove.queue_free()
			is_near_candy = false
			_hide_pickup_label()
			print("[HOUSE] ✅ Candy picked up and added to inventory!")
		else:
			print("[HOUSE] ❌ Inventory is full! Only one item allowed.")
			# Можно показать сообщение игроку, что инвентарь полон
	else:
		print("[HOUSE] ❌ ERROR: house_gui or add_item_to_inventory method not found!")


# Princess mouse pickup functions
func _on_princess_mouse_body_entered(body: Node) -> void:
	# Try to find the princess_mouse that triggered this
	var princess_mouse_area = null
	for child in get_children():
		if child is Area2D and child.name == "PrincessMouse":
			if child.get_overlapping_bodies().has(body):
				princess_mouse_area = child
				break
	
	if not princess_mouse_area:
		princess_mouse_area = find_child("PrincessMouse", true, false) as Area2D
	
	_on_princess_mouse_body_entered_with_source(body, princess_mouse_area)


func _on_princess_mouse_body_entered_with_source(body: Node, princess_mouse_area: Area2D) -> void:
	print("[HOUSE] Body entered PrincessMouse area: ", body.name)
	if princess_mouse_area and (body.name == "HeroMouse" or "HeroMouse" in str(body.get_path())):
		current_princess_mouse = princess_mouse_area
		is_near_princess_mouse = true
		_show_pickup_label()
		print("[HOUSE] ✅ Hero mouse near PrincessMouse - showing pickup label")


func _on_princess_mouse_body_exited(body: Node) -> void:
	# Try to find the princess_mouse that triggered this
	var princess_mouse_area = null
	for child in get_children():
		if child is Area2D and child.name == "PrincessMouse":
			if not child.get_overlapping_bodies().has(body):
				# Check if this was the one we were near
				if child == current_princess_mouse:
					princess_mouse_area = child
					break
	
	_on_princess_mouse_body_exited_with_source(body, princess_mouse_area)


func _on_princess_mouse_body_exited_with_source(body: Node, _princess_mouse_area: Area2D) -> void:
	print("[HOUSE] Body exited PrincessMouse area: ", body.name)
	if body.name == "HeroMouse" or "HeroMouse" in str(body.get_path()):
		# Check if we're still near any princess_mouse
		var still_near = false
		for child in get_children():
			if child is Area2D and child.name == "PrincessMouse":
				if child.get_overlapping_bodies().has(body):
					current_princess_mouse = child
					still_near = true
					break
		
		if not still_near:
			is_near_princess_mouse = false
			current_princess_mouse = null
			_hide_pickup_label()
			print("[HOUSE] ✅ Hero mouse left PrincessMouse area")


func _on_princess_mouse_area_entered(area: Area2D) -> void:
	if "HeroMouse" in area.get_path().get_concatenated_names():
		# Find which princess_mouse triggered this signal
		var princess_mouse_area = null
		for child in get_children():
			if child is Area2D and child.name == "PrincessMouse":
				if child.get_overlapping_areas().has(area):
					princess_mouse_area = child
					break
		
		_on_princess_mouse_area_entered_with_source(area, princess_mouse_area)


func _on_princess_mouse_area_entered_with_source(area: Area2D, princess_mouse_area: Area2D) -> void:
	if princess_mouse_area and "HeroMouse" in area.get_path().get_concatenated_names():
		current_princess_mouse = princess_mouse_area
		is_near_princess_mouse = true
		_show_pickup_label()
		print("[HOUSE] ✅ Hero mouse area entered PrincessMouse - showing pickup label")


func _on_princess_mouse_area_exited(area: Area2D) -> void:
	if "HeroMouse" in area.get_path().get_concatenated_names():
		# Find which princess_mouse triggered this signal
		var princess_mouse_area = null
		for child in get_children():
			if child is Area2D and child.name == "PrincessMouse":
				if not child.get_overlapping_areas().has(area):
					if child == current_princess_mouse:
						princess_mouse_area = child
						break
		
		_on_princess_mouse_area_exited_with_source(area, princess_mouse_area)


func _on_princess_mouse_area_exited_with_source(area: Area2D, _princess_mouse_area: Area2D) -> void:
	if "HeroMouse" in area.get_path().get_concatenated_names():
		# Check if we're still near any princess_mouse
		var still_near = false
		for child in get_children():
			if child is Area2D and child.name == "PrincessMouse":
				if child.get_overlapping_areas().has(area):
					current_princess_mouse = child
					still_near = true
					break
		
		if not still_near:
			is_near_princess_mouse = false
			current_princess_mouse = null
			_hide_pickup_label()
			print("[HOUSE] ✅ Hero mouse area exited PrincessMouse")


func _pickup_princess_mouse() -> void:
	if not is_near_princess_mouse or not current_princess_mouse or not princess_mouse_item_data:
		return
	
	print("[HOUSE] ✅ Picking up PrincessMouse...")
	
	# Add item to inventory
	if house_gui and house_gui.has_method("add_item_to_inventory"):
		if house_gui.add_item_to_inventory(princess_mouse_item_data):
			# Add to Global.inventory_data
			Global.inventory_data.append({
				"name": princess_mouse_item_data.name,
				"texture_path": princess_mouse_item_data.texture.resource_path if princess_mouse_item_data.texture else "",
				"size": princess_mouse_item_data.size,
				"description": princess_mouse_item_data.description
			})
			print("[HOUSE] ✅ PrincessMouse added to Global.inventory_data")
			print("[HOUSE] 📦 Global.inventory_data contents after pickup: ", Global.inventory_data)
			
			# Remove PrincessMouse from scene
			var princess_mouse_to_remove = current_princess_mouse
			current_princess_mouse = null
			princess_mouse_to_remove.queue_free()
			is_near_princess_mouse = false
			_hide_pickup_label()
			print("[HOUSE] ✅ PrincessMouse picked up and added to inventory!")
		else:
			print("[HOUSE] ❌ Inventory is full! Only one item allowed.")
			# Можно показать сообщение игроку, что инвентарь полон
	else:
		print("[HOUSE] ❌ ERROR: house_gui or add_item_to_inventory method not found!")
