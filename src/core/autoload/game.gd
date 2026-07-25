extends Node

var bullet_speed: float = 300.
var current_bullet_speed: float = 300.

var fire_interval: float = 0.5
var current_fire_interval: float = 0.5

# Global signals for ease
signal snowball_done


func _ready() -> void:
	print("[Game] ready")
