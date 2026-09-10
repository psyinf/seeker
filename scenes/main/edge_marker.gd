class_name EdgeMarker
extends Node2D
## A single directional marker drawn at the screen border to point at something
## off-screen. It is the reusable visual primitive of the edge-marker system:
## style it with `color`/`marker_size`, pick a `shape`, and rotate it so its tip
## points outward (it draws pointing along local +X). More shapes get added to
## `Shape` as new marker kinds appear — callers stay unchanged.

## The silhouette this marker draws. Triangle is the only one for now; add new
## entries here (and a branch in `_draw`) for future marker kinds.
enum Shape { TRIANGLE }

## Which silhouette to draw.
@export var shape: Shape = Shape.TRIANGLE:
	set(value):
		shape = value
		queue_redraw()

## Fill color of the marker.
@export var color: Color = Color("ff6b6b"):
	set(value):
		color = value
		queue_redraw()

## Half-extent of the marker in pixels (tip distance from its origin).
@export var marker_size: float = 14.0:
	set(value):
		marker_size = value
		queue_redraw()


func _draw() -> void:
	match shape:
		Shape.TRIANGLE:
			_draw_triangle()


func _draw_triangle() -> void:
	var s := marker_size
	# Apex points along +X so rotating the node aims the marker outward.
	var points := PackedVector2Array([
		Vector2(s, 0.0),
		Vector2(-s * 0.6, -s * 0.7),
		Vector2(-s * 0.6, s * 0.7),
	])
	draw_colored_polygon(points, color)
