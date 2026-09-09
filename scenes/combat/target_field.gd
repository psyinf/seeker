class_name TargetField
extends Node2D
## Scatters practice targets randomly across an annulus around its origin at
## startup. It owns spawning only; each target handles its own hit detection and
## destruction. Drop this into a combat scene and point it at the target scene.

## Emitted whenever one of its targets is destroyed (relayed for score/FX).
signal target_destroyed(at: Vector2)

## The target scene to instance.
@export var target_scene: PackedScene
## How many targets to scatter on ready.
@export_range(0, 200, 1) var count: int = 12
## Inner radius of the spawn annulus, in pixels (keeps targets off the ship).
@export var min_radius: float = 300.0
## Outer radius of the spawn annulus, in pixels.
@export var max_radius: float = 1600.0
## Seed for reproducible layouts; 0 randomizes each run.
@export var spawn_seed: int = 0


func _ready() -> void:
	if target_scene == null:
		return
	var rng := RandomNumberGenerator.new()
	if spawn_seed != 0:
		rng.seed = spawn_seed
	else:
		rng.randomize()
	for _i in count:
		_spawn_one(rng)


func _spawn_one(rng: RandomNumberGenerator) -> void:
	var target := target_scene.instantiate() as Node2D
	if target == null:
		return
	var angle := rng.randf() * TAU
	# Square-root keeps the scatter uniform across the annulus area.
	var t := rng.randf()
	var r := sqrt(lerpf(min_radius * min_radius, max_radius * max_radius, t))
	target.position = Vector2.RIGHT.rotated(angle) * r
	if target.has_signal("destroyed"):
		target.destroyed.connect(_on_target_destroyed)
	add_child(target)


func _on_target_destroyed(at: Vector2) -> void:
	target_destroyed.emit(at)
