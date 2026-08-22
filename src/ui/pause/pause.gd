extends Control

## Emitted when the player asks to leave the pause menu
signal resume_requested

@onready var time_label: Label = %TimeLabel
@onready var health_label: Label = %HealthLabel
@onready var level_label: Label = %LevelLabel
@onready var xp_label: Label = %XPLabel
@onready var beaver_label: Label = %BeaverLabel
@onready var axo_label: Label = %AxolotlLabel


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	update_labels()


## Refresh the stats every time the menu comes up
func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		update_labels()


## Update all the text
func update_labels() -> void:
	time_label.text = Game.format_time(Game.MAX_TIME - Game.time_elapsed)
	health_label.text = str(Game.current_player_health) + "/" + str(Game.player_health)
	level_label.text = str(Game.player_level)
	beaver_label.text = str(Game.beaver_kills)
	axo_label.text = str(Game.axolotl_kills)
	xp_label.text = str(Game.player_xp) + "/" + str(Game.level_xp_needed)


## Resume the game
func _on_resume_button_pressed() -> void:
	resume_requested.emit()


## Close the game entirely
func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_restart_button_pressed() -> void:
	pass # Replace with function body.
