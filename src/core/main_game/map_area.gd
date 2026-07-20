extends TileMapLayer

# This script generates the map procedurally. 
# We use PERIOD as the size of each tile and repeat it as the player moves through the world.

## Tiles per wrap
const PERIOD: int = 16
## Tiles per chunk edge
const CHUNK: int = 8
## Number of chunks around the player
const LOAD_RADIUS: int = 2

## Player character scene
@export var _player: CharacterBody2D

## Tile storage (noise values for the tile)
var _tiles: PackedByteArray

## Dictionary of loaded chunks (keys are Vector2i coords, values are true/false)
var _loaded: Dictionary = {}

## Noise generator
var noise := FastNoiseLite.new()

# Dimensions of each generated chunk
var width: int = 64
var height: int = 64

# Noise thresholds
var water_cutoff: float = 0.3
var dirt_cutoff: float = 0.4
var grass_cutoff: float = 0.7
# rock_cutoff not used- anything higher than grass is rock


func _ready() -> void:
	# Set noise parameters
	noise.set_noise_type(FastNoiseLite.TYPE_SIMPLEX_SMOOTH)
	noise.set_seed(randi())
	noise.set_frequency(0.02) # lower is smoother
	noise.set_fractal_octaves(3)  # from docs: number of noise layers that are sampled to get the final value
	
	# Set up tile storage
	_tiles.resize(PERIOD * PERIOD)
	
	# Get the position of the player local to the TileMap and scale it to CHUNK
	var center := local_to_map(to_local(_player.global_position)) / CHUNK
	_refresh(center)
	
	# Generate chunk (old code)
	generate_chunk()
	
	print("[MapArea] Generated map tiles")

## Load/unload chunks as needed based on player position
func _refresh(center: Vector2i) -> void:
	pass


## Helper method to load chunks at position c
func _load_chunk(c: Vector2i) -> void:
	# Loop over x/y for CHUNK
	# For each, get the world i coordinates
	# Get the terrain for that coordinate using the tile_at method
	# Use set_cell to set the image based on that value
	pass


## Helper method to unload chunks at position c
func _unload_chunk(c: Vector2i) -> void:
	# Like load_chunk but simpler
	# Loop over x/y for CHUNK
	# For each, get the world i coordinates
	# Call erase_cell at that location
	pass


## Generate the noise to be stored for later recall
func _generate_noise() -> void:
	# TODO: Review this, not sure if it is correct
	
	# Loop over x/y for the PERIOD
	for x in range(PERIOD):
		for y in range(PERIOD):
			# Generate noise at that location
			var a = noise.get_noise_2d(x, y)
			# Scale noise to be 0 to 1
			a = (a + 1.0) / 2.0
			# Store it in tiles
			_tiles[y*PERIOD + x] = a

## Generate a chunk based on noise values (old)
func generate_chunk() -> void:
	# TODO: replace with logic that generates full tileable map
	
	var pos = Vector2i.ZERO
	
	# Get properties of the TileSet
	var tilepos: Vector2i
	var atlaspos: Vector2i
	var span: int = 3  # how many variants of each terrain
	
	# Loop over the width/height to generate all the tiles
	for x in range(PERIOD):
		for y in range(PERIOD):
			# Location of the tile to generate
			tilepos = Vector2i(pos.x - (width/2.) + x, pos.y - (height/2.) + y)
			
			# Generate noise values, these are -1 to 1
			var a = noise.get_noise_2d(tilepos.x, tilepos.y)
			# Scale noise to be 0 to 1
			a = (a + 1.0) / 2.0
			
			# Get the terrain using the cutoff thresholds
			var atlas_y: int = _classify(a)
			# Randomize which tile of that terraint to use
			var atlas_x: int = randi_range(0, span - 1)
			
			atlaspos = Vector2i(atlas_x, atlas_y)
			
			#print("[MapArea] " + str(tilepos) + " " + str(atlaspos) + " " + str(atlas_y) + " " + str(a))
			
			set_cell(tilepos, 0, atlaspos)


## Classify noise into the different terrain types based on cutoff thresholds
func _classify(v: float) -> int:
	var atlasi: int = 2  # default is rock
	if v < water_cutoff:
		atlasi = 3  # grass altasi
	elif v < dirt_cutoff:
		atlasi = 1  # dirt atlasi
	elif v < grass_cutoff:
		atlasi = 0  # grass atlasi
	
	return atlasi


## Helper method to fetch tile at specified position
func tile_at(x: int, y: int) -> int:
	# posmod for the positive variant of the modulus operator
	return _tiles[posmod(y, PERIOD) * PERIOD + posmod(x, PERIOD)]
