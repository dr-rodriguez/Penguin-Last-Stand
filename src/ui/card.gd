extends Control

## Power-up this card offers; setting it refreshes the card visuals
@export var powerup: PowerUp:
	set(value):
		powerup = value
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
	if powerup == null:
		return
	title.text = powerup.title
	image.texture = powerup.texture
	description.text = powerup.description


func _on_button_pressed() -> void:
	# Send a signal with the name of the selected power-up
	Game.powerup_selected.emit(powerup.name)
