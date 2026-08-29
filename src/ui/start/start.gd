extends Control

func _ready() -> void:
	pass



## Quit the game
func _on_quit_button_pressed() -> void:
	get_tree().quit()


## Start the game
func _on_start_button_pressed() -> void:
	Game.game_started.emit()
