extends Control

@onready var title_label: Label = %TitleLabel
@onready var score_label: Label = %ScoreLabel
@onready var time_label: Label = %TimeLabel
@onready var health_label: Label = %HealthLabel
@onready var level_label: Label = %LevelLabel
@onready var kill_list: HBoxContainer = %KillList


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	update_labels()


## Refresh the stats every time the menu comes up
func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		update_labels()


func update_labels() -> void:
	if Stats.is_victory:
		title_label.text = "Game Over: Victory!"
	else:
		title_label.text = "Game Over: Defeat!"
	
	time_label.text = Game.format_time(Stats.MAX_TIME - Stats.time_elapsed)
	health_label.text = Game.format_pair(Stats.current_player_health, Stats.player_health, 0)
	level_label.text = str(Stats.player_level)
	KillList.refresh(kill_list)
	
	Stats.calculate_score()
	score_label.text = str(Stats.score)


## Close the game entirely
func _on_quit_button_pressed() -> void:
	Game.button_click_sfx()
	get_tree().quit()


## Go back to start menu
func _on_restart_button_pressed() -> void:
	Game.button_click_sfx()
	Game.start_menu_requested.emit()
