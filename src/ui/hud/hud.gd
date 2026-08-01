extends Control

@onready var health_bar: ProgressBar = %HealthBar

func _ready() -> void:
	health_bar.max_value = Game.player_health
	health_bar.value = Game.current_player_health
	Game.player_hit.connect(_on_player_hit)


func _on_player_hit() -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(health_bar, "value", Game.current_player_health, 0.2)
