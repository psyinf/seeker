@tool
class_name ModuleStats
extends Resource
## Base stat block for one module kind. These are the unmodified baseline values;
## upgrades and modifiers layer on top later. Look up a kind's baseline with
## `ModuleStats.base_stats(kind)`, which returns a fresh copy so callers can
## mutate it (apply modifiers) without touching the shared table. Ship-wide totals
## are computed by `ShipDesign` from these.

## Structural mass; drives the ship's acceleration and turn rate.
@export var mass: float = 1.0
## Energy per second consumed while the module is active.
@export var power_draw: float = 0.0
## Energy per second produced (reactors and the like; 0 for consumers).
@export var power_gen: float = 0.0
## Internal armor: hit points before the module is destroyed.
@export var armor_hp: float = 10.0
## Minerals required to build the module.
@export var build_cost: float = 0.0
## Crew needed to operate. Always 0 for now (reserved for a later crew system).
@export var crew: int = 0
## Heat generated per second. Always 0 for now (reserved for a later heat system).
@export var heat: float = 0.0
## Cargo storage the module adds (cargo holds only).
@export var cargo_capacity: float = 0.0
## Survey/scan range the module adds (sensors only).
@export var scan_range: float = 0.0
## Fuel storage the module adds (fuel tanks only).
@export var fuel_capacity: float = 0.0
## Energy storage the module adds (capacitors only); extends energy-weapon
## capacity now, and is the reserve a future energy system draws from.
@export var energy_capacity: float = 0.0


## Baseline stats for a `ShipSegment.Kind`, as a fresh resource. Callers own the
## copy and may layer upgrades/modifiers on it. Unknown kinds get plain defaults.
static func base_stats(kind: ShipSegment.Kind) -> ModuleStats:
	var s := ModuleStats.new()
	match kind:
		ShipSegment.Kind.CORE:
			s.mass = 2.0
			s.power_draw = 1.0
			s.armor_hp = 30.0
			s.build_cost = 20.0
		ShipSegment.Kind.HULL:
			s.mass = 1.0
			s.armor_hp = 15.0
			s.build_cost = 5.0
		ShipSegment.Kind.THRUSTER:
			s.mass = 1.5
			s.power_draw = 2.0
			s.armor_hp = 8.0
			s.build_cost = 10.0
		ShipSegment.Kind.WEAPON:
			s.mass = 1.5
			s.power_draw = 3.0
			s.armor_hp = 8.0
			s.build_cost = 15.0
		ShipSegment.Kind.REACTOR:
			s.mass = 2.0
			s.power_gen = 20.0
			s.armor_hp = 10.0
			s.build_cost = 25.0
		ShipSegment.Kind.DRONE_BAY:
			s.mass = 2.0
			s.power_draw = 2.0
			s.armor_hp = 12.0
			s.build_cost = 20.0
		ShipSegment.Kind.CARGO_HOLD:
			s.mass = 1.0
			s.armor_hp = 8.0
			s.build_cost = 8.0
			s.cargo_capacity = 50.0
		ShipSegment.Kind.SHIELD:
			s.mass = 1.5
			s.power_draw = 4.0
			s.armor_hp = 8.0
			s.build_cost = 20.0
		ShipSegment.Kind.SENSOR:
			s.mass = 1.0
			s.power_draw = 2.0
			s.armor_hp = 6.0
			s.build_cost = 15.0
			s.scan_range = 200.0
		ShipSegment.Kind.FUEL_TANK:
			s.mass = 1.5
			s.armor_hp = 6.0
			s.build_cost = 8.0
			s.fuel_capacity = 40.0
		ShipSegment.Kind.RADIATOR:
			s.mass = 1.0
			s.armor_hp = 6.0
			s.build_cost = 8.0
		ShipSegment.Kind.ARMOR:
			s.mass = 2.0
			s.armor_hp = 40.0
			s.build_cost = 12.0
		ShipSegment.Kind.CAPACITOR:
			s.mass = 1.0
			s.power_draw = 1.0
			s.armor_hp = 8.0
			s.build_cost = 14.0
			s.energy_capacity = 2.0
		_:
			pass
	return s
