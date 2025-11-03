extends Node2D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if state_machine:
		state_machine.travel("sleep")


# Function to wake up the predator
func wake_up() -> void:
	if state_machine:
		state_machine.travel("awake")


# Function to put predator back to sleep
func fall_asleep() -> void:
	if state_machine:
		state_machine.travel("sleep")
