@tool
class_name ShipDesign
extends Resource
## A segmented ship as grid-placed cells. Owns the list of `ShipSegment`s and the
## `cell_size` that maps grid coordinates to pixels; it is the save/load unit for
## a ship layout (author as a `.tres`, or build one in code). Rendering and, later,
## the flight model and the in-game editor all operate on this one resource.

## Pixels per grid cell (both axes).
@export var cell_size: float = 22.0:
	set(value):
		cell_size = value
		emit_changed()

## The cells that make up the ship.
@export var segments: Array[ShipSegment] = []:
	set(value):
		segments = value
		emit_changed()


## The segment occupying `cell`, or null if that cell is empty.
func get_segment_at(cell: Vector2i) -> ShipSegment:
	for segment in segments:
		if segment != null and segment.cell == cell:
			return segment
	return null


## Inclusive grid bounds covering every cell; a zero-size rect when empty.
func bounds() -> Rect2i:
	if segments.is_empty():
		return Rect2i()
	var rect := Rect2i(segments[0].cell, Vector2i.ZERO)
	for segment in segments:
		if segment != null:
			rect = rect.expand(segment.cell)
	return rect


## A stock starter ship: a nose gun, a cockpit core, a reactor with hull wings,
## and a three-nozzle tail. Used when no design is assigned so there is always
## something to draw. Forward is -Y, so smaller Y is toward the nose.
static func create_default() -> ShipDesign:
	var design := ShipDesign.new()
	design.segments = [
		_seg(ShipSegment.Kind.WEAPON, Vector2i(0, -2), ShipSegment.Facing.UP),
		_seg(ShipSegment.Kind.CORE, Vector2i(0, -1)),
		_seg(ShipSegment.Kind.HULL, Vector2i(-1, 0)),
		_seg(ShipSegment.Kind.REACTOR, Vector2i(0, 0)),
		_seg(ShipSegment.Kind.HULL, Vector2i(1, 0)),
		_seg(ShipSegment.Kind.THRUSTER, Vector2i(-1, 1), ShipSegment.Facing.DOWN),
		_seg(ShipSegment.Kind.THRUSTER, Vector2i(0, 1), ShipSegment.Facing.DOWN),
		_seg(ShipSegment.Kind.THRUSTER, Vector2i(1, 1), ShipSegment.Facing.DOWN),
	]
	return design


static func _seg(kind: ShipSegment.Kind, cell: Vector2i, facing := ShipSegment.Facing.UP) -> ShipSegment:
	var segment := ShipSegment.new()
	segment.kind = kind
	segment.cell = cell
	segment.facing = facing
	return segment
