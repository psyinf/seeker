# Seeker — Ship Module Design Questionnaire

> Filled in during the module-design session (2026-09-10). Answers here feed the
> ship-design data model ([ship_segment.gd](../scenes/ship/ship_segment.gd),
> [ship_design.gd](../scenes/ship/ship_design.gd),
> [module_stats.gd](../scenes/ship/module_stats.gd)) and the module catalog in
> [game-design.md](game-design.md). Base numbers are placeholders to be tuned.

## 1. Module concept

A ship is a grid of cells; each cell is a **module** of one `Kind`. Structural
cells (hull, armor) hold the ship together; functional cells (thrusters, weapons,
reactors, …) give it capabilities. Two cells are special:

- **Core** — the command cell. It is *always* present and is the thing that must
  survive; losing it ends the ship.
- **Armor** — a special "border" cell. Interior cells are regular modules; the
  outside of the ship can be armor, forming the tough shell/shape.

## 2. Shared stat block (every module)

Every module carries the same baseline stat block. `crew` and `heat` are modelled
now but held at **0** until their systems exist.

| Stat | Meaning |
|------|---------|
| **mass** | Structural mass; drives acceleration and turn rate. |
| **power_draw** | Energy/sec consumed while active. |
| **power_gen** | Energy/sec produced (0 for consumers). |
| **armor_hp** | Internal armor: HP before the module is destroyed. |
| **build_cost** | Minerals to construct. |
| **crew** | Crew to operate. **Always 0 for now.** |
| **heat** | Heat/sec produced. **Always 0 for now.** |

Module-specific extras layer on top: `cargo_capacity` (cargo holds),
`scan_range` (sensors), `fuel_capacity` (fuel tanks).

## 3. Module catalog (base values)

Placeholder baselines from [module_stats.gd](../scenes/ship/module_stats.gd).
Empty cells are 0.

| Kind | mass | power_draw | power_gen | armor_hp | build_cost | extra |
|------|-----:|-----------:|----------:|---------:|-----------:|-------|
| CORE | 2.0 | 1.0 | | 30 | 20 | must survive |
| HULL | 1.0 | | | 15 | 5 | structural filler |
| THRUSTER | 1.5 | 2.0 | | 8 | 10 | |
| WEAPON | 1.5 | 3.0 | | 8 | 15 | |
| REACTOR | 2.0 | | 20.0 | 10 | 25 | power source |
| DRONE_BAY | 2.0 | 2.0 | | 12 | 20 | |
| CARGO_HOLD | 1.0 | | | 8 | 8 | cargo_capacity 50 |
| SHIELD | 1.5 | 4.0 | | 8 | 20 | |
| SENSOR | 1.0 | 2.0 | | 6 | 15 | scan_range 200 |
| FUEL_TANK | 1.5 | | | 6 | 8 | fuel_capacity 40 |
| RADIATOR | 1.0 | | | 6 | 8 | heat sink (heat 0 for now) |
| ARMOR | 2.0 | | | 40 | 12 | border/shell cell |

## 4. Where stats live

- **Static base table keyed by `Kind`** — `ModuleStats.base_stats(kind)` returns a
  fresh copy of the baseline. This is the single source of truth for base numbers.
- **Modifiers/upgrades layer on later** — because `base_stats` returns a *copy*,
  future upgrades can adjust a module's values without mutating the shared table.
  The modifier data model is a later step; base values are tabled now.

## 5. Ship-wide aggregates

`ShipDesign` computes totals from its modules:

- `total_mass()`
- `power_generation_total()`, `power_draw_total()`, `net_power()` (gen − draw;
  negative = over budget)
- `total_hp()` (sum of `armor_hp`)
- `cargo_capacity_total()`
- `scan_range_total()` (sum of sensor ranges)
- `build_cost_total()`
- `core_segment()` (the must-survive cell, or null)

## 6. Open questions

- **Base tuning:** all numbers above are placeholders; balance once flight/combat
  consume them.
- **Modifier model:** how upgrades attach to a module (flat/percentage, stacking).
- **Scan range aggregation:** currently summed; may switch to max, or diminishing
  returns.
- **Armor as shape:** rules for what counts as a valid "border" and whether armor
  is auto-placed on the outer edge.
- **Crew & heat systems:** both stats exist but are inert; design their loops
  before switching them on.
- **Fuel capacity:** stored per fuel tank but not yet an aggregate/consumer.
