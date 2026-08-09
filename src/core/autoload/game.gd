extends Node

# Global signals for ease of use
# Change Project Settings-Debug-GDScript-Warnings to ingore these warnings
@warning_ignore("unused_signal") 
signal snowball_done(n: Node)
signal enemy_defeated(n: Node)
signal player_hit()
signal game_tick()
signal run_won()
signal run_lost()
signal level_up()

## Growth rate of difficulty/level up requirement
const GROWTH: float = 0.1
## Maximum time to count down from
const MAX_TIME: int = 900

# Player properties
var player_xp: float = 0
var player_health: float = 50.
var player_level: int = 1
var current_player_health: float = 50.
var level_xp_needed: float = 10

# Player combat attributes
var bullet_speed: float = 300.
var fire_interval: float = 0.5
var bullet_damage: float = 4.0
var current_bullet_speed: float = 300.
var current_fire_interval: float = 0.5
var current_bullet_damage: float = 4.0

## Enemy type weight (below this value, second type shows up)
var enemy_type_weight: float = 0.4
## Enemy spawn time (rate increases over time)
var enemy_spawn_time: float = 1.0

# Game stats
var beaver_kills: int = 0
var axolotl_kills: int = 0
## Game time in seconds
var time_elapsed: int = 0

var debug_flag:bool = true


func _ready() -> void:
	_reset()
	print("[Game] ready")
	
	# Signal connnections
	game_tick.connect(calculate_time_stats)
	enemy_defeated.connect(_on_enemy_defeated)
	level_up.connect(_on_level_up)


## Helper method to reset values on game start
func _reset() -> void:
	# TODO: Make a game reset function
	pass


## Logic for any time calculations
func calculate_time_stats() -> void:
	time_elapsed += 1
	
	# Reached end time, emit win signal
	if time_elapsed >= MAX_TIME:
		run_won.emit()
	
	# Increase difficulty every 2 minutes
	if time_elapsed % 120 == 0:
		enemy_spawn_time = enemy_spawn_time * (1.0 - GROWTH)
		# Clamp so we don't go above/below thresholds
		enemy_spawn_time = clampf(enemy_spawn_time, 0.2, 1.0)
		print("[Game] Spawn time now " + str(enemy_spawn_time))


## Formats a time in seconds as MM:SS (e.g. 900 -> "15:00")
func format_time(seconds: int) -> String:
	@warning_ignore("INTEGER_DIVISION") 
	return "%02d:%02d" % [seconds / 60, seconds % 60]


## Handle XP when enemies are defeated
func _on_enemy_defeated(_n: Node) -> void:
	player_xp += 1
	
	# Level up logic
	if player_xp >= level_xp_needed:
		level_up.emit()


## Handle level ups
func _on_level_up() -> void:
	print("[Game] Level up")
	# Reset current XP amount
	player_xp = 0
	level_xp_needed *= (1.0 + GROWTH)
	player_level += 1
