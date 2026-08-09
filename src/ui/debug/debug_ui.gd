extends Control

@onready var debug_label: Label = %DebugLabel

func _ready() -> void:
	_update_label(null)
	
	# Connect signals
	Game.enemy_defeated.connect(_update_label)
	

func _update_label(_n: Node) -> void:
	debug_label.text = "XP: " + \
	str(Game.player_xp) + \
	" BK: " + str(Game.beaver_kills) + \
	" AK: " + str(Game.axolotl_kills) + \
	"\nReq XP: " + str(Game.level_xp_needed)


func _on_button_pressed() -> void:
	Game.level_up.emit()
