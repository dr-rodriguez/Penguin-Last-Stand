extends Area2D

var direction := Vector2.ZERO
var travelled_distance: float = 0.0
var speed: float = Game.current_bullet_speed
const RANGE: float = 300.


## Reset and specify movement direction and speed
func launch() -> void:
	# Reset properties
	_reset()
	
	var mouse_pos: Vector2 = get_global_mouse_position()
	direction = (mouse_pos - global_position).normalized()
	speed = Game.current_bullet_speed


## Reset any properties between acquisitions
func _reset() -> void:
	travelled_distance = 0.0
	direction = Vector2.ZERO
	speed = Game.current_bullet_speed


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	
	# Keep track of how far it has gone to release it
	travelled_distance += speed * delta
	
	# If travelled beyond range, emit so pool can release
	# May also need to add logic for when it hits an enemy
	if travelled_distance > RANGE:
		Game.snowball_done.emit(self)
