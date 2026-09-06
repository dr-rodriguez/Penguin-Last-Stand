class_name PowerUp
extends Resource

## How the amount is folded into the stat
enum Mode {
	## stat += amount
	ADD,
	## stat *= amount
	MULTIPLY,
}

## Unique id, and the key power-up levels are counted under
@export var id: StringName
## Texture to use for powerup
@export var texture: Texture
## Title to use for card
@export var title: String
## Description to use for card
@export var description: String

#region Effect
## Base stat on Stats this power-up changes; its "current_" twin moves with it
@export var stat: StringName
## Whether amount is added to the stat or multiplied into it
@export var mode: Mode = Mode.ADD
## How much to add/multiply per level
@export var amount: float = 0.0
## Times this power-up can be taken; 0 means no cap
@export var max_level: int = 0
#endregion
