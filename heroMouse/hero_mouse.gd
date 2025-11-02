extends CharacterBody2D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@export var speed: float = 400.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if state_machine:
		state_machine.travel("idle_right")


# Called every physics frame
func _physics_process(_delta: float) -> void:
	var direction: float = 0.0
	
	# Check for left/right input
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction -= 1.0
		if state_machine:
			state_machine.travel("walk_left")
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction += 1.0
		if state_machine:
			state_machine.travel("walk_right")
	
	# Move the hero mouse using CharacterBody2D velocity
	velocity.x = direction * speed
	move_and_slide()
	
	# Handle idle states
	if direction == 0.0 and state_machine:
		# Если шли вправо — стоим вправо. Если влево — стоим влево.
		var current_node = state_machine.get_current_node()
		if current_node == "walk_right":
			state_machine.travel("idle_right")
		elif current_node == "walk_left":
			state_machine.travel("idle_left")
