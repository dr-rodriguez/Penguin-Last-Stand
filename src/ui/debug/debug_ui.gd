extends Control


func _ready() -> void:
	pass
	

func _on_button_pressed() -> void:
	Game.level_up.emit()
