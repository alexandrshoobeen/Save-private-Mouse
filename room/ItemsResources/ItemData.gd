class_name ItemData 
extends Resource

enum Type {HEAD, CHEST, LEGS, FEET, WEAPON, ACCESSORY, MAIN}

@export var type: Type
@export var name: String
@export_multiline var description: String
@export var texture: Texture2D
@export var width: int = 1
@export var height: int = 1
@export var size: Vector2i =  Vector2i(1, 1)
@export var pivot_offset: Vector2i =  Vector2i(0, 0)
@export var z_size: int = 0
@export var sound: AudioStream
