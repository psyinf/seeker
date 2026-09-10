@tool
class_name Ship
extends Node2D
## Top-down player ship. Forward is -Y, so the nose points "up" on screen —
## matching the visual top of a top-down view and Godot's convention that a
## later `look_at`/velocity can align the nose with a heading. The visual hull
## lives in the child `ShipHull` scene; this script owns only flight logic.

## Requested when the player double-clicks; the mode opens a context menu.
signal context_menu_requested

## Relayed from the ship's turrets when they fire; the mode adds the bolt to the
## world so it keeps its own momentum instead of moving with the ship.
signal projectile_fired(projectile: Node2D)

## Turret spawned at each WEAPON cell when a design is applied.
const TURRET_SCENE := preload("res://scenes/ship/ship_turret.tscn")

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
## A quick click whose direction is within this angle of the current heading
## fires a short forward thrust tap instead of a (redundant) turn, so you can
## nudge the ship up to speed without waiting out the double-click window.
@export_range(0.0, 90.0, 1.0) var tap_thrust_tolerance_deg: float = 20.0
## How long that forward thrust tap burns, in seconds.
@export var tap_thrust_duration: float = 0.15
## Force of the retro (backward) thrusters, fired by clicking near the retrograde
## marker to bleed off speed without turning. Lower than thrust_force — retros
## are less effective than the main engine.
@export var retro_thrust_force: float = 400.0
## Minimum burn a single tap on the retrograde marker fires, in seconds (holding
## keeps burning until release or full stop).
@export var retro_thrust_duration: float = 0.15
## When true, the main engine only fires once the nose is aligned with the aim
## direction: the ship turns to face the target first, then accelerates. When
## false, thrust is applied along the current heading even while still turning.
@export var require_alignment: bool = true
## Max heading error, in degrees, that still counts as aligned enough to thrust
## (only used when `require_alignment` is on).
@export_range(0.0, 90.0, 1.0) var alignment_tolerance_deg: float = 5.0

@export_group("Turning")
## Steering torque. Angular acceleration = turn_torque / mass (rad/s²). The ship
## builds and sheds angular velocity instead of snapping to the aim.
@export var turn_torque: float = 8.0
## Maximum angular speed, in radians/second.
@export_range(0.1, 20.0, 0.1) var max_turn_speed: float = 2.5
## Angular velocity damping per second (bleeds off residual spin).
@export_range(0.0, 5.0, 0.05) var angular_damping: float = 0.5

@export_group("Recoil")
## How much weapon recoil the RCS can null per second, in px/s of delta-v. Recoil
## arriving faster than this (heavy or many weapons firing at once) overwhelms the
## thrusters and the leftover kick shoves the ship.
@export var rcs_recoil_compensation: float = 150.0

## Current world-space velocity, in pixels/second. Read by the flight indicators.
var velocity: Vector2 = Vector2.ZERO
## Unit vector the nose points toward (the desired heading). Read by the indicators.
var aim_direction: Vector2 = Vector2.UP
## Current angular velocity, in radians/second (turning momentum).
var angular_velocity: float = 0.0

## Main engine throttle this frame, 0..1 (forward thrust). Read by the thruster FX.
var main_throttle: float = 0.0
## Signed RCS rotation command this frame, -1..1 (which way the control thrusters
## torque the hull). Read by the thruster FX.
var rcs_torque: float = 0.0
## RCS translation command this frame in local space (the retro-burn during a
## Full Stop), each axis -1..1. Read by the thruster FX.
var rcs_translation: Vector2 = Vector2.ZERO

## Max gap between two clicks to count as a double-click, in milliseconds.
const DOUBLE_CLICK_WINDOW_MS := 250

## Below this heading error (radians) the ship is treated as aligned (~0.6°).
const SETTLE_ANGLE := 0.01
## Below this angular speed (rad/s) a nearly-aligned ship snaps to rest.
const SETTLE_SPEED := 0.05

