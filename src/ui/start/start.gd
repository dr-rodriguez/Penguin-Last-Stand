extends Control

func _ready() -> void:
	pass



## Quit the game
func _on_quit_button_pressed() -> void:
	Game.button_click_sfx()
	get_tree().quit()


## Start the game
func _on_start_button_pressed() -> void:
	Game.button_click_sfx()
	Game.game_started.emit()


## Show options menu
func _on_options_button_pressed() -> void:
	Game.button_click_sfx()
	Game.options_menu_requested.emit()
