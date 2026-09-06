class_name EnemyDef
extends Resource

# Enemy definition

@export var texture: Texture
@export var health: float = 5.0
@export var speed: float = 10.0
@export var damage: float = 1.0
## Unique id, and the key kills are counted under
@export var id: StringName
## Plural form used in the kill readouts
@export var plural: String
## Points one kill is worth in the final score
@export var score_value: int = 1
## Relative chance of spawning against the other enemy types
@export var spawn_weight: float = 1.0
