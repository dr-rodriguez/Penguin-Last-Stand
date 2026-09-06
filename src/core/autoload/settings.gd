extends Node

## Flag whether the player is in a mobile device
var is_mobile: bool = false

## Flag for enabling auto-shoot functionality
var auto_shoot: bool = false


func _ready() -> void:
	print("[Settings] ready")
