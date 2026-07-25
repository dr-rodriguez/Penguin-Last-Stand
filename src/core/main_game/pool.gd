class_name Pool
extends Node

## What scene to pool
@export var scene: PackedScene
## Initial size of pool
@export var initial_size: int = 64
## Whether the pool can grow in size or not
@export var can_grow: bool = true

## Pool of idle nodes ready to hand out
var _free: Array[Node] = []

func _ready() -> void:
	# Instantiate the pool with deactivated scenes
	for i in initial_size:
		_add_new()

## Instantiate a new scene, but deactivated
func _add_new() -> Node:
	var n := scene.instantiate()
	add_child(n)
	_deactivate(n)
	return n

## Hand out a ready node (or null if empty and not growing)
func acquire() -> Node:
	# Check if pool empty
	if _free.is_empty():
		if can_grow:
			_add_new()
		else:
			return null
	
	# Get a scene and activate it
	var n: Node = _free.pop_back()
	n.set_process(true)
	n.set_physics_process(true)
	n.visible = true
	if n is CollisionObject2D:
		n.set_deferred("monitoring", true)   # re-enable overlap checks
	return n

## Take a node back into the pool (call this instead of queue_free)
func release(n: Node) -> void:
	_deactivate(n)

## Core logic of storing back in pool
func _deactivate(n: Node) -> void:
	# Deactivate the specified scene
	n.set_process(false)
	n.set_physics_process(false)
	n.visible = false
	if n is CollisionObject2D:
		n.set_deferred("monitoring", false)  # stop overlap checks while idle
	
	# Store back in pool for reuse
	if n not in _free:
		_free.append(n)
