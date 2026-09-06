extends Node

## Holds all per-run tuning values and mutable run state.
## Game reads/writes these; Stats owns the defaults and the reset.

## Growth rate of difficulty/level up requirement
const GROWTH: float = 0.15
## Maximum time to count down from
const MAX_TIME: int = 300
## Difficulty increase timer
const DIFFICULTY_TIMER: int = 30
## Minimum possible enemy spawn time
const MINIMUM_ENEMY_SPAWN_TIME: float = 0.01

#region Defaults
const DEFAULT_PLAYER_HEALTH: float = 50.0
const DEFAULT_LEVEL_XP_NEEDED: float = 10.0
const DEFAULT_FIRE_INTERVAL: float = 0.5
const DEFAULT_BULLET_SPEED: float = 300.0
const DEFAULT_BULLET_DAMAGE: float = 4.0
const DEFAULT_ENEMY_SPAWN_TIME: float = 0.5
#endregion

#region Player properties
## Current XP toward next level, never negative
var player_xp: float = 0:
	set(value):
		player_xp = maxf(value, 0.0)
## Max health, never below 1
var player_health: float = DEFAULT_PLAYER_HEALTH:
	set(value):
		player_health = maxf(value, 1.0)
		# Re-clamp current health against the new max
		current_player_health = current_player_health
## Live health, clamped to [0, player_health]
var current_player_health: float = DEFAULT_PLAYER_HEALTH:
	set(value):
		current_player_health = clampf(value, 0.0, player_health)
## Player level
var player_level: int = 1
## XP needed for a level up
var level_xp_needed: float = DEFAULT_LEVEL_XP_NEEDED
## Score value
var score: int = 0
## Game won/lost flag
var is_victory: bool = false
#endregion

#region Player combat attributes
## Fire rate, never below 0.1
var fire_interval: float = DEFAULT_FIRE_INTERVAL:
	set(value):
		fire_interval = maxf(value, 0.1)
## Current fire rate, clamped to [0.1, fire_interval]
var current_fire_interval: float = DEFAULT_FIRE_INTERVAL:
	set(value):
		current_fire_interval = clampf(value, 0.1, fire_interval)

var bullet_speed: float = DEFAULT_BULLET_SPEED
var current_bullet_speed: float = DEFAULT_BULLET_SPEED
var bullet_damage: float = DEFAULT_BULLET_DAMAGE
var current_bullet_damage: float = DEFAULT_BULLET_DAMAGE
#endregion

## Enemy spawn time (rate increases over time)
var enemy_spawn_time: float = DEFAULT_ENEMY_SPAWN_TIME:
	set(value):
		# Clamp to be within low/high thresholds
		enemy_spawn_time = clampf(value, MINIMUM_ENEMY_SPAWN_TIME, DEFAULT_ENEMY_SPAWN_TIME)

## List of available power ups
var power_up_list: Array[PowerUp] = [
	preload("res://src/resources/powerups/damage_up.tres"),
	preload("res://src/resources/powerups/fire_rate.tres"),
	preload("res://src/resources/powerups/health_boost.tres"),
]

## Times each power-up has been taken this run, keyed by PowerUp.id
var power_up_levels: Dictionary[StringName, int] = {}

## List of enemy types that can spawn
var enemy_list: Array[EnemyDef] = [
	preload("res://src/resources/beaver.tres"),
	preload("res://src/resources/axolotl.tres"),
]

# Game stats
## Kills this run, keyed by EnemyDef.id
var kills: Dictionary[StringName, int] = {}
## Running score from kills, so the tally never has to walk the enemy list
var kill_score: int = 0
## Game time in seconds
var time_elapsed: int = 0

var is_debug: bool = false


func _ready() -> void:
	print("[Stats] ready")


## Restore every run value to its starting state
func reset() -> void:
	player_xp = 0.0
	score = 0
	is_victory = false
	player_level = 1
	level_xp_needed = DEFAULT_LEVEL_XP_NEEDED

	player_health = DEFAULT_PLAYER_HEALTH
	current_player_health = DEFAULT_PLAYER_HEALTH

	fire_interval = DEFAULT_FIRE_INTERVAL
	current_fire_interval = DEFAULT_FIRE_INTERVAL
	bullet_speed = DEFAULT_BULLET_SPEED
	current_bullet_speed = DEFAULT_BULLET_SPEED
	bullet_damage = DEFAULT_BULLET_DAMAGE
	current_bullet_damage = DEFAULT_BULLET_DAMAGE

	enemy_spawn_time = DEFAULT_ENEMY_SPAWN_TIME

	power_up_levels.clear()

	# Seed every known type at zero so the readouts list them from the start
	kills.clear()
	for enemy_def: EnemyDef in enemy_list:
		kills[enemy_def.id] = 0
	kill_score = 0

	time_elapsed = 0


## Record one kill and bank what it is worth
func add_kill(enemy_def: EnemyDef) -> void:
	kills[enemy_def.id] = kills.get(enemy_def.id, 0) + 1
	kill_score += enemy_def.score_value


## Kills recorded for one enemy type this run
func kills_of(enemy_def: EnemyDef) -> int:
	return kills.get(enemy_def.id, 0)


## Pick an enemy type at random, biased by each type's spawn_weight
func random_enemy_def() -> EnemyDef:
	# Line the enemy types up, each taking a stretch as wide as its
	# spawn_weight. Beaver 0.35 and Axolotl 0.65 lay out like this:
	#
	#   0.0        0.35                  1.0
	#   |--Beaver--|-------Axolotl-------|
	#
	# Drop a random point on that line, return whoever's stretch it lands in.
	var total: float = 0.0
	for enemy_def: EnemyDef in enemy_list:
		total += enemy_def.spawn_weight
	var point: float = randf() * total
	
	# Walk left to right until the point falls short of the current right edge
	var edge: float = 0.0
	for enemy_def: EnemyDef in enemy_list:
		edge += enemy_def.spawn_weight
		if point < edge:
			return enemy_def
	
	# Only reached if every weight is 0, which leaves no stretch to land in
	return enemy_list.back()


## How many times a power-up has been taken this run
func power_up_level(power_up: PowerUp) -> int:
	return power_up_levels.get(power_up.id, 0)


## True once a power-up has hit its max_level (max_level 0 means never)
func is_power_up_capped(power_up: PowerUp) -> bool:
	return power_up.max_level > 0 and power_up_level(power_up) >= power_up.max_level


## Calculate the final score
func calculate_score() -> void:
	score = time_elapsed + kill_score \
	+ int(player_health - DEFAULT_PLAYER_HEALTH) \
	+ int(current_player_health - DEFAULT_PLAYER_HEALTH) \
	+ player_level * 5
