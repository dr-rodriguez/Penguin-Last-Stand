extends Control

@onready var shoot_button: CheckButton = %AutoShootButton
@onready var joystick_button: CheckButton = %JoystickButton

func _ready() -> void:
	shoot_button.button_pressed = Settings.auto_shoot
	joystick_button.button_pressed = Settings.joystick_enabled


## Go back to start menu
func _on_restart_button_pressed() -> void:
	Game.button_click_sfx()
	Game.start_menu_requested.emit()


func _on_auto_shoot_button_toggled(toggled_on: bool) -> void:
	Game.button_click_sfx()
	Settings.auto_shoot = toggled_on


func _on_joystick_button_toggled(toggled_on: bool) -> void:
	Game.button_click_sfx()
	Settings.joystick_enabled = toggled_on
