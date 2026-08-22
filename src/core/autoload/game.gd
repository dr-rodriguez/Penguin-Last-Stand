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
signal powerup_selected(name: String)

## Growth rate of difficulty/level up requirement
const GROWTH: float = 0.15
## Maximum time to count down from
const MAX_TIME: int = 600
## Growth rate of power ups
const POWER_GROWTH: float = 0.1

# Player properties
## Current XP toward next level, never negative
var player_xp: float = 0:
	set(value):
		player_xp = maxf(value, 0.0)
## Max health, never below 1
var player_health: float = 50.0:
	set(value):
		player_health = maxf(value, 1.0)
		# Re-clamp current health against the new max
		current_player_health = current_player_health
## Live health, clamped to [0, player_health]
var current_player_health: float = 50.0:
	set(value):
		current_player_health = clampf(value, 0.0, player_health)
## Player level
var player_level: int = 1
## XP needed for a level up
var level_xp_needed: float = 10.0

#region Player combat attributes
## Fire rate, never below 0.1
var fire_interval: float = 0.5:
	set(value):
		fire_interval = maxf(value, 0.1)
## Current fire rate, clamped to [0.1, fire_interval]
var current_fire_interval: float = 0.5:
	set(value):
		current_fire_interval = clampf(value, 0.1, fire_interval)

var bullet_speed: float = 300.
var current_bullet_speed: float = 300.
var bullet_damage: float = 4.0
var current_bullet_damage: float = 4.0

#endregion

## Enemy type weight (below this value, second type shows up)
var enemy_type_weight: float = 0.4
## Enemy spawn time (rate increases over time)
var enemy_spawn_time: float = 1.0:
	set(value):
		# Clamp to be within low/high thresholds
		enemy_spawn_time = clampf(value, 0.1, 1.0)

## List of available power ups
var power_up_list := [
	preload("res://src/resources/powerups/damage_up.tres"),
	preload("res://src/resources/powerups/fire_rate.tres"),
	preload("res://src/resources/powerups/health_boost.tres"),
]

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
	powerup_selected.connect(_on_powerup_selected)


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
		_increase_difficulty()


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


## Increase the difficulty
func _increase_difficulty() -> void:
	enemy_spawn_time *= (1.0 - GROWTH)
	print("[Game] Spawn time now " + str(enemy_spawn_time))


## Handle level ups
func _on_level_up() -> void:
	# Reset current XP amount
	player_xp = 0
	level_xp_needed *= (1.0 + GROWTH)
	player_level += 1
	
	# Increase the difficutly
	_increase_difficulty()
	
	print("[Game] Level up to " + str(player_level))
	# MainGame freezes the run until a power-up is picked


#region Power Up Logic
## Handle power ups
func _on_powerup_selected(power_up_name: String) -> void:
	print("[Game] Choose " + power_up_name)
	
	# Use helper function depending on name
	match power_up_name:
		"HealthBoost":
			_apply_health_boost()
		"FireRateUp":
			_apply_fire_rate_up()
		"DamageUp":
			_apply_damage_up()
	# MainGame resumes the run now that the choice is made

## Increase maximum health
func _apply_health_boost() -> void:
	player_health += 10.
	current_player_health += 10.
	print("[Game] health: " + str(current_player_health) + "/" + str(player_health))
	# Player hasn't really been hit, but this is used for the HUD
	player_hit.emit()

## Increase fire rate
func _apply_fire_rate_up() -> void:
	current_fire_interval *= (1.0 - POWER_GROWTH)
	fire_interval *= (1.0 - POWER_GROWTH)
	print("[Game] fire rate: " + str(current_fire_interval))

## Increase damage dealt
func _apply_damage_up() -> void:
	current_bullet_damage += 1
	bullet_damage += 1.0
	print("[Game] damage: " + str(current_bullet_damage))

#endregion
