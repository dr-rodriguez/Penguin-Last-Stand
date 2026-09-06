extends Control

@onready var card_list: Array = [%Card1, %Card2, %Card3]


func _ready() -> void:
	Game.leveled_up.connect(show_options)
	Game.powerup_selected.connect(_on_powerup_selected)


## Deal a fresh random power-up to each card, then reveal the screen
func show_options() -> void:
	# Anything already at max_level is out of the running
	var pool: Array[PowerUp] = []
	for power_up: PowerUp in Stats.power_up_list:
		if not Stats.is_power_up_capped(power_up):
			pool.append(power_up)
	pool.shuffle()
	
	# Everything is capped: nothing to offer, so don't hold the run hostage
	if pool.is_empty():
		Game.powerup_selected.emit(null)
		return
	
	# Deal what's left; any spare card sits this level out
	for i in card_list.size():
		var has_offer: bool = i < pool.size()
		card_list[i].visible = has_offer
		if has_offer:
			card_list[i].powerup = pool[i]
	show()


func _on_powerup_selected(_power_up: PowerUp) -> void:
	# Play click sound
	Game.button_click_sfx()
	
	print("[LevelUp] done.")
	hide()
