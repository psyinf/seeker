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

## Fill color of the outer hull silhouette drawn beneath the cell tiles.
@export var hull_color: Color = Color("2a3242"):
	set(value):
		hull_color = value
		queue_redraw()

var _fallback: ShipDesign


func _draw() -> void:
	var d := design
	if d == null:
		if _fallback == null:
			_fallback = ShipDesign.create_default()
		d = _fallback
	_draw_hull(d)
	for segment in d.segments:
		if segment != null:
			_draw_segment(segment, d)


## Fill and outline the design's convex hull as the ship's outer shape, beneath
## the cell tiles so modules read as mounted on the hull.
# TODO: place thrusters from this hull — main engines on the aftmost (max +Y)
# hull edge, steering thrusters at the outer corners, each facing outward along
# the hull normal, instead of relying on hand-authored THRUSTER cells.
func _draw_hull(d: ShipDesign) -> void:
	var hull := d.convex_hull()
	if hull.size() < 3:
		return
	draw_colored_polygon(hull, hull_color)
	draw_polyline(hull + PackedVector2Array([hull[0]]), outline_color, outline_width, true)


func _draw_segment(segment: ShipSegment, d: ShipDesign) -> void:
	var cell_size := d.cell_size
	var center := Vector2(segment.cell) * cell_size
	var half := cell_size * 0.5 - cell_inset
	var color := _color_for(segment.kind)
	var rect := Rect2(center - Vector2(half, half), Vector2(half, half) * 2.0)
	draw_rect(rect, color, true)
	# Fixed cells (core, initial drive) get a distinct locked outline.
	var edge := Color("c9a227") if segment.fixed else outline_color
	draw_rect(rect, edge, false, outline_width)
	match segment.kind:
		ShipSegment.Kind.THRUSTER:
			# Only the aft-most drive in a run vents; forward cells are extensions.
			if d.is_drive_extension(segment):
				_draw_drive_extension(center, segment.facing_dir(), half)
			else:
				_draw_nozzle(center, segment.facing_dir(), half)
		ShipSegment.Kind.WEAPON:
			_draw_barrel(center, segment.facing_dir(), half)
		ShipSegment.Kind.REACTOR:
			draw_circle(center, half * 0.5, Color("8dff9b"))
		ShipSegment.Kind.CORE:
			draw_circle(center, half * 0.45, Color("cdefff"))
		_:
			pass


## A drive extension: a spine stripe along the thrust axis (no nozzle) marking a
## cell that feeds the nozzle ahead of it.
func _draw_drive_extension(center: Vector2, dir: Vector2, half: float) -> void:
	draw_line(center - dir * half * 0.6, center + dir * half * 0.6, Color("ff9d3c"), half * 0.3)


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
		ShipSegment.Kind.DRONE_BAY:
			return Color("b06fd0")
		ShipSegment.Kind.CARGO_HOLD:
			return Color("a8863f")
		ShipSegment.Kind.SHIELD:
			return Color("4f8fd9")
		ShipSegment.Kind.SENSOR:
			return Color("4fd9c4")
		ShipSegment.Kind.FUEL_TANK:
			return Color("c96b3c")
		ShipSegment.Kind.RADIATOR:
			return Color("9aa4b0")
		ShipSegment.Kind.ARMOR:
			return Color("5a6270")
		_:
			return Color("7b8798")
