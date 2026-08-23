extends CharacterBody2D


const PLAYER_SPEED: float = 100.0

var direction: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurt_box: Area2D = $HurtBox
@onready var damage_cooldown: Timer = $DamageCooldown


func _physics_process(_delta: float) -> void:
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * PLAYER_SPEED
	move_and_slide()
	_anim_update()
	_check_enemy_contact()


func _anim_update() -> void:
	# Don't update sprite if not moving
	if velocity == Vector2.ZERO:
		return
	
	# Flip to direction of motion
	sprite.flip_h = direction.x < 0


## Check if an enemy is touching the player
func _check_enemy_contact() -> void:
	# No damage if in cooldown
	if not damage_cooldown.is_stopped():
		return

	for body in hurt_box.get_overlapping_bodies():
		# Skip pooled-but-idle enemies
		if not "Enemy" in body.get_groups() or not body.active:
			continue
		
		take_damage(body.damage)
		#print("[Player] hit by %s @ %s hp=%s" % [body.get_instance_id(), body.global_position, body.health])
		
		# Reciprocal damage to enemy
		# TODO: Decide if this should be bullet damage or some other value
		body.take_damage(Stats.current_bullet_damage)
		
		# Start cooldown so player doesn't take too much damage
		damage_cooldown.start()
		return


## Method for player to take damage
func take_damage(value: float) -> void:
	Stats.current_player_health -= value
	damage_fx()
	Game.player_hit.emit()
	
	# TODO: Add logic for when below 0 health
	
	# Emit signal when player lost
	if Stats.current_player_health <= 0:
		Game.run_lost.emit()


## Damage FX indicator
func damage_fx() -> void:
	var hit_time: float = 0.15
	var tween = get_tree().create_tween()
	# Flash red when hit
	tween.tween_property(sprite, "modulate", Color.RED, hit_time)
	tween.tween_property(sprite, "modulate", Color.WHITE, hit_time)
