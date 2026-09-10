@tool
class_name ShipSegment
extends Resource
## One cell of a segmented ship on the build grid. Pure data: a `kind`, its grid
## `cell` (integer coordinates, +X right, +Y aft since the ship's forward is -Y),
## and a `facing` for directional parts (thruster exhaust / weapon barrel). The
## renderer and, later, the flight model read this; the segment draws nothing
## itself. New part kinds get an entry in `Kind` (and the systems that care).

## The part a cell represents. CORE/HULL are structural; the rest are functional.
enum Kind { CORE, HULL, THRUSTER, WEAPON, REACTOR }

## Which way a directional part points. UP is -Y — the ship's forward.
enum Facing { UP, RIGHT, DOWN, LEFT }

## What this cell is.
@export var kind: Kind = Kind.HULL:
	set(value):
		kind = value
		emit_changed()

## Integer grid coordinate of the cell (+X right, +Y aft).
@export var cell: Vector2i = Vector2i.ZERO:
	set(value):
		cell = value
		emit_changed()

## Orientation for directional kinds (thruster exhaust side, weapon barrel side).
@export var facing: Facing = Facing.UP:
	set(value):
		facing = value
		emit_changed()


## Unit vector the `facing` points along, in local space (UP = -Y = forward).
func facing_dir() -> Vector2:
	match facing:
		Facing.RIGHT:
			return Vector2.RIGHT
		Facing.DOWN:
			return Vector2.DOWN
		Facing.LEFT:
			return Vector2.LEFT
		_:
			return Vector2.UP
