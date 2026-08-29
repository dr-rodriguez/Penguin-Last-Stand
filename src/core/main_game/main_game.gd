extends Node

## Which UI currently owns the pause, so two of them can't fight over it
enum PauseSource { NONE, START, MENU, LEVEL_UP }

@onready var enemy_pool: Pool = %EnemyPool
@onready var snowball_pool: Pool = %SnowballPool
@onready var player: CharacterBody2D = %Player
@onready var shoot_point: Marker2D = %ShootPoint
@onready var shoot_timer: Timer = %ShootTimer
@onready var debug_layer := $DebugLayer
@onready var game_timer: Timer = %GameTimer
@onready var pause_menu: Control = %Pause
@onready var start_menu: Control = %Start
@onready var world_layer := %World
@onready var hud_layer := %HudLayer
@onready var music_player_a: AudioStreamPlayer = %MusicPlayerA
@onready var music_player_b: AudioStreamPlayer = %MusicPlayerB
@onready var sfx_player: AudioStreamPlayer = %SfxPlayer

const MUSIC_FADE: float = 0.8

var on_cooldown: bool = false
var pause_source: PauseSource = PauseSource.NONE
var music_tween: Tween
## The player that owns the audible track; the other one is free to fade in
var music_current: AudioStreamPlayer


func _ready() -> void:
	# Show the start menu at game start, pauses the game
	_show_start_menu()
	
	# Connect signals
	Game.snowball_done.connect(_on_snowball_done)
	Game.level_up.connect(_pause_for.bind(PauseSource.LEVEL_UP))
	Game.powerup_selected.connect(_on_powerup_selected)
	Game.game_started.connect(_start_game)
	pause_menu.resume_requested.connect(_pause_for.bind(PauseSource.NONE))
	Game.start_menu_requested.connect(_show_start_menu)

	debug_layer.visible = Stats.debug_flag


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
	start_menu.visible = source == PauseSource.START
	pause_menu.visible = source == PauseSource.MENU


## A power-up choice ends the level-up pause
func _on_powerup_selected(_power_up_name: String) -> void:
	_pause_for(PauseSource.NONE)


## Show the start menu
func _show_start_menu() -> void:
	# Start music
	play_music_track(Game.START_MUSIC)
	
	# Make sure stats are reset
	Stats.reset()
	Game.stats_refreshed.emit()
	
	# Despawn all enemies/snowballs
	_clear_pool(snowball_pool, "Bullet")
	_clear_pool(enemy_pool, "Enemy")
	
	# Hide the world and hud
	world_layer.visible = false
	hud_layer.visible = false
	
	# Pause until player action
	_pause_for(PauseSource.START)


## Start the game
func _start_game() -> void:
	# Unpause and hide the start menu
	_pause_for(PauseSource.NONE)
	start_menu.visible = false
	
	# Show the world and hud
	world_layer.visible = true
	hud_layer.visible = true
	
	# Game music
	play_music_track(Game.GAME_MUSIC)


## Play music tracks, crossfading between them
func play_music_track(track: AudioStream) -> void:
	# Already the audible track, nothing to do
	if music_current != null and music_current.stream == track:
		return

	# Swap players: whatever isn't current takes the new track
	var prev := music_current
	var next := music_player_b if music_current == music_player_a else music_player_a
	music_current = next

	# Remove any existing music_tween
	if music_tween != null and music_tween.is_valid():
		music_tween.kill()

	# Set the next track
	next.stream = track
	next.volume_linear = 0.0
	next.play()

	# Use a tween to fade in/out a music track
	music_tween = create_tween()
	music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	music_tween.set_parallel(true)

	# Fade out prev (first call has none), fade in next
	if prev != null:
		music_tween.tween_property(prev, "volume_linear", 0.0, MUSIC_FADE)
		# Free the player once it's silent, so it's clean for the next swap
		music_tween.finished.connect(prev.stop)
	music_tween.tween_property(next, "volume_linear", 1.0, MUSIC_FADE)


## Clear all objects in the pool (enemies, bullets)
func _clear_pool(pool: Pool, pool_str: String) -> void:
	var pool_nodes = get_tree().get_nodes_in_group(pool_str)
	for n in pool_nodes:
		pool.release(n)


## Acquire snowball from pool
func _fire_snowball() -> void:
	# Get the scene and call it's launch method
	var snowball: Node = snowball_pool.acquire()
	if snowball == null:
		return
	snowball.global_position = shoot_point.global_position
	snowball.launch()
	
	sfx_player.stream = Game.SNOWBALL_SFX
	sfx_player.play()
	
	# Start the timer
	shoot_timer.start(Stats.current_fire_interval)
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
