extends Control

@onready var card_list: Array = [%Card1, %Card2, %Card3]


func _ready() -> void:
	Game.level_up.connect(show_options)
	Game.powerup_selected.connect(_on_powerup_selected)


## Deal a fresh random power-up to each card, then reveal the screen
func show_options() -> void:
	# TODO: Remove fire rate up card if at min value (0.1)
	var pool: Array = Game.power_up_list.duplicate()
	pool.shuffle()
	for i in card_list.size():
		card_list[i].powerup = pool[i]
	show()


func _on_powerup_selected(_power_up_name: String) -> void:
	print("[LevelUp] done.")
	hide()
