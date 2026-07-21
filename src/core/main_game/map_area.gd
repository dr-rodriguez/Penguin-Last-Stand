extends TileMapLayer

# This script generates the map procedurally. 
# We use PERIOD as the size of each tile and repeat it as the player moves through the world.

# Noise thresholds as export values
## Water threshold
@export var water_threshold: float = 0.2
## Dirt threshold
@export var dirt_threshold: float = 0.4
## Grass threshold
@export var grass_threshold: float = 0.85
# rock_cutoff not used- anything higher than grass is rock

## Tiles per wrap
const PERIOD: int = 128
## Tiles per chunk edge
const CHUNK: int = 16
## Number of chunks around the player
const LOAD_RADIUS: int = 2
## Number of varient versions of each terrain
const VARIANTS: int = 3
## Source ID for TileSet
const SOURCE_ID: int = 0

## Terrain possibilities
enum Terrain {GRASS, DIRT, ROCK, WATER}
# These are effectively ints, so Terrain.GRASS == 0

## Player character scene
@export var _player: CharacterBody2D

## Tile storage (noise values for the tile)
var _tiles: PackedByteArray
# Unpacking notes for _tiles and similar arrays:
# i = y * PERIOD + x          # cell -> index
# x = i % PERIOD              # index -> cell
# y = i / PERIOD              # integer division

## Dictionary of loaded chunks (keys are Vector2i coords, values are true/false)
var _loaded: Dictionary = {}

## Noise generator
var noise := FastNoiseLite.new()

# Noise cutoff values for terrain
var water_cutoff: float
var dirt_cutoff: float
var grass_cutoff: float


func _ready() -> void:
	# Generate tiles from noise
	_bake_noise()
	
	print("[MapArea] Generated map tiles")


func _process(_delta: float) -> void:
	# Load chunks around player, unload those far away
	_refresh(_player_chunk())


## Bake the noise into the _tiles array
func _bake_noise() -> void:
	var noise_value: float
	var terrain: int
	var variant: int
	var fx: float
	var fy: float
	## Temporary float field with noise values
	var field := PackedFloat32Array()
	field.resize(PERIOD * PERIOD)
	
	# Set noise parameters
	noise.set_noise_type(FastNoiseLite.TYPE_SIMPLEX_SMOOTH)
	noise.set_seed(randi())
	noise.set_frequency(0.02) # lower is smoother
	noise.set_fractal_octaves(3)  # from docs: number of noise layers that are sampled to get the final value
	
	# Set up tile storage
	_tiles.resize(PERIOD * PERIOD)
	
	# Generate over all x/y values within the PERIOD
	for x in range(PERIOD):
		for y in range(PERIOD):
			# x/y scaled by PERIOD (so 0.0 to 1.0)
			fx = float(x) / PERIOD
			fy = float(y) / PERIOD
			
			# Make noise symmetric
			# Biliniar blend of four offset copies
			noise_value = (
				noise.get_noise_2d(x, y)                      * (1.0 - fx) * (1.0 - fy)
				+ noise.get_noise_2d(x - PERIOD, y)           * fx         * (1.0 - fy)
				+ noise.get_noise_2d(x, y - PERIOD)           * (1.0 - fx) * fy
				+ noise.get_noise_2d(x - PERIOD, y - PERIOD)  * fx         * fy
				)
			
			# Scale noise to 0.0 to 1.0 (instead of -1 to 1)
			field[x * PERIOD + y] = noise_value
	
	# Determine exact cutoff values from percentages
	var sorted := field.duplicate()
	sorted.sort()
	var n := sorted.size()
	water_cutoff = sorted[int(n * water_threshold)]
	dirt_cutoff = sorted[int(n * dirt_threshold)]
	grass_cutoff = sorted[int(n * grass_threshold)]
	
	# Classify into byte array (indicating terrain type)
	for i in field.size():
		terrain = _classify(field[i])
		variant = randi_range(0, VARIANTS - 1)
		_tiles[i] = terrain * VARIANTS + variant


## Load/unload chunks as needed based on player position
func _refresh(center: Vector2i) -> void:
	# Check for loaded chanks that are too far away- unload them
	for c: Vector2i in _loaded.keys():
		if absi(c.x - center.x) > LOAD_RADIUS or absi(c.y - center.y) > LOAD_RADIUS:
			_unload_chunk(c)
	
	# Load chunks close to the player
	for dy: int in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for dx: int in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var c: Vector2i = center + Vector2i(dx, dy)
			if not _loaded.has(c):
				_load_chunk(c)


## Helper method to determine which chunk the player is in
func _player_chunk() -> Vector2i:
	var cell := local_to_map(to_local(_player.global_position))
	return Vector2i(
		floori(cell.x / float(CHUNK)), 
		floori(cell.y / float(CHUNK))
	)
	

## Helper method to load chunks at position c
func _load_chunk(c: Vector2i) -> void:
	var world: Vector2i
	var atlas_tile: Vector2i
	
	# Loop over x/y for CHUNK
	for x in range(CHUNK):
		for y in range(CHUNK):
			# For each, get the world i coordinates
			world = Vector2i(c.x * CHUNK + x, c.y * CHUNK + y)
			
			# Get the terrain for that coordinate using the tile_at method
			atlas_tile = tile_at(world.x, world.y)
			
			# Use set_cell to set the image based on that value
			set_cell(world, SOURCE_ID, atlas_tile)
	
	# Store flag that this position is loaded
	_loaded[c] = true


## Helper method to unload chunks at position c
func _unload_chunk(c: Vector2i) -> void:
	# Like load_chunk but simpler
	var world: Vector2i
	
	# Loop over x/y for CHUNK
	for x in range(CHUNK):
		for y in range(CHUNK):
			# For each, get the world i coordinates
			world = Vector2i(c.x * CHUNK + x, c.y * CHUNK + y)
			
			# Call erase_cell at that location
			erase_cell(world)
	
	# Erase the record that we've loaded this position
	_loaded.erase(c)


## Classify noise into the different terrain types based on cutoff thresholds
func _classify(v: float) -> Terrain:
	if v < water_cutoff:
		return Terrain.WATER
	elif v < dirt_cutoff:
		return Terrain.DIRT
	elif v < grass_cutoff:
		return Terrain.GRASS
	else:
		return Terrain.ROCK


## Helper method to fetch atlas coordinates at specified location
func tile_at(x: int, y: int) -> Vector2i:
	# Unpacking notes:
	# i = y * PERIOD + x          # cell -> index
	# x = i % PERIOD              # index -> cell
	# y = i / PERIOD              # integer division
	
	# posmod for the positive variant of the modulus operator
	var packed: int = _tiles[posmod(y, PERIOD) * PERIOD + posmod(x, PERIOD)]
	# Unpack index values for the atlas
	@warning_ignore("integer_division")
	return Vector2i(packed % VARIANTS, packed / VARIANTS)


## Helper method like tile_at but only carring about type of terrain
func terrain_at(x: int, y: int) -> int:
	# Get y-value of Atlas only (type of terrain)
	@warning_ignore("integer_division")
	return _tiles[posmod(y, PERIOD) * PERIOD + posmod(x, PERIOD)] / VARIANTS
