extends CharacterBody2D

## Enemy resource to load
@export var enemy_def: EnemyDef

@onready var sprite: Sprite2D = $Sprite2D

var direction := Vector2.ZERO
var health: float
var speed: float
var damage: float

## Target to move towards
var target: Node2D = null
## Active flag
var active: bool = false


## Reset any properties between acquisitions
func _reset() -> void:
	# Safeguard against not having enemy_def set
	if enemy_def == null:
		return
	
	health = enemy_def.health
	speed = enemy_def.speed
	damage = enemy_def.damage
	
	# Set correct sprite texture
	sprite.texture = enemy_def.texture


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
	# Remove enemy if health goes negative
	if health <= 0:
		remove_enemy()


## Remove enemy node
func remove_enemy() -> void:
	# Emit signal so we can call release
	Game.enemy_defeated.emit(self)
