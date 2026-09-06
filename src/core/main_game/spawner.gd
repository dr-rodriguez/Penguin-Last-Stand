extends Path2D

## Extra distance beyond the visible view where enemies appear
const SPAWN_MARGIN: float = 24.0
## How far past the spawn ring an enemy may drift before it is pulled back
const RECALL_FACTOR: float = 1.5

@onready var spawn_follow: PathFollow2D = $SpawnFollow
@onready var spawn_timer: Timer = $SpawnTimer
@onready var enemy_pool: Pool = %EnemyPool
@onready var spawn_timer_2: Timer = $SpawnTimer2

## Pointer to player node
@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("Player")
# Can also access via get_parent() but if I move the spawner it may break
# Should also be able to use %Player

## Pointer to the player's camera, used to convert screen size to world size
@onready var camera: Camera2D = %Camera2D

## Half extents of the spawn rectangle, in world units
var spawn_half_extents: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Connect signals
	Game.enemy_defeated.connect(_on_enemy_defeated)
	get_viewport().size_changed.connect(_rebuild_spawn_path)
	
	# Size the spawn ring to the current view
	_rebuild_spawn_path()


## Rebuild the spawn rect so it always sits just outside the visible view.
## The window uses an "expand" stretch aspect, so a wider screen shows more
## world - a fixed curve would end up inside the view on those screens.
func _rebuild_spawn_path() -> void:
	var view: Vector2 = get_viewport_rect().size / camera.zoom
	spawn_half_extents = view * 0.5 + Vector2(SPAWN_MARGIN, SPAWN_MARGIN)
	
	var half: Vector2 = spawn_half_extents
	var rect_curve: Curve2D = Curve2D.new()
	for corner: Vector2 in [
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
		Vector2(-half.x, -half.y),
	]:
		rect_curve.add_point(corner)
	curve = rect_curve


func _on_spawn_timer_timeout() -> void:
	# Get a random location along the path
	spawn_follow.progress_ratio = randf()
	
	# Add enemy at that location
	var enemy: Node = enemy_pool.acquire()
	if enemy == null:
		return
	enemy.global_position = spawn_follow.global_position
	
	# Randomize enemy type (change enemy.enemy_def)
	enemy.enemy_def = Stats.random_enemy_def()
	
	# Start enemy movement, pass player as target
	enemy.launch(player)
	
	# Use latest spawn time
	spawn_timer.start(Stats.enemy_spawn_time)


## Release a defeated enemy
func _on_enemy_defeated(enemy: Node) -> void:
	# Count the kill against its own type
	Stats.add_kill(enemy.enemy_def)
	# Player XP is handled by Game autoload
	
	# Release enemy back to pool
	enemy_pool.release(enemy)


## Respawn enemies if the player moves too fast
func _on_distant_player() -> void:
	# If the player puts too much distance between the enemy, 
	# will teleport the enemies back around the player
	var separation: float = 0
	# Scale with the view so ultrawide screens don't recall on-screen enemies
	var threshold: float = spawn_half_extents.length() * RECALL_FACTOR
	
	# Get all enemy nodes
	var enemy_nodes: Array[Node] = get_tree().get_nodes_in_group("Enemy")
	for n: Node in enemy_nodes:
		# Don't process hidden enemy nodes
		if n.visible == false:
			continue
		
		# Calculate distance to player
		separation = player.global_position.distance_to(n.global_position)
		
		# If larger than threshold, move it to a random location along the spawn
		if separation >= threshold:
			print("[Spawner] moving closer to player: " + str(n))
			spawn_follow.progress_ratio = randf()
			n.global_position = spawn_follow.global_position
