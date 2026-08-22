extends Node

## Which UI currently owns the pause, so two of them can't fight over it
enum PauseSource { NONE, MENU, LEVEL_UP }

@onready var snowball_pool: Pool = %SnowballPool
@onready var player: CharacterBody2D = %Player
@onready var shoot_point: Marker2D = %ShootPoint
@onready var shoot_timer: Timer = %ShootTimer
@onready var debug_layer := $DebugLayer
@onready var game_timer: Timer = %GameTimer
@onready var pause_menu: Control = %Pause

var on_cooldown: bool = false
var pause_source: PauseSource = PauseSource.NONE

func _ready() -> void:
	# Connect signals
	Game.snowball_done.connect(_on_snowball_done)
	Game.level_up.connect(_pause_for.bind(PauseSource.LEVEL_UP))
	Game.powerup_selected.connect(_on_powerup_selected)
	pause_menu.resume_requested.connect(_pause_for.bind(PauseSource.NONE))

	debug_layer.visible = Game.debug_flag


func _process(_delta: float) -> void:
	# Pause toggle runs even while paused, otherwise there is no way back out
	if Input.is_action_just_pressed("pause"):
		_toggle_pause()
		return

	# No other input handling/processing when paused
	if get_tree().paused:
		return

	# Continuously shoot (_input only fires per event)
	if Input.is_action_pressed("shoot") and not on_cooldown:
		_fire_snowball()


## Flip the pause menu on and off
func _toggle_pause() -> void:
	# The level-up screen owns the screen while it's up, leave it alone
	if pause_source == PauseSource.LEVEL_UP:
		return
	_pause_for(PauseSource.MENU if pause_source == PauseSource.NONE else PauseSource.NONE)


## Single owner of the pause flag and the pause menu's visibility
func _pause_for(source: PauseSource) -> void:
	pause_source = source
	get_tree().paused = source != PauseSource.NONE
	pause_menu.visible = source == PauseSource.MENU


## A power-up choice ends the level-up pause
func _on_powerup_selected(_power_up_name: String) -> void:
	_pause_for(PauseSource.NONE)


## Acquire snowball from pool
func _fire_snowball() -> void:
	# Get the scene and call it's launch method
	var snowball: Node = snowball_pool.acquire()
	if snowball == null:
		return
	snowball.global_position = shoot_point.global_position
	snowball.launch()
	
	# Start the timer
	shoot_timer.start(Game.current_fire_interval)
	on_cooldown = true


## Release a spent snowball (out of range or hit target)
func _on_snowball_done(snowball: Node) -> void:
	#print("[Main] " + str(object) + " released")
	snowball_pool.release(snowball)


func _on_shoot_timer_timeout() -> void:
	on_cooldown = false


## Every second, emit a game tick
func _on_game_timer_timeout() -> void:
	Game.game_tick.emit()
