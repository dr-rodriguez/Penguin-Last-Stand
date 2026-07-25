extends TileMapLayer

# This script generates the map procedurally. 
# We use PERIOD as the size of each tile and repeat it as the player moves through the world.

## Player character scene
@export var _player: CharacterBody2D
## Water threshold
@export var water_threshold: float = 0.2
## Dirt threshold
@export var dirt_threshold: float = 0.4
## Grass threshold
@export var grass_threshold: float = 0.85

## Tiles per wrap
const PERIOD: int = 128
## Tiles per chunk edge
const CHUNK: int = 16
## Number of chunks around the player
const LOAD_RADIUS: int = 2
## Number of variant versions of each terrain
const VARIANTS: int = 3
## Source ID for TileSet
const SOURCE_ID: int = 0

## Terrain possibilities
enum Terrain {GRASS, DIRT, ROCK, WATER}
# These are effectively ints, so Terrain.GRASS == 0

## Tile storage (noise values for the tile)
var _tiles: PackedByteArray
# Unpacking notes for _tiles and similar arrays:
# i = y * PERIOD + x          # cell -> index
# x = i % PERIOD              # index -> cell
# y = i / PERIOD              # integer division

## Dictionary of loaded chunks (keys are Vector2i coords, values are true/false)
var _loaded: Dictionary = {}

# Noise cutoff values for terrain
var water_cutoff: float
var dirt_cutoff: float
var grass_cutoff: float
# rock_cutoff not used- anything higher than grass is rock

func _ready() -> void:
	# Generate tiles from noise
	_bake_noise()
	
	# Find a suitable spawn location that avoids water
	var cell: Vector2i = _find_spawn()
	while cell == Vector2i.ZERO:
		cell = _find_spawn()
	_player.global_position = to_global(map_to_local(cell))
	
	# Load chunks around player, unload those far away
	_refresh(_player_chunk())
	
	print("[MapArea] Generated map tiles")


func _process(_delta: float) -> void:
	# Load chunks around player, unload those far away
	_refresh(_player_chunk())


## Bake the noise into the _tiles array
func _bake_noise() -> void:
	## Temporary float field with noise values
	var field := PackedFloat32Array()
	field.resize(PERIOD * PERIOD)

	# Set noise parameters
	## Noise generator
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = randi()
	noise.frequency = 0.02 # lower is smoother
	noise.fractal_octaves = 3  # from docs: number of noise layers that are sampled to get the final value

	# Set up tile storage
	_tiles.resize(PERIOD * PERIOD)

	# Generate over all x/y values within the PERIOD
	for y: int in PERIOD:
		for x: int in PERIOD:
			# x/y scaled by PERIOD (so 0.0 to 1.0)
			var fx := float(x) / PERIOD
			var fy := float(y) / PERIOD

			# Make noise symmetric
			# Bilinear blend of four offset copies
			var noise_value := (
				noise.get_noise_2d(x, y)                      * (1.0 - fx) * (1.0 - fy)
				+ noise.get_noise_2d(x - PERIOD, y)           * fx         * (1.0 - fy)
				+ noise.get_noise_2d(x, y - PERIOD)           * (1.0 - fx) * fy
				+ noise.get_noise_2d(x - PERIOD, y - PERIOD)  * fx         * fy
				)

			field[y * PERIOD + x] = noise_value
	
	# Determine exact cutoff values from percentages instead of scaling
	var sorted := field.duplicate()
	sorted.sort()
	var n := sorted.size()
	water_cutoff = sorted[int(n * water_threshold)]
	dirt_cutoff = sorted[int(n * dirt_threshold)]
	grass_cutoff = sorted[int(n * grass_threshold)]
	
	# Classify into byte array (indicating terrain type)
	for i: int in field.size():
		var terrain := _classify(field[i])
		var variant := randi_range(0, VARIANTS - 1)
		_tiles[i] = terrain * VARIANTS + variant


