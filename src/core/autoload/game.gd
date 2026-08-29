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
signal stats_refreshed()
signal start_menu_requested()
signal game_started()


func _ready() -> void:
	Stats.reset()
	print("[Game] ready")
	
	# Signal connnections
	game_tick.connect(calculate_time_stats)
	enemy_defeated.connect(_on_enemy_defeated)
	level_up.connect(_on_level_up)
	powerup_selected.connect(_on_powerup_selected)


## Logic for any time calculations
func calculate_time_stats() -> void:
	Stats.time_elapsed += 1
	
	# Reached end time, emit win signal
	if Stats.time_elapsed >= Stats.MAX_TIME:
		run_won.emit()
	
	# Increase difficulty every 2 minutes
	if Stats.time_elapsed % 120 == 0:
		_increase_difficulty()


## Formats a time in seconds as MM:SS (e.g. 900 -> "15:00")
func format_time(seconds: int) -> String:
	@warning_ignore("INTEGER_DIVISION") 
	return "%02d:%02d" % [seconds / 60, seconds % 60]


## Handle XP when enemies are defeated
func _on_enemy_defeated(_n: Node) -> void:
	Stats.player_xp += 1
	
	# Level up logic
	if Stats.player_xp >= Stats.level_xp_needed:
		level_up.emit()


## Increase the difficulty
func _increase_difficulty() -> void:
	Stats.enemy_spawn_time *= (1.0 - Stats.GROWTH)
	print("[Game] Spawn time now " + str(Stats.enemy_spawn_time))


## Handle level ups
func _on_level_up() -> void:
	# Reset current XP amount
	Stats.player_xp = 0
	Stats.level_xp_needed *= (1.0 + Stats.GROWTH)
	Stats.player_level += 1
	
	# Increase the difficutly
	_increase_difficulty()
	
	print("[Game] Level up to " + str(Stats.player_level))
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
	
	# Refresh stats, if needed
	stats_refreshed.emit()

## Increase maximum health
func _apply_health_boost() -> void:
	Stats.player_health += 10.
	Stats.current_player_health += 10.
	print("[Game] health: " + str(Stats.current_player_health) + "/" + str(Stats.player_health))

## Increase fire rate
func _apply_fire_rate_up() -> void:
	Stats.current_fire_interval *= (1.0 - Stats.POWER_GROWTH)
	Stats.fire_interval *= (1.0 - Stats.POWER_GROWTH)
	print("[Game] fire rate: " + str(Stats.current_fire_interval))

## Increase damage dealt
func _apply_damage_up() -> void:
	Stats.current_bullet_damage += 1
	Stats.bullet_damage += 1.0
	print("[Game] damage: " + str(Stats.current_bullet_damage))

#endregion
