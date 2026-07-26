extends Node

# Global signals for ease of use
@warning_ignore("unused_signal")  # can also change Project Settings-Debug-GDScript-Warnings
signal snowball_done

# Player properties to track
var bullet_speed: float = 300.
var fire_interval: float = 0.5
var current_bullet_speed: float = 300.
var current_fire_interval: float = 0.5

## Enemy type weight (below this value, second type shows up)
var enemy_type_weight: float = 0.4


func _ready() -> void:
	print("[Game] ready")
