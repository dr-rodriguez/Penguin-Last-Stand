extends Path2D

@onready var spawn_follow: PathFollow2D = $SpawnFollow
@onready var spawn_timer: Timer = $SpawnTimer
@onready var enemy_pool: Pool = %EnemyPool
@onready var spawn_timer_2: Timer = $SpawnTimer2

## Pointer to player node
@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("Player")
# Can also access via get_parent() but if I move the spawner it may break
# Should also be able to use %Player

const BEAVER := preload("res://src/resources/beaver.tres")
const AXOLOTL := preload("res://src/resources/axolotl.tres")


func _ready() -> void:
	# Connect signals
	Game.enemy_defeated.connect(_on_enemy_defeated)


func _on_spawn_timer_timeout() -> void:
	# Get a random location along the path
	spawn_follow.progress_ratio = randf()
	
	# Add enemy at that location
	var enemy: Node = enemy_pool.acquire()
	if enemy == null:
		return
	enemy.global_position = spawn_follow.global_position
	
	# Randomize enemy type (change enemy.enemy_def)
	var spawn_weight := randf()
	if spawn_weight <= Stats.enemy_type_weight:
		enemy.enemy_def = BEAVER
	else:
		enemy.enemy_def = AXOLOTL
	
	# Start enemy movement, pass player as target
	enemy.launch(player)
	
	# Use latest spawn time
	spawn_timer.start(Stats.enemy_spawn_time)


## Release a defeated enemy
func _on_enemy_defeated(enemy: Node) -> void:
	# Count score
	if enemy.enemy_def.name == "Axolotl":
		Stats.axolotl_kills += 1
	elif enemy.enemy_def.name == "Beaver":
		Stats.beaver_kills += 1
	# Player XP is handled by Game autoload
	
	# Release enemy back to pool
	enemy_pool.release(enemy)


## Respawn enemies if the player moves too fast
func _on_distant_player() -> void:
	# If the player puts too much distance between the enemy, 
	# will teleport the enemies back around the player
	var separation: float = 0
	const THRESHOLD: float = 500.
	
	# Get all enemy nodes
	var enemy_nodes = get_tree().get_nodes_in_group("Enemy")
	for n in enemy_nodes:
		# Don't process hidden enemy nodes
		if n.visible == false:
			continue
		
		# Calculate distance to player
		separation = player.global_position.distance_to(n.global_position)
		
		# If larger than threshold, move it to a random location along the spawn
		if separation >= THRESHOLD:
			print("[Spawner] moving closer to player: " + str(n))
			spawn_follow.progress_ratio = randf()
			n.global_position = spawn_follow.global_position
