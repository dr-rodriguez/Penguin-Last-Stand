extends CharacterBody2D

## Enemy resource to load
@export var enemy_def: EnemyDef

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var direction := Vector2.ZERO
var health: float
var speed: float
var damage: float

## Target to move towards
var target: Node2D = null
## Active flag
var active: bool = false
## Live hit-flash tween, killed before the node goes back to the pool
var flash_tween: Tween


## Reset any properties between acquisitions
func _reset() -> void:
	# Re-enable collision after being released back to the pool
	collision_shape.set_deferred("disabled", false)
	
	# Drop any flash left over from the previous life
	_kill_flash()

	# Safeguard against not having enemy_def set
	if enemy_def == null:
		return
	
	health = enemy_def.health
	speed = enemy_def.speed
	damage = enemy_def.damage
	
	# Set correct sprite texture
	sprite.texture = enemy_def.texture
	sprite.modulate = Color.WHITE


func _ready() -> void:
	# Reset properties
	_reset()


func _physics_process(_delta: float) -> void:
	# Safeguard against not being active
	if not active or target == null:
		return
	
	# Get direction and velocity towards player, then move towards them
	direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	# Flip to direction of motion
	sprite.flip_h = direction.x < 0


## Reset and start movement
func launch(new_target: Node2D) -> void:
	# Reset properties
	_reset()
	target = new_target
	active = true


## Take damage
func take_damage(value: float) -> void:
	health -= value
	
	damage_fx()
	
	# Remove enemy if health goes negative
	if health <= 0:
		remove_enemy()


## Damage FX indicator
func damage_fx() -> void:
	var hit_time: float = 0.2
	
	# Restart the flash instead of stacking a second one on top
	_kill_flash()
	
	# Node-bound so the tween dies with the enemy, not with the scene tree
	flash_tween = create_tween()
	# Flash red when hit
	flash_tween.tween_property(sprite, "modulate", Color.RED, hit_time)
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, hit_time)


## Remove enemy node
func remove_enemy() -> void:
	# Stop being hittable/touchable while idle in the pool
	active = false
	collision_shape.set_deferred("disabled", true)
	
	# A pooled node never frees, so the flash has to be stopped by hand
	_kill_flash()
	sprite.modulate = Color.WHITE

	# Emit signal so we can call release
	Game.enemy_defeated.emit(self)


## Stop any running hit-flash so it can't write to a reused sprite
func _kill_flash() -> void:
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	flash_tween = null