## True while the left mouse button is held (rotate; thrust past hold_thrust_delay).
var _lmb_held: bool = false
## Seconds the current LMB hold has lasted.
var _hold_time: float = 0.0
## Remaining burn time on a click-to-nudge forward thrust tap (see tap_thrust_*).
var _tap_thrust_time: float = 0.0
## Remaining minimum burn from a tap on the retrograde marker (see retro_*).
var _retro_thrust_time: float = 0.0
## True while the retrograde marker is held: keep firing the retro thrusters.
var _retro_engaged: bool = false
## A single click's turn is deferred by the double-click window so the first
## click of a double-click never rotates the ship.
var _pending_turn: bool = false
var _pending_turn_dir: Vector2 = Vector2.UP
var _pending_turn_msec: int = 0
## Timestamp of the last quick-click release, to pair up double-clicks.
var _last_click_msec: int = -100000
## True while executing a Full Stop order (retro-burn until at rest).
var _braking: bool = false

## The turrets mounted on this ship; RMB fires them all.
var _turrets: Array[ShipTurret] = []
## Optional fire-control computer; relays the selected module and platform data.
var _fire_control: FireControl = null
## Recoil delta-v the RCS still owes to cancel (accumulated shot kicks). Grows
## when weapons fire faster than the RCS can compensate; the leftover pushes the ship.
var _recoil_debt: Vector2 = Vector2.ZERO


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for child in get_children():
		if child is ShipTurret:
			_turrets.append(child)
			child.projectile_fired.connect(_on_turret_projectile_fired)
			child.recoil_applied.connect(apply_recoil)
		elif child is FireControl:
			_fire_control = child
	if _fire_control != null:
		_fire_control.setup(self, _turrets)


## Render this ship using `design` (its SegmentedHull visual) and rebuild its
## propulsion FX from the design (main plumes off the drives, hull RCS mounts).
## Called when a test flight starts from the ship editor.
func apply_design(design: ShipDesign) -> void:
	var hull := get_node_or_null("SegmentedHull") as SegmentedHull
	if hull != null:
		hull.design = design
	var thrusters := get_node_or_null("ShipThrusters") as ShipThrusters
	if thrusters != null:
		thrusters.config = _build_propulsion(design)
	_build_turrets(design)


## Replace the ship's turrets with one per WEAPON cell in the design, so every
## weapon the player places actually fires. Each turret sits on its cell, starts
## aimed along the barrel's facing, and is wired into fire control.
func _build_turrets(design: ShipDesign) -> void:
	for turret in _turrets:
		if turret.projectile_fired.is_connected(_on_turret_projectile_fired):
			turret.projectile_fired.disconnect(_on_turret_projectile_fired)
		turret.queue_free()
	_turrets.clear()
	var cs := design.cell_size
	for segment in design.segments:
		if segment == null or segment.kind != ShipSegment.Kind.WEAPON:
			continue
		var turret := TURRET_SCENE.instantiate() as ShipTurret
		if turret == null:
			continue
		turret.weapon = WeaponConfig.from_name(segment.weapon)
		turret.position = Vector2(segment.cell) * cs
		turret.rotation = segment.facing_dir().angle() + PI / 2.0
		add_child(turret)
		turret.projectile_fired.connect(_on_turret_projectile_fired)
		turret.recoil_applied.connect(apply_recoil)
		_turrets.append(turret)
	if _fire_control != null:
		_fire_control.setup(self, _turrets)


