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

const START_MUSIC := preload("res://assets/audio/music/music_kulluh_Pink_Shores_36.mp3")
const GAME_MUSIC := preload("res://assets/audio/music/music_zapsplat_game_music_action_retro_8_bit_repeating_016.mp3")
const SNOWBALL_SFX := preload("res://assets/audio/sfx/zapsplat_science_fiction_cannon_fire_85646.mp3")
const CLICK_SFX := preload("res://assets/audio/sfx/zapsplat_multimedia_beep_soft_click_button_87548.mp3")
const IMPACT_SFX := preload("res://assets/audio/sfx/zapsplat_impacts_body_person_heavy_005_43768.mp3")

## Create new audio player for button click sounds
var sfx_player: AudioStreamPlayer


func _ready() -> void:
	# Always process, so UI sounds still play while the tree is paused
	sfx_player = AudioStreamPlayer.new()
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx_player)

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
	
	# Increase difficulty periodically
	if Stats.time_elapsed % Stats.DIFFICULTY_TIMER == 0:
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

## Increase fire rate
func _apply_fire_rate_up() -> void:
	Stats.current_fire_interval *= (1.0 - Stats.POWER_GROWTH)
	Stats.fire_interval *= (1.0 - Stats.POWER_GROWTH)

## Increase damage dealt
func _apply_damage_up() -> void:
	Stats.current_bullet_damage += 1
	Stats.bullet_damage += 1.0

#endregion


## Shared UI click sound, callable from any script as Game.button_click_sfx()
func button_click_sfx() -> void:
	sfx_player.stream = CLICK_SFX
	sfx_player.play()
