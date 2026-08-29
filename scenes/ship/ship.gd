@tool
class_name Ship
extends Node2D
## Top-down player ship, drawn as an elongated diamond (a kite): the longer tip
## is the nose. Forward is -Y, so the nose points "up" on screen — matching the
## visual top of a top-down view and Godot's convention that a later
## `look_at`/velocity can align the nose with a heading.
##
## The hull is fully tunable from the inspector and redraws live (@tool).

## Distance from the origin to the nose tip, in pixels. Longer than the tail so
## the front is unambiguous.
@export var front_length: float = 44.0:
	set(value):
		front_length = value
		queue_redraw()

## Distance from the origin to the tail tip, in pixels.
@export var tail_length: float = 24.0:
	set(value):
		tail_length = value
		queue_redraw()

## Half the hull width at its widest (the left/right points), in pixels.
@export var half_width: float = 18.0:
	set(value):
		half_width = value
		queue_redraw()

## Hull fill color.
@export var hull_color: Color = Color("5fd0ff"):
	set(value):
		hull_color = value
		queue_redraw()

## Hull outline color.
@export var outline_color: Color = Color("1d2330"):
	set(value):
		outline_color = value
		queue_redraw()

## Hull outline thickness, in pixels.
@export var outline_width: float = 2.0:
	set(value):
		outline_width = value
		queue_redraw()

@export_group("Flight")
## Thrust acceleration while the thrust input is held, in pixels/second².
@export var thrust_accel: float = 900.0
## Speed cap, in pixels/second.
@export var max_speed: float = 600.0
## Linear velocity damping per second (0 = pure Newtonian drift, higher = tighter).
@export_range(0.0, 5.0, 0.05) var damping: float = 0.6

## Current world-space velocity, in pixels/second. Read by the flight indicators.
var velocity: Vector2 = Vector2.ZERO
## Unit vector the nose points toward (the desired heading). Read by the indicators.
var aim_direction: Vector2 = Vector2.UP


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 0.001:
			aim_direction = to_mouse.normalized()
	rotation = aim_direction.angle() + PI / 2.0 # nose (-Y) faces the aim
	if Input.is_action_pressed("thrust"):
		velocity += aim_direction * thrust_accel * delta
	if damping > 0.0:
		velocity *= maxf(0.0, 1.0 - damping * delta)
	velocity = velocity.limit_length(max_speed)
	position += velocity * delta


func _draw() -> void:
	var hull := _hull_points()
	draw_colored_polygon(hull, hull_color)
	# Repeat the first point so the outline closes cleanly.
	draw_polyline(hull + PackedVector2Array([hull[0]]), outline_color, outline_width, true)


## The four hull vertices, clockwise from the nose. Forward is -Y.
func _hull_points() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -front_length), # nose (front, longer)
		Vector2(half_width, 0.0),    # right
		Vector2(0.0, tail_length),   # tail
		Vector2(-half_width, 0.0),   # left
	])