## Load/unload chunks as needed based on player position
func _refresh(center: Vector2i) -> void:
	# Check for loaded chunks that are too far away- unload them
	for c: Vector2i in _loaded.keys():
		if absi(c.x - center.x) > LOAD_RADIUS or absi(c.y - center.y) > LOAD_RADIUS:
			_unload_chunk(c)
	
	# Load chunks close to the player
	for dy: int in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for dx: int in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var c: Vector2i = center + Vector2i(dx, dy)
			if not _loaded.has(c):
				_load_chunk(c)


## Determine which chunk the player is in
func _player_chunk() -> Vector2i:
	var cell := local_to_map(to_local(_player.global_position))
	return Vector2i(
		floori(cell.x / float(CHUNK)), 
		floori(cell.y / float(CHUNK))
	)
	

## Load chunks at position c
func _load_chunk(c: Vector2i) -> void:
	# Loop over x/y for CHUNK
	for y: int in CHUNK:
		for x: int in CHUNK:
			# For each, get the world i coordinates
			var world := Vector2i(c.x * CHUNK + x, c.y * CHUNK + y)

			# Get the terrain for that coordinate using the tile_at method
			var atlas_tile := tile_at(world.x, world.y)

			# Use set_cell to set the image based on that value
			set_cell(world, SOURCE_ID, atlas_tile)
	
	# Store flag that this position is loaded
	_loaded[c] = true


## Unload chunks at position c
func _unload_chunk(c: Vector2i) -> void:
	# Like load_chunk but simpler
	# Loop over x/y for CHUNK
	for y: int in CHUNK:
		for x: int in CHUNK:
			# For each, get the world i coordinates
			var world := Vector2i(c.x * CHUNK + x, c.y * CHUNK + y)

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


## Fetch atlas coordinates at specified location
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


## Method like tile_at but only caring about type of terrain
func terrain_at(x: int, y: int) -> int:
	# Get y-value of Atlas only (type of terrain)
	@warning_ignore("integer_division")
	return _tiles[posmod(y, PERIOD) * PERIOD + posmod(x, PERIOD)] / VARIANTS


## Find player spawn location (avoid water spawn)
func _find_spawn() -> Vector2i:
	var candidate: Vector2i
	## Minimum number of open spaces required
	const MIN_OPEN: int = 400
	
	# Loop over 64 attempts to find a valid one
	for attempt: int in 64:
		candidate = Vector2i(randi() % PERIOD, randi() % PERIOD)
		if terrain_at(candidate.x, candidate.y) == Terrain.WATER:
			continue
		if _open_region_size(candidate, MIN_OPEN) >= MIN_OPEN:
			return candidate
	return Vector2i.ZERO


## BFS method to return number of valid tiles
func _open_region_size(c: Vector2i, threshold: int) -> int:
	# Initial check to ensure we don't start in water
	if terrain_at(c.x, c.y) == Terrain.WATER:
		return 0
	
	## Dictionary of visited locations
	var visited: Dictionary = {}
	visited[c] = true
	## Queue of what to crawl through, starting with initial location
	var queue: Array[Vector2i] = [c]
	## Number of valid tiles found
	var count: int = 0
	
	# Core of Breadth-First Search algorithm
	var head: int = 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		
		count += 1
		# Reached threshold counts, we have enough spaces for the player
		if count >= threshold:
			return count
		
		# Loop over direction vectors and test if water
		for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			# Wrap from 0..PERIOD-1
			var n := Vector2i(posmod(cell.x + offset.x, PERIOD), posmod(cell.y + offset.y, PERIOD))
			
			# If already visited this position, skip
			if visited.has(n):
				continue
			
			# If a water tile, skip
			if terrain_at(n.x, n.y) == Terrain.WATER:
				continue
			
			# Mark position as visited and add to queue
			visited[n] = true
			queue.append(n)
	
	return count