## Assemble the propulsion layout from a design: a main plume off every venting
## drive nozzle (skipping extensions) plus the hull's fixed RCS mounts.
func _build_propulsion(design: ShipDesign) -> PropulsionConfig:
	var nozzles: Array[ThrusterNozzle] = []
	var cs := design.cell_size
	for segment in design.segments:
		if segment == null or segment.kind != ShipSegment.Kind.THRUSTER:
			continue
		if design.is_drive_extension(segment):
			continue
		var dir := segment.facing_dir()
		var n := ThrusterNozzle.new()
		n.position = Vector2(segment.cell) * cs + dir * cs * 0.5
		n.direction = dir
		n.length = cs * 1.6
		n.width = cs * 0.8
		n.inner_color = Color(1.0, 0.96, 0.72)
		n.outer_color = Color(1.0, 0.52, 0.15, 0.85)
		n.channels = ThrusterNozzle.Channel.MAIN
		nozzles.append(n)
	for mount in design.rcs_mounts:
		if mount != null:
			nozzles.append(mount)
	var cfg := PropulsionConfig.new()
	cfg.nozzles = nozzles
	return cfg


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if not (event is InputEventMouseButton):
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		_set_firing(event.pressed)
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		_lmb_held = true
		_hold_time = 0.0
		_tap_thrust_time = 0.0 # a fresh press supersedes any lingering tap burn
		return
	_lmb_held = false
	if _hold_time >= hold_thrust_delay:
		_last_click_msec = -100000 # a hold is never part of a double-click
		return
	var now := Time.get_ticks_msec()
	if now - _last_click_msec <= DOUBLE_CLICK_WINDOW_MS:
		_pending_turn = false # this is a double-click — cancel the first click's turn
		_tap_thrust_time = 0.0 # and cancel a nudge the first click may have started
		_last_click_msec = -100000
		context_menu_requested.emit()
	else:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 0.001:
			var dir := to_mouse.normalized()
			var heading := Vector2.UP.rotated(rotation)
			# Already pointing (roughly) where you clicked? Nudge forward now instead
			# of deferring a turn that wouldn't swing the nose anyway.
			if absf(heading.angle_to(dir)) <= deg_to_rad(tap_thrust_tolerance_deg):
				_tap_thrust_time = tap_thrust_duration
				_braking = false # manual input cancels a Full Stop
			else:
				_pending_turn_dir = dir
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
	main_throttle = 0.0
	rcs_translation = Vector2.ZERO
	if _retro_engaged or _retro_thrust_time > 0.0:
		# Backward thrusters from the retrograde marker: shed speed, never turn.
		if not _retro_burn(delta):
			_retro_engaged = false
			_retro_thrust_time = 0.0
		elif _retro_thrust_time > 0.0:
			_retro_thrust_time -= delta
	elif _lmb_held and _hold_time >= hold_thrust_delay:
		var heading := Vector2.UP.rotated(rotation)
		if not require_alignment or absf(heading.angle_to(aim_direction)) <= deg_to_rad(alignment_tolerance_deg):
			velocity += heading * (thrust_force / mass) * delta
			main_throttle = 1.0
	elif _tap_thrust_time > 0.0:
		# Immediate forward nudge from a click made along the current heading.
		velocity += Vector2.UP.rotated(rotation) * (thrust_force / mass) * delta
		main_throttle = 1.0
		_tap_thrust_time -= delta
	elif _braking:
		_apply_braking(delta)
	_compensate_recoil(delta)
	velocity = velocity.limit_length(max_speed)
	position += velocity * delta
	# Turrets inherit the hull's momentum so bolts fly Newtonian.
	for turret in _turrets:
		turret.base_velocity = velocity


## Begins a Full Stop: a retro-burn that kills velocity using the ship's thrust.
func full_stop() -> void:
	_braking = true


## Fires (true) or stops (false) the backward retro thrusters. Driven by the
## flight indicators when the player uses the retrograde marker, so it decelerates
## along the current velocity without ever turning the hull. A tap fires at least
## retro_thrust_duration; holding keeps burning until release.
func set_retro_burn(active: bool) -> void:
	_retro_engaged = active
	if active:
		_retro_thrust_time = maxf(_retro_thrust_time, retro_thrust_duration)
		_braking = false # manual input cancels a Full Stop


## Selects the active fire-control module (FireControl.Mode int) from the HUD.
func set_fire_control_mode(mode: int) -> void:
	if _fire_control != null:
		_fire_control.mode = mode


