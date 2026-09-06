extends Node

## Flag whether the player is in a mobile device
var is_mobile: bool = false

## Flag for enabling auto-shoot functionality
var auto_shoot: bool = true


func _ready() -> void:
	# Check if the game is running on an Android or iOS device
	is_mobile = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	
	# Default to auto-shooting if in mobile
	if is_mobile:
		auto_shoot = true
	
	print("[Settings] ready")
