extends Area2D

const RANGE: float = 300.

var direction := Vector2.ZERO
var travelled_distance: float = 0.0
## Set from Stats by _reset() on every launch, not at script init
var speed: float = 0.0
## Set once this snowball has spent itself, so it can only report done once
var _spent: bool = false


func _physics_process(delta: float) -> void:
	# Already reported done this frame, waiting on the pool to take it back
	if _spent:
		return
	
	position += direction * speed * delta
	
	# Keep track of how far it has gone to release it
	travelled_distance += speed * delta
	
	# If travelled beyond range, emit so pool can release
	# May also need to add logic for when it hits an enemy
	if travelled_distance > RANGE:
		_finish()


## Reset and specify movement direction and speed
func launch() -> void:
	# Reset properties
	_reset()
	
	var target_pos: Vector2 = get_global_mouse_position()
	
	# If auto_shooting, use the nearest enemy, not the mouse position
	if Settings.auto_shoot:
		# Get enemies and choot the closest
		var nearest: Node2D = _get_nearest_enemy()
		if nearest != null:
			target_pos = nearest.global_position

	direction = (target_pos - global_position).normalized()
	speed = Stats.current_bullet_speed


## Reset any properties between acquisitions
func _reset() -> void:
	travelled_distance = 0.0
	direction = Vector2.ZERO
	speed = Stats.current_bullet_speed
	_spent = false


## Closest live enemy in range, or null
func _get_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist_sq: float = RANGE * RANGE
	
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		var dist_sq: float = global_position.distance_squared_to(enemy.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = enemy
	
	return nearest


## Hit an enemy
func _on_body_entered(body: Node2D) -> void:
	# Overlaps are reported per body, so a crowd can fire this several times in
	# one frame. Only the first one gets to spend the snowball.
	if _spent:
		return
	
	# Check if body hit is an enemy
	if "Enemy" in body.get_groups():
		#print("[Snowball] hit enemy " + str(body))
		# Do damage to enemy
		body.take_damage(Stats.current_bullet_damage)
		_finish()


## Spend the snowball and ask the pool to take it back
func _finish() -> void:
	_spent = true
	Game.snowball_done.emit(self)
