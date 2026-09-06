extends Control


func _on_button_pressed() -> void:
	Game.leveled_up.emit()
