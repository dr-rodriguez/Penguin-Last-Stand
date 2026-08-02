extends Path2D

@onready var spawn_follow: PathFollow2D = $SpawnFollow
@onready var spawn_timer: Timer = $SpawnTimer

@onready var enemy_pool: Pool = %EnemyPool

## Pointer to player node
@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("Player")
# Can also access via get_parent() but if I move the spawner it may break

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
	if spawn_weight <= Game.enemy_type_weight:
		enemy.enemy_def = BEAVER
	else:
		enemy.enemy_def = AXOLOTL
	
	# Start enemy movement, pass player as target
	enemy.launch(player)
	
	# Use latest spawn time
	spawn_timer.start(Game.enemy_spawn_time)
	
	#print("[Spawner] Enemy " + enemy.enemy_def.name + " added")


## Release a defeated enemy
func _on_enemy_defeated(enemy: Node) -> void:
	#print("[Sapwner] Enemy " + str(enemy) + " released")
	
	# Count score
	if enemy.enemy_def.name == "Axolotl":
		Game.axolotl_kills += 1
	elif enemy.enemy_def.name == "Beaver":
		Game.beaver_kills += 1
	Game.player_xp += 1
	
	# Release enemy back to pool
	enemy_pool.release(enemy)
