extends Control

@onready var health_bar: ProgressBar = %HealthBar
@onready var xp_bar: ProgressBar = %XpBar
@onready var time_label: Label = %TimeLabel
@onready var level_label: Label = %LevelLabel

## Live bar tweens, restarted rather than stacked
var _xp_tween: Tween
var _health_tween: Tween

func _ready() -> void:
	health_bar.max_value = Stats.player_health
	health_bar.value = Stats.current_player_health
	xp_bar.value = Stats.player_xp
	xp_bar.max_value = Stats.level_xp_needed
	
	# Signals
	Game.player_hit.connect(_on_player_hit)
	Game.game_tick.connect(_on_game_tick)
	Game.enemy_defeated.connect(_on_enemy_defeated)
	Game.level_up.connect(_on_level_up)
	Game.stats_refreshed.connect(_refresh_stats)
	
	time_label.text = Game.format_time(Stats.MAX_TIME)


## Refresh all stats in the HUD
func _refresh_stats() -> void:
	_update_xp_bar()
	_on_player_hit()
	_on_enemy_defeated(null)
	_on_game_tick()
	_on_level_up()


func _update_xp_bar() -> void:
	# Kills stack up fast: restart the fill instead of racing a second tween
	if _xp_tween != null and _xp_tween.is_valid():
		_xp_tween.kill()
	
	_xp_tween = create_tween().set_parallel()
	_xp_tween.tween_property(xp_bar, "value", Stats.player_xp, 0.2)
	_xp_tween.tween_property(xp_bar, "max_value", Stats.level_xp_needed, 0.2)


func _on_player_hit() -> void:
	# Same for repeated hits while standing in a crowd
	if _health_tween != null and _health_tween.is_valid():
		_health_tween.kill()
	
	_health_tween = create_tween().set_parallel()
	_health_tween.tween_property(health_bar, "max_value", Stats.player_health, 0.2)
	_health_tween.tween_property(health_bar, "value", Stats.current_player_health, 0.2)


func _on_game_tick() -> void:
	time_label.text = Game.format_time(Stats.MAX_TIME - Stats.time_elapsed)


func _on_enemy_defeated(_n: Node) -> void:
	_update_xp_bar()


func _on_level_up() -> void:
	level_label.text = "Level: " + str(Stats.player_level)
	_update_xp_bar()
