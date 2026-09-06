extends Control

## Power-up this card offers; setting it refreshes the card visuals
@export var power_up: PowerUp:
	set(value):
		power_up = value
		# The setter also runs before @onready vars resolve, so guard on readiness
		if is_node_ready():
			_refresh()

@onready var title: Label = %TitleLabel
@onready var description: Label = %DescriptionLabel
@onready var image: TextureRect = %Image


func _ready() -> void:
	_refresh()


## Push the current power-up's data into the card's labels and texture
func _refresh() -> void:
	if power_up == null:
		return
	title.text = power_up.title
	image.texture = power_up.texture
	description.text = power_up.description


func _on_button_pressed() -> void:
	# Send a signal with the selected power-up itself
	if power_up == null:
		return
	Game.power_up_selected.emit(power_up)
