extends Node

# Global signals for ease of use
# Change Project Settings-Debug-GDScript-Warnings to ingore these warnings
@warning_ignore("unused_signal") 
signal snowball_done(n: Node)
signal enemy_defeated(n: Node)
signal player_hit()

# Player properties
var player_xp: int = 0
var player_health: float = 50.
var current_player_health: float = 50.

# Player combat attributes
var bullet_speed: float = 300.
var fire_interval: float = 0.5
var bullet_damage: float = 4.0
var current_bullet_speed: float = 300.
var current_fire_interval: float = 0.5
var current_bullet_damage: float = 4.0

## Enemy type weight (below this value, second type shows up)
var enemy_type_weight: float = 0.4

# Game stats
var beaver_kills: int = 0
var axolotl_kills: int = 0

var debug_flag:bool = true

func _ready() -> void:
	print("[Game] ready")
	# TODO: Make a game reset function
