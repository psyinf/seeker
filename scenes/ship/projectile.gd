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

## World-space velocity set by the firing turret, in pixels/second.
var _velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0


## Sets the bolt's world velocity; call right after spawning.
func launch(velocity: Vector2) -> void:
	_velocity = velocity


func _physics_process(delta: float) -> void:
	position += _velocity * delta
	_age += delta
	if _age >= lifetime:
		queue_free()


func _draw() -> void:
	draw_line(Vector2(0.0, length * 0.5), Vector2(0.0, -length * 0.5), color, 2.0, true)
	draw_circle(Vector2(0.0, -length * 0.5), 2.0, color)
