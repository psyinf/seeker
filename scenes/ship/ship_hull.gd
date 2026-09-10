@tool
class_name ShipHull
extends Node2D
## The player ship's visual: an elongated diamond (a kite) whose longer tip is
## the nose. Forward is -Y, so the nose points "up" in local space and rotates
## with the parent `Ship`. Fully tunable from the inspector and redraws live
## (@tool). Kept separate from the flight logic so drawing and physics stay
## decoupled.

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
