extends Node

# Global signals for ease of use
signal snowball_done

# Player properties to track
var bullet_speed: float = 300.
var fire_interval: float = 0.5
var current_bullet_speed: float = 300.
var current_fire_interval: float = 0.5


func _ready() -> void:
	print("[Game] ready")
