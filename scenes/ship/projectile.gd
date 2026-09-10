class_name Projectile
extends Node2D
## A simple turret bolt: travels in a straight line at a fixed world velocity and
## despawns after its lifetime. Spawned into the world (not parented to the ship)
## so it keeps its own momentum once fired.

## Seconds before the bolt despawns.
@export var lifetime: float = 2.0
## Length of the drawn tracer, in pixels (forward is local -Y).
@export var length: float = 10.0
## Bolt color.
@export var color: Color = Color("ffd36b")

## Damage dealt to a target on impact; set by the firing turret from its weapon.
var damage: float = 1.0
## World-space velocity set by the firing turret, in pixels/second.
var _velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0

## Physics layer targets sit on; the bolt sweeps against it each frame.
const TARGET_LAYER := 4


## Sets the bolt's world velocity; call right after spawning.
func launch(velocity: Vector2) -> void:
	_velocity = velocity


func _physics_process(delta: float) -> void:
	_steer(delta) # straight by default; guided rounds override this to home
	var step := _velocity * delta
	# Sweep the whole step so a fast bolt can't tunnel past a small target.
	var target := _swept_target(global_position, global_position + step)
	if target != null:
		if target.has_method("hit"):
			target.hit(damage)
		queue_free()
		return
	position += step
	_age += delta
	if _age >= lifetime:
		queue_free()


## Per-frame steering hook. The base bolt flies straight (no-op); guided rounds
## override this to bend `_velocity` toward a target.
func _steer(_delta: float) -> void:
	pass


## Ray-casts the bolt's path this frame against the targets layer; returns the
## first target hit (an Area2D) or null. Bodies are ignored so nothing blocks flight.
func _swept_target(from: Vector2, to: Vector2) -> Node:
	if from.is_equal_approx(to):
		return null
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = TARGET_LAYER
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return null
	return hit.collider


func _draw() -> void:
	draw_line(Vector2(0.0, length * 0.5), Vector2(0.0, -length * 0.5), color, 2.0, true)
	draw_circle(Vector2(0.0, -length * 0.5), 2.0, color)
