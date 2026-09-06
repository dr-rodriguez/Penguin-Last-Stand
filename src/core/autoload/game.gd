extends Node

# Global signals for ease of use
# Change Project Settings-Debug-GDScript-Warnings to ingore these warnings
@warning_ignore("unused_signal") 
signal snowball_done(n: Node)
signal enemy_defeated(n: Node)
signal player_hit()
signal tick_elapsed()
signal leveled_up()
signal power_up_selected(power_up: PowerUp)
signal stats_refreshed()
signal start_menu_requested()
signal game_started()
signal game_ended()
signal options_menu_requested()

const START_MUSIC := preload("res://assets/audio/music/music_kulluh_Pink_Shores_36.mp3")
const GAME_MUSIC := preload("res://assets/audio/music/music_zapsplat_game_music_action_retro_8_bit_repeating_016.mp3")
const SNOWBALL_SFX := preload("res://assets/audio/sfx/zapsplat_cartoon_swipe_grab_fast_swish_003_115127.mp3")
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
	tick_elapsed.connect(calculate_time_stats)
	enemy_defeated.connect(_on_enemy_defeated)
	leveled_up.connect(_on_leveled_up)
	power_up_selected.connect(_on_power_up_selected)


## Logic for any time calculations
func calculate_time_stats() -> void:
	Stats.time_elapsed += 1
	
	# Check if game is over
	_check_game_end()
	
	# Increase difficulty periodically
	if Stats.time_elapsed % Stats.DIFFICULTY_TIMER == 0:
		_increase_difficulty()


## Shared UI click sound, callable from any script as Game.button_click_sfx()
func button_click_sfx() -> void:
	sfx_player.stream = CLICK_SFX
	sfx_player.play()


## Handle XP when enemies are defeated
func _on_enemy_defeated(_n: Node) -> void:
	Stats.player_xp += 1
	
	# Level up logic
	if Stats.player_xp >= Stats.level_xp_needed:
		leveled_up.emit()


## Increase the difficulty
func _increase_difficulty() -> void:
	Stats.enemy_spawn_time *= (1.0 - Stats.GROWTH)
	print("[Game] Spawn time now " + str(Stats.enemy_spawn_time))


## Handle level ups
func _on_leveled_up() -> void:
	# Reset current XP amount
	Stats.player_xp = 0
	Stats.level_xp_needed *= (1.0 + Stats.GROWTH)
	Stats.player_level += 1
	
	# Increase the difficutly
	_increase_difficulty()
	
	print("[Game] Level up to " + str(Stats.player_level))
	# MainGame freezes the run until a power-up is picked


## Check if the game is over
func _check_game_end() -> void:
	# Player reached the end of the timer
	if Stats.time_elapsed >= Stats.MAX_TIME:
		Stats.is_victory = true
		game_ended.emit()
		return
	# Player lost
	elif Stats.current_player_health <= 0:
		Stats.is_victory = false
		game_ended.emit()
		return
	# No action, continue the game
	else:
		return


#region Power Up Logic
## Handle power ups
func _on_power_up_selected(power_up: PowerUp) -> void:
	# A level-up with nothing left to offer passes null; just resume the run
	if power_up == null:
		print("[Game] No power-up available")
		return
	
	print("[Game] Choose " + power_up.id)
	
	_apply_power_up(power_up)
	# MainGame resumes the run now that the choice is made
	
	# Refresh stats, if needed
	stats_refreshed.emit()


## Fold a power-up's effect into the stat it names, plus that stat's live twin
func _apply_power_up(power_up: PowerUp) -> void:
	var base_name: StringName = power_up.stat
	if base_name == &"":
		push_warning("[Game] %s has no stat set" % power_up.id)
		return
	
	# Every tunable stat is a base/current pair, e.g. fire_interval and
	# current_fire_interval. The base moves first: current clamps against it.
	var current_name := StringName("current_" + base_name)
	var base_value: float = Stats.get(base_name)
	var current_value: float = Stats.get(current_name)
	
	match power_up.mode:
		PowerUp.Mode.ADD:
			base_value += power_up.amount
			current_value += power_up.amount
		PowerUp.Mode.MULTIPLY:
			base_value *= power_up.amount
			current_value *= power_up.amount
	
	Stats.set(base_name, base_value)
	Stats.set(current_name, current_value)
	
	# Count the pick so capped power-ups stop being offered
	Stats.power_up_levels[power_up.id] = Stats.power_up_levels.get(power_up.id, 0) + 1

#endregion


#region Formatting functions
## Formats a time in seconds as MM:SS (e.g. 900 -> "15:00")
func format_time(seconds: int) -> String:
	@warning_ignore("integer_division")
	return "%02d:%02d" % [seconds / 60, seconds % 60]


## Formats a current/max stat pair to the given decimal count (e.g. "42/50")
func format_pair(current: float, maximum: float, precision: int = 0) -> String:
	var spec: String = _decimal_spec(precision)
	return (spec + "/" + spec) % [current, maximum]


## Formats a single stat to the given decimal count (e.g. "4.5")
func format_stat(value: float, precision: int = 1) -> String:
	return _decimal_spec(precision) % value


## Builds a float format spec with the given decimal count (1 -> "%.1f")
func _decimal_spec(precision: int) -> String:
	# "%%.%df"   template
	#  ^^        -> "%"      literal percent
	#    ^       -> "."      literal dot
	#     ^^     -> "1"      maxi(1, 0) substituted
	#       ^    -> "f"      literal f
	# result: "%.1f"
	return "%%.%df" % maxi(precision, 0)
#endregion
