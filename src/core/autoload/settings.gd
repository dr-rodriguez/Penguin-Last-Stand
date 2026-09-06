extends Node

## Platform detection: true on an Android/iOS device. Read-only, set once at startup
var is_mobile: bool = false

## Player-facing toggle for the on-screen joystick, defaults to on for mobile
var joystick_enabled: bool = false

## Flag for enabling auto-shoot functionality
var auto_shoot: bool = true


func _ready() -> void:
	# Check if the game is running on an Android or iOS device
	is_mobile = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	
	# Default to the joystick and auto-shooting if in mobile
	joystick_enabled = is_mobile
	auto_shoot = is_mobile
	
	print("[Settings] ready")
