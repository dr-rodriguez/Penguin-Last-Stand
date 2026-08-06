extends Control

@onready var health_bar: ProgressBar = %HealthBar
@onready var time_label: Label = %TimeLabel

func _ready() -> void:
	health_bar.max_value = Game.player_health
	health_bar.value = Game.current_player_health
	Game.player_hit.connect(_on_player_hit)
	Game.game_tick.connect(_on_game_tick)
	
	time_label.text = Game.format_time(Game.MAX_TIME)


func _on_player_hit() -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(health_bar, "value", Game.current_player_health, 0.2)


func _on_game_tick() -> void:
	time_label.text = Game.format_time(Game.MAX_TIME - Game.time_elapsed)
