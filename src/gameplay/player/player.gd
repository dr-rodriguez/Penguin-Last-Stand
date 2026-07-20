extends CharacterBody2D

# Movement attributes
var direction: Vector2 = Vector2.ZERO
const PLAYER_SPEED: float = 100.0


func _physics_process(_delta: float) -> void:
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * PLAYER_SPEED
	move_and_slide()
