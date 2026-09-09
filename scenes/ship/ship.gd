@tool
class_name Ship
extends Node2D
## Top-down player ship. Forward is -Y, so the nose points "up" on screen —
## matching the visual top of a top-down view and Godot's convention that a
## later `look_at`/velocity can align the nose with a heading. The visual hull
## lives in the child `ShipHull` scene; this script owns only flight logic.

## Requested when the player double-clicks; the mode opens a context menu.
signal context_menu_requested

@export_group("Flight")
## Ship mass. Force is divided by mass for both thrust and turning, so heavier
## ships need proportionally more thrust/torque for the same responsiveness —
## the hook for larger-mass ships that must carry beefier engines.
@export_range(0.1, 100.0, 0.1) var mass: float = 1.0
## Engine thrust force. Linear acceleration = thrust_force / mass (px/s²).
@export var thrust_force: float = 900.0
## Speed cap, in pixels/second.
@export var max_speed: float = 600.0
## Seconds LMB must be held before it counts as thrust; a shorter press is a
## click, which only turns the ship without accelerating.
@export var hold_thrust_delay: float = 0.15

@export_group("Turning")
## Steering torque. Angular acceleration = turn_torque / mass (rad/s²). The ship
## builds and sheds angular velocity instead of snapping to the aim.
@export var turn_torque: float = 8.0
## Maximum angular speed, in radians/second.
@export_range(0.1, 20.0, 0.1) var max_turn_speed: float = 2.5
## Angular velocity damping per second (bleeds off residual spin).
@export_range(0.0, 5.0, 0.05) var angular_damping: float = 0.5

## Current world-space velocity, in pixels/second. Read by the flight indicators.
var velocity: Vector2 = Vector2.ZERO
## Unit vector the nose points toward (the desired heading). Read by the indicators.
var aim_direction: Vector2 = Vector2.UP
## Current angular velocity, in radians/second (turning momentum).
var angular_velocity: float = 0.0

## Max gap between two clicks to count as a double-click, in milliseconds.
const DOUBLE_CLICK_WINDOW_MS := 250

## True while the left mouse button is held (rotate; thrust past hold_thrust_delay).
var _lmb_held: bool = false
## Seconds the current LMB hold has lasted.
var _hold_time: float = 0.0
## A single click's turn is deferred by the double-click window so the first
## click of a double-click never rotates the ship.
var _pending_turn: bool = false
var _pending_turn_dir: Vector2 = Vector2.UP
var _pending_turn_msec: int = 0
## Timestamp of the last quick-click release, to pair up double-clicks.
var _last_click_msec: int = -100000
## True while executing a Full Stop order (retro-burn until at rest).
var _braking: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if event.pressed:
		_lmb_held = true
		_hold_time = 0.0
		return
	_lmb_held = false
	if _hold_time >= hold_thrust_delay:
		_last_click_msec = -100000 # a hold is never part of a double-click
		return
	var now := Time.get_ticks_msec()
	if now - _last_click_msec <= DOUBLE_CLICK_WINDOW_MS:
		_pending_turn = false # this is a double-click — cancel the first click's turn
		_last_click_msec = -100000
		context_menu_requested.emit()
	else:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 0.001:
			_pending_turn_dir = to_mouse.normalized()
			_pending_turn = true
			_pending_turn_msec = now
		_last_click_msec = now


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# A single click only turns — deferred past the double-click window so the
	# first click of a double-click (menu) never rotates the ship.
	if _pending_turn and Time.get_ticks_msec() - _pending_turn_msec > DOUBLE_CLICK_WINDOW_MS:
		aim_direction = _pending_turn_dir
		_pending_turn = false
	# Hold LMB: turn toward the cursor and thrust (past a short delay). Space is
	# frictionless, so momentum never bleeds off by itself.
	if _lmb_held:
		_hold_time += delta
		if _hold_time >= hold_thrust_delay:
			var to_mouse := get_global_mouse_position() - global_position
			if to_mouse.length() > 0.001:
				aim_direction = to_mouse.normalized()
			_braking = false # manual input cancels a Full Stop
	_apply_turning(delta)
	if _lmb_held and _hold_time >= hold_thrust_delay:
		var heading := Vector2.UP.rotated(rotation)
		velocity += heading * (thrust_force / mass) * delta
	elif _braking:
		_apply_braking(delta)
	velocity = velocity.limit_length(max_speed)
	position += velocity * delta


## Begins a Full Stop: a retro-burn that kills velocity using the ship's thrust.
func full_stop() -> void:
	_braking = true


## Retro-burn opposite the current velocity, capped so it settles exactly at rest.
func _apply_braking(delta: float) -> void:
	var speed := velocity.length()
	var delta_v := (thrust_force / mass) * delta
	if speed <= delta_v:
		velocity = Vector2.ZERO
		_braking = false
	else:
		velocity -= velocity / speed * delta_v


## Steers the ship's rotation toward `aim_direction` with angular momentum:
## builds up angular velocity under a torque/mass limit and brakes early so it
## arrives on the target heading without oscillating.
func _apply_turning(delta: float) -> void:
	var angular_accel := turn_torque / mass
	var target_rotation := aim_direction.angle() + PI / 2.0 # nose (-Y) faces the aim
	var error := wrapf(target_rotation - rotation, -PI, PI)
	# Fastest spin we can still decelerate from before reaching the target.
	var brake_speed := sqrt(2.0 * angular_accel * absf(error))
	var desired_velocity := signf(error) * minf(max_turn_speed, brake_speed)
	var max_step := angular_accel * delta
	angular_velocity += clampf(desired_velocity - angular_velocity, -max_step, max_step)
	if angular_damping > 0.0:
		angular_velocity *= maxf(0.0, 1.0 - angular_damping * delta)
	rotation += angular_velocity * delta
