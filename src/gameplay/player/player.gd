extends CharacterBody2D


const PLAYER_SPEED: float = 100.0

var direction: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D


func _physics_process(_delta: float) -> void:
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * PLAYER_SPEED
	move_and_slide()
	_anim_update()


func _anim_update() -> void:
	# Don't update sprite if not moving
	if velocity == Vector2.ZERO:
		return
	
	# Flip to direction of motion
	sprite.flip_h = direction.x < 0
