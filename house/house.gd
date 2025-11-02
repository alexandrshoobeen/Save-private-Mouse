extends Node2D

@onready var predator_awaking: Area2D = $PredatorAwaking
@onready var predator_node: Node2D = $predator
var hero_mouse: CharacterBody2D = null
var predator_awakened: bool = false

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
	
	# Create and add hero_mouse
	var hero_mouse_scene = preload("res://heroMouse/hero_mouse.tscn")
	hero_mouse = hero_mouse_scene.instantiate()
	hero_mouse.position = Vector2(350.0, 550.0)
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
