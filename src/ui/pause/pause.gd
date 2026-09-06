extends Control

## Emitted when the player asks to leave the pause menu
signal resume_requested

@onready var time_label: Label = %TimeLabel
@onready var health_label: Label = %HealthLabel
@onready var level_label: Label = %LevelLabel
@onready var xp_label: Label = %XPLabel
@onready var fire_rate_label: Label = %FireRateLabel
@onready var damage_label: Label = %DamageLabel
@onready var kill_list: HBoxContainer = %KillList


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	update_labels()


## Refresh the stats every time the menu comes up
func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		update_labels()


## Update all the text
func update_labels() -> void:
	time_label.text = Game.format_time(Stats.MAX_TIME - Stats.time_elapsed)
	health_label.text = Game.format_pair(Stats.current_player_health, Stats.player_health, 0)
	level_label.text = str(Stats.player_level)
	KillList.refresh(kill_list)
	xp_label.text = Game.format_pair(Stats.player_xp, Stats.level_xp_needed, 0)
	fire_rate_label.text = Game.format_stat(Stats.current_fire_interval, 2)
	damage_label.text = Game.format_stat(Stats.current_bullet_damage, 1)


## Resume the game
func _on_resume_button_pressed() -> void:
	Game.button_click_sfx()
	resume_requested.emit()


## Close the game entirely
func _on_quit_button_pressed() -> void:
	Game.button_click_sfx()
	get_tree().quit()


## Go back to start menu
func _on_restart_button_pressed() -> void:
	Game.button_click_sfx()
	Game.start_menu_requested.emit()
