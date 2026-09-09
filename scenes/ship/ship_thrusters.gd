@tool
class_name ShipThrusters
extends Node2D
## Draws the ship's propulsion FX from a data-driven `PropulsionConfig`: a main
## engine plume and control thrusters (RCS) for rotation and the Full Stop
## retro-burn. Each frame it reads the parent `Ship`'s thruster state and draws
## only the nozzles that are firing; it never drives the flight logic. Kept
## behind the hull in the scene tree so plumes render under the ship.

## The propulsion layout to draw. When unset, a default layout is used so the
## ship still shows thrusters; assign a saved `.tres` to customize per ship.
@export var config: PropulsionConfig:
	set(value):
		config = value
		queue_redraw()

## Command below which a thruster is treated as off (avoids flickering dust).
const DEADZONE := 0.02

## Fallback layout, built lazily when no `config` resource is assigned.
var _default_config: PropulsionConfig
## Elapsed time, used only to redraw the flicker each frame.
var _time: float = 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var cfg := _active_config()
	if cfg == null:
		return

	if Engine.is_editor_hint():
		for nozzle in cfg.nozzles:
			if nozzle != null:
				draw_circle(nozzle.position, 2.0, Color(1.0, 1.0, 1.0, 0.25))
		return

	var ship := get_parent() as Ship
	if ship == null:
		return

	var accel := ship.rcs_translation
	for nozzle in cfg.nozzles:
		if nozzle == null:
			continue
		var dir := nozzle.direction.normalized()
		var force := -dir # reaction on the hull when the nozzle expels along dir
		var intensity := 0.0
		if (nozzle.channels & ThrusterNozzle.Channel.MAIN) != 0:
			intensity += ship.main_throttle
		if (nozzle.channels & ThrusterNozzle.Channel.ROTATION) != 0 and absf(ship.rcs_torque) > DEADZONE:
			var torque_z := nozzle.position.x * force.y - nozzle.position.y * force.x
			if signf(torque_z) == signf(ship.rcs_torque):
				intensity += absf(ship.rcs_torque)
		if (nozzle.channels & ThrusterNozzle.Channel.TRANSLATION) != 0 and accel.length() > DEADZONE:
			intensity += maxf(0.0, force.dot(accel))
		_draw_flame(nozzle.position, dir, clampf(intensity, 0.0, 1.0),
			nozzle.width, nozzle.length, nozzle.inner_color, nozzle.outer_color)


## The assigned config, or a lazily-built default when none is set.
func _active_config() -> PropulsionConfig:
	if config != null:
		return config
	if _default_config == null:
		_default_config = PropulsionConfig.create_default()
	return _default_config


## Draws a two-layer flame from `origin` extending along `dir`, scaled and
## jittered by `intensity`. Does nothing when the thruster is effectively off.
func _draw_flame(origin: Vector2, dir: Vector2, intensity: float,
		width: float, length: float, inner: Color, outer: Color) -> void:
	if intensity <= DEADZONE:
		return
	var flicker := 0.78 + 0.22 * randf()
	var span := length * intensity * flicker
	var perp := Vector2(-dir.y, dir.x)
	var half := perp * width * 0.5
	var tip := origin + dir * span
	draw_colored_polygon(PackedVector2Array([origin + half, origin - half, tip]), outer)
	var half_inner := perp * width * 0.28
	var tip_inner := origin + dir * span * 0.6
	draw_colored_polygon(
		PackedVector2Array([origin + half_inner, origin - half_inner, tip_inner]), inner)
