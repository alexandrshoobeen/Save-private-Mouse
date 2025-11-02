extends CharacterBody2D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@export var speed: float = 400.0
var can_move_vertically: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if state_machine:
		state_machine.travel("idle_right")


# Called every physics frame
func _physics_process(_delta: float) -> void:
	var direction_x: float = 0.0
	var direction_y: float = 0.0
	
	# Check for left/right input
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction_x -= 1.0
		if state_machine:
			state_machine.travel("walk_left")
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction_x += 1.0
		if state_machine:
			state_machine.travel("walk_right")
	
	# Check for up/down input (only when in "get up" area)
	if can_move_vertically:
		if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
			direction_y -= 1.0
			print("[HERO_MOUSE] Moving UP - direction_y: ", direction_y)
		if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
			direction_y += 1.0
			print("[HERO_MOUSE] Moving DOWN - direction_y: ", direction_y)
	else:
		# Debug: check if keys are pressed but vertical movement is disabled
		if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
			print("[HERO_MOUSE] DEBUG: Up/Down keys pressed but can_move_vertically = ", can_move_vertically)
	
	# Move the hero mouse using CharacterBody2D velocity
	velocity.x = direction_x * speed
	velocity.y = direction_y * speed
	if direction_y != 0.0:
		print("[HERO_MOUSE] Vertical velocity set: ", velocity.y, " | can_move_vertically: ", can_move_vertically)
	move_and_slide()
	
	# Handle idle states
	if direction_x == 0.0 and state_machine:
		# Если шли вправо — стоим вправо. Если влево — стоим влево.
		var current_node = state_machine.get_current_node()
		if current_node == "walk_right":
			state_machine.travel("idle_right")
		elif current_node == "walk_left":
			state_machine.travel("idle_left")


# Methods to enable/disable vertical movement
func enable_vertical_movement() -> void:
	can_move_vertically = true
	print("[HERO_MOUSE] ✅ Vertical movement ENABLED - can_move_vertically = ", can_move_vertically)
	print("[HERO_MOUSE] Hero position: ", global_position)


func disable_vertical_movement() -> void:
	can_move_vertically = false
	print("[HERO_MOUSE] ❌ Vertical movement DISABLED - can_move_vertically = ", can_move_vertically)
