class_name Missile
extends Projectile
## A guided bolt: homes on the nearest target, steering its velocity at a limited
## turn rate while holding a constant cruise speed. Reuses `Projectile`'s swept
## collision, damage and despawn — only the per-frame steering differs.

## Cruise speed held while homing, px/s. Set by the turret from the weapon config.
var cruise_speed: float = 420.0
## Maximum heading change while homing, radians/second.
var turn_rate: float = 4.0

## Physics layer targets sit on (matches Projectile.TARGET_LAYER).
const SEEK_LAYER := 4
## How far the seeker looks for a target, in pixels.
@export var seek_radius: float = 1600.0

var _target: Node2D = null


## Bends the velocity toward the nearest target, capped by `turn_rate`, keeping a
## constant cruise speed. Falls straight when nothing is in range.
func _steer(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_target = _nearest_target()
	if _target == null:
		return
	var to_target := _target.global_position - global_position
	if to_target.length() < 0.001:
		return
	var current := _velocity.angle()
	var error := wrapf(to_target.angle() - current, -PI, PI)
	var step := clampf(error, -turn_rate * delta, turn_rate * delta)
	var speed := cruise_speed if cruise_speed > 0.0 else _velocity.length()
	_velocity = Vector2.RIGHT.rotated(current + step) * speed
	rotation = _velocity.angle() + PI / 2.0 # nose (-Y) faces travel


## Nearest target Area2D on the targets layer within `seek_radius`, or null.
func _nearest_target() -> Node2D:
	var space := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = seek_radius
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, global_position)
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = SEEK_LAYER
	var best: Node2D = null
	var best_dist := INF
	for hit in space.intersect_shape(params, 32):
		var collider := hit.collider as Node2D
		if collider == null:
			continue
		var dist := collider.global_position.distance_squared_to(global_position)
		if dist < best_dist:
			best_dist = dist
			best = collider
	return best
