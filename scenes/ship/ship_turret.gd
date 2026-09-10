@tool
class_name ShipTurret
extends Node2D
## A small turret mounted on the ship that independently aims at the mouse
## cursor and fires bolts. It rotates in world space (so it tracks the pointer
## regardless of the hull's heading), slews toward the target instead of
## snapping, and gates its own fire rate. It owns no flight logic and draws
## itself (@tool), matching the hull/thruster component split. Instance more of
## these on the ship for extra turrets; tune each independently in the inspector.

## Emitted when the turret spawns a bolt. The turret does not add it to the tree
## itself (it may not know the world node) — a listener places it in the world.
signal projectile_fired(projectile: Node2D)

## Emitted on each shot with the recoil impulse (opposite the muzzle), so the ship
## can push back against it with its RCS. Zero-recoil weapons never emit.
signal recoil_applied(impulse: Vector2)

## Radius of the turret base, in pixels.
@export var base_radius: float = 9.0:
	set(value):
		base_radius = value
		queue_redraw()

## Length of the barrel from the turret center, in pixels.
@export var barrel_length: float = 22.0:
	set(value):
		barrel_length = value
		queue_redraw()

## Width of the barrel, in pixels.
@export var barrel_width: float = 5.0:
	set(value):
		barrel_width = value
		queue_redraw()

## Turret fill color.
@export var turret_color: Color = Color("cfd8e3"):
	set(value):
		turret_color = value
		queue_redraw()

## Barrel color.
@export var barrel_color: Color = Color("8b98a8"):
	set(value):
		barrel_color = value
		queue_redraw()

## Outline color for the base.
@export var outline_color: Color = Color("1d2330"):
	set(value):
		outline_color = value
		queue_redraw()

## How fast the turret slews toward the aim, in radians/second. 0 aims instantly.
@export_range(0.0, 30.0, 0.1) var slew_speed: float = 8.0

@export_group("Weapon")
## The mounted weapon's stat block. Assigning one syncs cadence and muzzle speed;
## leave null to use the raw fire_rate/projectile_speed below (a plain mount).
@export var weapon: WeaponConfig:
	set(value):
		weapon = value
		_sync_weapon()
## Fallback bolt scene, used when the weapon config carries none.
@export var projectile_scene: PackedScene
## Shots per second while firing (overridden by an assigned weapon).
@export_range(0.1, 30.0, 0.1) var fire_rate: float = 5.0
## Muzzle velocity of each bolt, in pixels/second (overridden by an assigned weapon).
@export var projectile_speed: float = 1100.0

## True while the fire command is held; the turret shoots at its fire rate.
var firing: bool = false
## Platform velocity (px/s) added to each bolt so shots inherit ship momentum.
## Set by the ship every frame; leave zero for a static mount.
var base_velocity: Vector2 = Vector2.ZERO
## World-space aim direction forced by the fire-control computer (Mk2 lead). When
## non-zero it overrides mouse tracking; Vector2.ZERO means "aim at the cursor".
var aim_override: Vector2 = Vector2.ZERO
## Seconds until the turret may fire again.
var _cooldown: float = 0.0


## World position of the barrel tip, where bolts spawn.
func muzzle_position() -> Vector2:
	return global_position + Vector2.UP.rotated(global_rotation) * barrel_length


func _ready() -> void:
	if not Engine.is_editor_hint() and weapon == null:
		weapon = WeaponConfig.autocannon() # a mount always carries a working weapon
	_sync_weapon()


## Copies the assigned weapon's cadence and muzzle speed onto the turret so the
## fire gate and the fire-control lead solver read live values.
func _sync_weapon() -> void:
	if weapon == null:
		return
	fire_rate = weapon.fire_rate
	projectile_speed = weapon.projectile_speed


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Barrel points along local -Y, so a heading angle needs a +PI/2 offset.
	var aim_vec := aim_override if aim_override != Vector2.ZERO else get_global_mouse_position() - global_position
	if aim_vec.length() >= 0.001:
		var target := aim_vec.angle() + PI / 2.0
		if slew_speed <= 0.0:
			global_rotation = target
		else:
			var error := wrapf(target - global_rotation, -PI, PI)
			var step := clampf(error, -slew_speed * delta, slew_speed * delta)
			global_rotation += step
	_cooldown = maxf(0.0, _cooldown - delta)
	if firing and _cooldown <= 0.0:
		_fire()
		_cooldown = 1.0 / fire_rate


## Spawns a bolt at the barrel tip, launched along the current aim.
func _fire() -> void:
	var scene := projectile_scene
	if weapon != null and weapon.projectile_scene != null:
		scene = weapon.projectile_scene
	if scene == null:
		return
	var dir := Vector2.UP.rotated(global_rotation)
	var projectile := scene.instantiate() as Node2D
	if projectile == null:
		return
	projectile.global_position = global_position + dir * barrel_length
	projectile.rotation = global_rotation
	if projectile is Projectile:
		var bolt := projectile as Projectile
		bolt.damage = weapon.damage if weapon != null else bolt.damage
		if weapon != null:
			bolt.color = weapon.projectile_color
	if projectile is Missile and weapon != null:
		var m := projectile as Missile
		m.cruise_speed = weapon.projectile_speed
		m.turn_rate = weapon.homing_turn_rate
	if projectile.has_method("launch"):
		# Muzzle velocity plus the platform's momentum (Newtonian, frictionless space).
		projectile.launch(dir * projectile_speed + base_velocity)
	projectile_fired.emit(projectile)
	# Recoil kicks the ship opposite the muzzle; its RCS fights to null it.
	var recoil := weapon.recoil() if weapon != null else 0.0
	if recoil > 0.0:
		recoil_applied.emit(-dir * recoil)


func _draw() -> void:
	# Barrel first so the base cap sits over its root; forward is -Y.
	var half := barrel_width * 0.5
	draw_rect(Rect2(-half, -barrel_length, barrel_width, barrel_length), barrel_color)
	draw_circle(Vector2.ZERO, base_radius, turret_color)
	draw_arc(Vector2.ZERO, base_radius, 0.0, TAU, 24, outline_color, 2.0, true)
