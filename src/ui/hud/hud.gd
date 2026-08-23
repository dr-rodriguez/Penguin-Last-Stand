extends Control

@onready var health_bar: ProgressBar = %HealthBar
@onready var xp_bar: ProgressBar = %XpBar
@onready var time_label: Label = %TimeLabel
@onready var level_label: Label = %LevelLabel

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
	var tween := get_tree().create_tween().set_parallel()
	tween.tween_property(xp_bar, "value", Stats.player_xp, 0.2)
	tween.tween_property(xp_bar, "max_value", Stats.level_xp_needed, 0.2)


func _on_player_hit() -> void:
	var tween := get_tree().create_tween().set_parallel()
	tween.tween_property(health_bar, "max_value", Stats.player_health, 0.2)
	tween.tween_property(health_bar, "value", Stats.current_player_health, 0.2)


func _on_game_tick() -> void:
	time_label.text = Game.format_time(Stats.MAX_TIME - Stats.time_elapsed)


func _on_enemy_defeated(_n: Node) -> void:
	_update_xp_bar()


func _on_level_up() -> void:
	level_label.text = "Level: " + str(Stats.player_level)
	_update_xp_bar()
