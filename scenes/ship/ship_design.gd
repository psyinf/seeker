@tool
class_name ShipDesign
extends Resource
## A segmented ship as grid-placed cells. Owns the list of `ShipSegment`s and the
## `cell_size` that maps grid coordinates to pixels; it is the save/load unit for
## a ship layout (author as a `.tres`, or build one in code). Rendering and, later,
## the flight model and the in-game editor all operate on this one resource.

## Class/type name of the hull (e.g. "Nomad" for the exploration/recon starter).
@export var ship_class: String = "":
	set(value):
		ship_class = value
		emit_changed()

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


## Place `kind` at `cell`, replacing any segment already there. Returns the
## segment. Used by the editor; emits `changed` so views refresh.
func place(kind: ShipSegment.Kind, cell: Vector2i, facing := ShipSegment.Facing.UP) -> ShipSegment:
	var segment := get_segment_at(cell)
	if segment == null:
		segment = ShipSegment.new()
		segment.cell = cell
		segments.append(segment)
	segment.kind = kind
	segment.facing = facing
	emit_changed()
	return segment


## Remove the segment at `cell`, if any. Returns true when one was removed.
func remove_at(cell: Vector2i) -> bool:
	for i in segments.size():
		if segments[i] != null and segments[i].cell == cell:
			segments.remove_at(i)
			emit_changed()
			return true
	return false


## Inclusive grid bounds covering every cell; a zero-size rect when empty.
func bounds() -> Rect2i:
	if segments.is_empty():
		return Rect2i()
	var rect := Rect2i(segments[0].cell, Vector2i.ZERO)
	for segment in segments:
		if segment != null:
			rect = rect.expand(segment.cell)
	return rect


## The ship's outer silhouette: the convex hull of every cell's corners, in local
## pixel space. Fewer than 3 points (empty/degenerate design) yields an empty array.
func convex_hull() -> PackedVector2Array:
	var points := PackedVector2Array()
	var half := cell_size * 0.5
	for segment in segments:
		if segment == null:
			continue
		var center := Vector2(segment.cell) * cell_size
		points.append(center + Vector2(-half, -half))
		points.append(center + Vector2(half, -half))
		points.append(center + Vector2(half, half))
		points.append(center + Vector2(-half, half))
	if points.size() < 3:
		return PackedVector2Array()
	return Geometry2D.convex_hull(points)


## The command cell that must survive, or null if the design has none.
func core_segment() -> ShipSegment:
	for segment in segments:
		if segment != null and segment.kind == ShipSegment.Kind.CORE:
			return segment
	return null


## Sum of every module's mass; drives acceleration and turn rate.
func total_mass() -> float:
	var total := 0.0
	for segment in segments:
		if segment != null:
			total += segment.stats().mass
	return total


## Energy per second produced across all modules.
func power_generation_total() -> float:
	var total := 0.0
	for segment in segments:
		if segment != null:
			total += segment.stats().power_gen
	return total


## Energy per second consumed across all modules.
func power_draw_total() -> float:
	var total := 0.0
	for segment in segments:
		if segment != null:
			total += segment.stats().power_draw
	return total


## Net power: generation minus draw. Negative means the ship is over budget.
func net_power() -> float:
	return power_generation_total() - power_draw_total()


## Sum of every module's internal armor; the ship's total structural HP.
func total_hp() -> float:
	var total := 0.0
	for segment in segments:
		if segment != null:
			total += segment.stats().armor_hp
	return total


## Total cargo storage from all cargo holds.
func cargo_capacity_total() -> float:
	var total := 0.0
	for segment in segments:
		if segment != null:
			total += segment.stats().cargo_capacity
	return total


## Combined survey/scan range from all sensors.
func scan_range_total() -> float:
	var total := 0.0
	for segment in segments:
		if segment != null:
			total += segment.stats().scan_range
	return total


## Total minerals to build every module in the design.
func build_cost_total() -> float:
	var total := 0.0
	for segment in segments:
		if segment != null:
			total += segment.stats().build_cost
	return total


## True when a drive cell is an *extension* rather than a nozzle: another drive
## sits on its exhaust (facing) side, so this cell stacks in front of one that
## actually vents. The aft-most drive in a run is the nozzle; cells forward of it
## are extensions. The type is derived from placement, never chosen directly.
func is_drive_extension(segment: ShipSegment) -> bool:
	if segment == null or segment.kind != ShipSegment.Kind.THRUSTER:
		return false
	var ahead := get_segment_at(segment.cell + Vector2i(segment.facing_dir()))
	return ahead != null and ahead.kind == ShipSegment.Kind.THRUSTER


## A stock starter ship: a nose gun, a cockpit core, a reactor with hull wings,
## and a three-nozzle tail. Used when no design is assigned so there is always
## something to draw. Forward is -Y, so smaller Y is toward the nose. The core and
## the center drive are `fixed` — the player builds around them.
static func create_default() -> ShipDesign:
	var design := ShipDesign.new()
	design.ship_class = "Nomad"
	design.segments = [
		_seg(ShipSegment.Kind.WEAPON, Vector2i(0, -2), ShipSegment.Facing.UP),
		_seg(ShipSegment.Kind.CORE, Vector2i(0, -1), ShipSegment.Facing.UP, true),
		_seg(ShipSegment.Kind.HULL, Vector2i(-1, 0)),
		_seg(ShipSegment.Kind.REACTOR, Vector2i(0, 0)),
		_seg(ShipSegment.Kind.HULL, Vector2i(1, 0)),
		_seg(ShipSegment.Kind.THRUSTER, Vector2i(-1, 1), ShipSegment.Facing.DOWN),
		_seg(ShipSegment.Kind.THRUSTER, Vector2i(0, 1), ShipSegment.Facing.DOWN, true),
		_seg(ShipSegment.Kind.THRUSTER, Vector2i(1, 1), ShipSegment.Facing.DOWN),
	]
	return design


static func _seg(kind: ShipSegment.Kind, cell: Vector2i, facing := ShipSegment.Facing.UP, fixed := false) -> ShipSegment:
	var segment := ShipSegment.new()
	segment.kind = kind
	segment.cell = cell
	segment.facing = facing
	segment.fixed = fixed
	return segment