## Toggles align-gated thrust (point-then-burn) from the HUD.
func set_require_alignment(enabled: bool) -> void:
	require_alignment = enabled


## Toggles the fire command on every mounted turret (each gates its own rate).
func _set_firing(active: bool) -> void:
	for turret in _turrets:
		turret.firing = active


## Relays a turret's bolt so the mode can place it in the world.
func _on_turret_projectile_fired(projectile: Node2D) -> void:
	projectile_fired.emit(projectile)


## Applies a shot's recoil impulse: the kick lands on velocity immediately, and
## the same delta-v is logged as debt the RCS then works to cancel.
func apply_recoil(impulse: Vector2) -> void:
	var delta_v := impulse / maxf(mass, 0.001)
	velocity += delta_v
	_recoil_debt += delta_v


## RCS fights the accumulated recoil: each frame it cancels up to
## rcs_recoil_compensation of the outstanding debt, restoring that much velocity.
## While debt remains it fires the translation thrusters (FX). Debt that keeps
## growing (recoil outpacing the RCS) leaves a residual kick on the ship.
func _compensate_recoil(delta: float) -> void:
	var debt := _recoil_debt.length()
	if debt <= 0.0001:
		return
	var applied := minf(rcs_recoil_compensation * delta, debt)
	var correction := -_recoil_debt / debt * applied
	velocity += correction
	_recoil_debt += correction
	rcs_translation = correction.normalized().rotated(-rotation)


## Retro-burn opposite the current velocity, capped so it settles exactly at rest.
func _apply_braking(delta: float) -> void:
	var speed := velocity.length()
	var delta_v := (thrust_force / mass) * delta
	# Control thrusters fire opposite the motion, so expel gas along +velocity.
	if speed > 0.001:
		rcs_translation = (-velocity / speed).rotated(-rotation)
	if speed <= delta_v:
		velocity = Vector2.ZERO
		_braking = false
	else:
		velocity -= velocity / speed * delta_v


## Applies one frame of weaker retro thrust opposite the current velocity, no
## turning — the backward thrusters fired by using the retrograde marker. Returns
## false once the ship has come to rest.
func _retro_burn(delta: float) -> bool:
	var speed := velocity.length()
	if speed <= 0.001:
		return false
	var delta_v := (retro_thrust_force / mass) * delta
	rcs_translation = (-velocity / speed).rotated(-rotation)
	if speed <= delta_v:
		velocity = Vector2.ZERO
		return false
	velocity -= velocity / speed * delta_v
	return true


## Steers the ship's rotation toward `aim_direction` with angular momentum:
## builds up angular velocity under a torque/mass limit and brakes early so it
## arrives on the target heading without oscillating.
func _apply_turning(delta: float) -> void:
	var angular_accel := turn_torque / mass
	var target_rotation := aim_direction.angle() + PI / 2.0 # nose (-Y) faces the aim
	var error := wrapf(target_rotation - rotation, -PI, PI)
	# Once aligned and nearly stopped, snap and go idle so the control thrusters
	# don't chatter with endless micro-corrections.
	if absf(error) < SETTLE_ANGLE and absf(angular_velocity) < SETTLE_SPEED:
		rotation = target_rotation
		angular_velocity = 0.0
		rcs_torque = 0.0
		return
	# Fastest spin we can still decelerate from before reaching the target.
	var brake_speed := sqrt(2.0 * angular_accel * absf(error))
	var desired_velocity := signf(error) * minf(max_turn_speed, brake_speed)
	var max_step := angular_accel * delta
	var step := clampf(desired_velocity - angular_velocity, -max_step, max_step)
	angular_velocity += step
	# Control thrusters only fire while changing angular velocity, not while coasting.
	rcs_torque = step / max_step if max_step > 0.0 else 0.0
	if angular_damping > 0.0:
		angular_velocity *= maxf(0.0, 1.0 - angular_damping * delta)
	rotation += angular_velocity * delta
