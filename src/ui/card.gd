extends Control

@export var powerup: PowerUp

@onready var title: Label = %TitleLabel
@onready var description: Label = %DescriptionLabel
@onready var image: TextureRect = %Image


func _ready() -> void:
	title.text = powerup.title
	image.texture = powerup.texture
	description.text = powerup.description


func _on_button_pressed() -> void:
	print("[Card] Choose " + powerup.name)
	# Send a signal with the name of the selected power-up
	Game.powerup_selected.emit(powerup.name)
