@tool
class_name PropulsionConfig
extends Resource
## A ship's complete propulsion layout: the set of thruster nozzles that drive
## its FX. A `Resource`, so a loadout can be authored in the inspector and saved
## or loaded as a `.tres` later (ship save/load, swappable engine loadouts).

## All thruster mounts on the ship.
@export var nozzles: Array[ThrusterNozzle] = []


## Builds the default single-engine + RCS layout matching the stock hull. Used as
## a fallback when no config resource is assigned.
static func create_default() -> PropulsionConfig:
	var engine_inner := Color(1.0, 0.96, 0.72)
	var engine_outer := Color(1.0, 0.52, 0.15, 0.85)
	var config := PropulsionConfig.new()
	config.nozzles = [
		# Main engine: one plume off the tail, pointing straight back (+Y).
		_make(Vector2(0.0, 24.0), Vector2(0.0, 1.0), 52.0, 26.0,
			engine_inner, engine_outer, ThrusterNozzle.Channel.MAIN),
		# Four lateral RCS nozzles form two rotation couples and brake lateral drift.
		_make(Vector2(-4.5, -24.2), Vector2(-1.0, 0.0)),  # nose-left
		_make(Vector2(4.5, -24.2), Vector2(1.0, 0.0)),    # nose-right
		_make(Vector2(-12.6, 9.6), Vector2(-1.0, 0.0)),   # tail-left
		_make(Vector2(12.6, 9.6), Vector2(1.0, 0.0)),     # tail-right
		# Nose-forward RCS brakes forward motion (torque is zero on the centerline).
		_make(Vector2(0.0, -37.4), Vector2(0.0, -1.0), 16.0, 6.0,
			Color(0.85, 0.96, 1.0), Color(0.42, 0.72, 1.0, 0.7),
			ThrusterNozzle.Channel.TRANSLATION),
	]
	return config


## Helper to build one nozzle with RCS defaults; override any field per call.
static func _make(position: Vector2, direction: Vector2, length: float = 16.0,
		width: float = 6.0, inner_color: Color = Color(0.85, 0.96, 1.0),
		outer_color: Color = Color(0.42, 0.72, 1.0, 0.7),
		channels: int = ThrusterNozzle.Channel.ROTATION | ThrusterNozzle.Channel.TRANSLATION
) -> ThrusterNozzle:
	var nozzle := ThrusterNozzle.new()
	nozzle.position = position
	nozzle.direction = direction
	nozzle.length = length
	nozzle.width = width
	nozzle.inner_color = inner_color
	nozzle.outer_color = outer_color
	nozzle.channels = channels
	return nozzle
