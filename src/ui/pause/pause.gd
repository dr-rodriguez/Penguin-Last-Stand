extends Control

## Emitted when the player asks to leave the pause menu
signal resume_requested

@onready var time_label: Label = %TimeLabel
@onready var health_label: Label = %HealthLabel
@onready var level_label: Label = %LevelLabel
@onready var xp_label: Label = %XPLabel
@onready var fire_rate_label: Label = %FireRateLabel
@onready var damage_label: Label = %DamageLabel
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
	time_label.text = Game.format_time(Stats.MAX_TIME - Stats.time_elapsed)
	health_label.text = _format_pair(Stats.current_player_health, Stats.player_health, 0)
	level_label.text = str(Stats.player_level)
	beaver_label.text = str(Stats.beaver_kills)
	axo_label.text = str(Stats.axolotl_kills)
	xp_label.text = _format_pair(Stats.player_xp, Stats.level_xp_needed, 0)
	fire_rate_label.text = _format_stat(Stats.current_fire_interval, 2)
	damage_label.text = _format_stat(Stats.current_bullet_damage, 1)


## Formats a current/max stat pair to the given decimal count (e.g. "42/50")
func _format_pair(current: float, maximum: float, precision: int = 0) -> String:
	var spec: String = _decimal_spec(precision)
	return (spec + "/" + spec) % [current, maximum]


## Formats a single stat to the given decimal count (e.g. "4.5")
func _format_stat(value: float, precision: int = 1) -> String:
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
