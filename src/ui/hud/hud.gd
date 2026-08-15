extends Control

@onready var health_bar: ProgressBar = %HealthBar
@onready var xp_bar: ProgressBar = %XpBar
@onready var time_label: Label = %TimeLabel
@onready var level_label: Label = %LevelLabel

func _ready() -> void:
	health_bar.max_value = Game.player_health
	health_bar.value = Game.current_player_health
	xp_bar.value = Game.player_xp
	xp_bar.max_value = Game.level_xp_needed
	
	# Signals
	Game.player_hit.connect(_on_player_hit)
	Game.game_tick.connect(_on_game_tick)
	Game.enemy_defeated.connect(_on_enemy_defeated)
	Game.level_up.connect(_on_level_up)
	
	time_label.text = Game.format_time(Game.MAX_TIME)


func _update_xp_bar() -> void:
	var tween := get_tree().create_tween().set_parallel()
	tween.tween_property(xp_bar, "value", Game.player_xp, 0.2)
	tween.tween_property(xp_bar, "max_value", Game.level_xp_needed, 0.2)


func _on_player_hit() -> void:
	var tween := get_tree().create_tween().set_parallel()
	tween.tween_property(health_bar, "max_value", Game.player_health, 0.2)
	tween.tween_property(health_bar, "value", Game.current_player_health, 0.2)


func _on_game_tick() -> void:
	time_label.text = Game.format_time(Game.MAX_TIME - Game.time_elapsed)


func _on_enemy_defeated(_n: Node) -> void:
	_update_xp_bar()


func _on_level_up() -> void:
	level_label.text = "Level: " + str(Game.player_level)
	_update_xp_bar()
