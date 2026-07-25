extends Node

@onready var snowball_pool := %SnowballPool
@onready var player: CharacterBody2D = %Player
@onready var shooting_point: Marker2D = %ShootPoint
@onready var shoot_timer: Timer = %ShootTimer

var on_cooldown: bool = false

func _ready() -> void:
	# Connect signals
	Game.snowball_done.connect(_on_snowball_done)


func _process(_delta: float) -> void:
	# Continuously shoot (_input only fires per event)
	if Input.is_action_pressed("shoot") and not on_cooldown:
		_fire_snowball()


## Acquire snowball from pool
func _fire_snowball() -> void:
	# Get the scene and call it's launch method
	var b = snowball_pool.acquire()
	b.global_position = shooting_point.global_position
	b.launch()
	
	# Start the timer
	shoot_timer.start(Game.current_fire_interval)
	on_cooldown = true


## Release a spent snowball (out of range or hit target)
func _on_snowball_done(object) -> void:
	#print("[Main] " + str(object) + " released")
	snowball_pool.release(object)


func _on_shoot_timer_timeout() -> void:
	on_cooldown = false
