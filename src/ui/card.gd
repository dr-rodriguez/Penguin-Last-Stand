extends Control

@export var powerup: PowerUp

@onready var title: Label = %TitleLabel
@onready var description: Label = %DescriptionLabel
@onready var image: TextureRect = %Image

func _ready() -> void:
	title.text = powerup.title
	image.texture = powerup.texture
	description.text = powerup.description
