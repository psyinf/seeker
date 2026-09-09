@tool
class_name FireControl
extends Node2D
## Ship fire-control computer — a module with no visual hardware of its own. It
## reads the ship's velocity and the mounted turrets, then either predicts where
## mouse-aimed shots will actually land (Mk1) or solves the lead angle so shots
## hit the cursor (Mk2). Because bolts inherit the ship's momentum, a straight
## shot drifts while moving; this module makes that drift visible and, at Mk2,
## corrects for it. Owns no flight or weapon hardware — it only advises and aims.
##
## Drawn in world space (top_level) so the overlay ignores the hull's rotation.

## Emitted whenever the active module changes, so the HUD can reflect it.
signal mode_changed(mode: int)

enum Mode { NONE, MK1, MK2 }

## Predicted-trajectory / impact color (Mk1) and the no-solution warning (Mk2).
@export var predict_color: Color = Color("ff6b6b")
## Locked firing-solution color (Mk2).
@export var solution_color: Color = Color("7cfc8a")
## Radius of the reticle drawn at the impact / target point, in pixels.
@export var reticle_radius: float = 7.0

## Active module. Setting it re-wires the turrets and refreshes the overlay.
var mode: int = Mode.NONE:
	set(value):
		if value == mode:
			return
		mode = value
		if mode != Mode.MK2:
			_clear_overrides() # hand aiming back to the turrets' own mouse tracking
		queue_redraw()
		mode_changed.emit(mode)

var _ship: Ship = null
var _turrets: Array[ShipTurret] = []


func _ready() -> void:
	top_level = true # draw in world space, unaffected by the hull's transform


## Wired by the ship so the computer can read platform velocity and aim turrets.
func setup(ship: Ship, turrets: Array[ShipTurret]) -> void:
	_ship = ship
	_turrets = turrets


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _ship == null:
		return
	if mode == Mode.MK2:
		_aim_turrets()
	if mode != Mode.NONE:
		queue_redraw() # overlay follows the moving ship and cursor


func _draw() -> void:
	if Engine.is_editor_hint() or _ship == null:
		return
	match mode:
		Mode.MK1:
			_draw_prediction()
		Mode.MK2:
			_draw_solution()


## Mk1: aim each turret straight at the cursor, then draw where the bolt really
## goes once the ship's velocity is added — the gap is the drift the player must
## account for by hand.
func _draw_prediction() -> void:
	var target := get_global_mouse_position()
	for turret in _turrets:
		var muzzle := turret.muzzle_position()
		var to_target := target - muzzle
		var dist := to_target.length()
		if dist < 0.001:
			continue
		var aim := to_target / dist
		var bolt_velocity := _ship.velocity + aim * turret.projectile_speed
		if bolt_velocity.length() < 0.001:
			continue
		var impact := muzzle + bolt_velocity.normalized() * dist
		draw_line(muzzle, impact, predict_color, 2.0, true)
		draw_arc(impact, reticle_radius, 0.0, TAU, 24, predict_color, 2.0, true)
		draw_dashed_line(target, impact, Color(predict_color, 0.5), 1.0, 6.0)
	draw_arc(target, 3.0, 0.0, TAU, 12, Color(predict_color, 0.7), 1.0, true)


## Mk2: solve the lead so shots land on the cursor and slew the turrets to it.
## Green reticle = solution locked; red = the ship outruns the muzzle, no shot.
func _draw_solution() -> void:
	var target := get_global_mouse_position()
	var solved := false
	for turret in _turrets:
		var aim := _firing_solution(turret.muzzle_position(), target, _ship.velocity, turret.projectile_speed)
		if aim != Vector2.ZERO:
			solved = true
			draw_line(turret.muzzle_position(), target, Color(solution_color, 0.6), 1.5, true)
	var color := solution_color if solved else predict_color
	draw_arc(target, reticle_radius, 0.0, TAU, 24, color, 2.0, true)
	var arm := reticle_radius * 1.6
	draw_line(target - Vector2(arm, 0.0), target + Vector2(arm, 0.0), color, 1.5, true)
	draw_line(target - Vector2(0.0, arm), target + Vector2(0.0, arm), color, 1.5, true)


## Feeds every turret the Mk2 lead direction (Vector2.ZERO when unsolvable, which
## makes the turret fall back to plain mouse-aim).
func _aim_turrets() -> void:
	var target := get_global_mouse_position()
	for turret in _turrets:
		turret.aim_override = _firing_solution(
			turret.muzzle_position(), target, _ship.velocity, turret.projectile_speed
		)


func _clear_overrides() -> void:
	for turret in _turrets:
		turret.aim_override = Vector2.ZERO


## Lead-angle solver for a stationary target point. Chooses a barrel direction so
## that muzzle_velocity + platform_velocity points at `target`. Returns the unit
## aim direction, or Vector2.ZERO if the platform outruns the muzzle (no hit).
func _firing_solution(muzzle: Vector2, target: Vector2, platform_velocity: Vector2, muzzle_speed: float) -> Vector2:
	var to_target := target - muzzle
	var dist := to_target.length()
	if dist < 0.001 or muzzle_speed <= 0.0:
		return Vector2.ZERO
	var dir := to_target / dist
	# Solve |k * dir - platform_velocity| = muzzle_speed for the bolt's closing
	# speed k along `dir`; the aim is whatever direction supplies the remainder.
	var along := platform_velocity.dot(dir)
	var discriminant := along * along - (platform_velocity.length_squared() - muzzle_speed * muzzle_speed)
	if discriminant < 0.0:
		return Vector2.ZERO
	var k := along + sqrt(discriminant)
	if k <= 0.0:
		return Vector2.ZERO
	return (dir * k - platform_velocity).normalized()
