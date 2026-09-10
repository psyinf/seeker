@tool
class_name SegmentedHull
extends Node2D
## Draws a `ShipDesign` as grid cells: a colored square per segment plus a
## kind-specific accent (thruster nozzle, weapon barrel, reactor/core glow). It
## is the visual counterpart to `ShipHull` for segmented ships — pure rendering,
## no flight logic. Forward is -Y, matching the ship. Redraws live in the editor
## (@tool) and when its design changes.

## The ship layout to draw. When unset, a stock design is drawn so there is
## always something on screen.
@export var design: ShipDesign:
	set(value):
		if design != null and design.changed.is_connected(queue_redraw):
			design.changed.disconnect(queue_redraw)
		design = value
		if design != null and not design.changed.is_connected(queue_redraw):
			design.changed.connect(queue_redraw)
		queue_redraw()

## Gap inset around each cell, in pixels, so segments read as distinct tiles.
@export var cell_inset: float = 2.0:
	set(value):
		cell_inset = value
		queue_redraw()

## Outline color drawn around every cell.
@export var outline_color: Color = Color("1d2330"):
	set(value):
		outline_color = value
		queue_redraw()

## Outline thickness, in pixels.
@export var outline_width: float = 2.0:
	set(value):
		outline_width = value
		queue_redraw()

var _fallback: ShipDesign


func _draw() -> void:
	var d := design
	if d == null:
		if _fallback == null:
			_fallback = ShipDesign.create_default()
		d = _fallback
	for segment in d.segments:
		if segment != null:
			_draw_segment(segment, d.cell_size)


func _draw_segment(segment: ShipSegment, cell_size: float) -> void:
	var center := Vector2(segment.cell) * cell_size
	var half := cell_size * 0.5 - cell_inset
	var color := _color_for(segment.kind)
	var rect := Rect2(center - Vector2(half, half), Vector2(half, half) * 2.0)
	draw_rect(rect, color, true)
	draw_rect(rect, outline_color, false, outline_width)
	match segment.kind:
		ShipSegment.Kind.THRUSTER:
			_draw_nozzle(center, segment.facing_dir(), half)
		ShipSegment.Kind.WEAPON:
			_draw_barrel(center, segment.facing_dir(), half)
		ShipSegment.Kind.REACTOR:
			draw_circle(center, half * 0.5, Color("8dff9b"))
		ShipSegment.Kind.CORE:
			draw_circle(center, half * 0.45, Color("cdefff"))
		_:
			pass


## A flared nozzle sticking out of the cell's exhaust (facing) side.
func _draw_nozzle(center: Vector2, dir: Vector2, half: float) -> void:
	var side := Vector2(-dir.y, dir.x)
	var base := center + dir * half
	var points := PackedVector2Array([
		base + side * half * 0.6,
		base - side * half * 0.6,
		base + dir * half * 0.7,
	])
	draw_colored_polygon(points, Color("ff9d3c"))


## A stubby barrel poking out of the cell's facing side.
func _draw_barrel(center: Vector2, dir: Vector2, half: float) -> void:
	draw_line(center, center + dir * (half + half * 0.7), Color("d94f4f"), half * 0.45)


func _color_for(kind: ShipSegment.Kind) -> Color:
	match kind:
		ShipSegment.Kind.CORE:
			return Color("5fd0ff")
		ShipSegment.Kind.THRUSTER:
			return Color("3a4150")
		ShipSegment.Kind.WEAPON:
			return Color("6b7280")
		ShipSegment.Kind.REACTOR:
			return Color("2f7d55")
		_:
			return Color("7b8798")
