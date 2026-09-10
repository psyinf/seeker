@tool
class_name WeaponConfig
extends Resource
## One weapon's tunable stat block, shared by the turret that mounts it. A
## `Resource`, so loadouts can be authored in the inspector and saved as `.tres`.
## Two kinds exist: PROJECTILE (dumb bolts fired at a muzzle speed) and GUIDED
## (missiles that home on the nearest target). Ready-made presets are the static
## factories below (`railgun`, `autocannon`, `missile`).

enum Kind {
	PROJECTILE, ## Straight bolt; recoil = muzzle speed × ammo mass.
	GUIDED,     ## Homing missile; soft launch, negligible recoil.
}

## Display name for the HUD / loadout screens.
@export var weapon_name: String = "Autocannon"
## Which firing model this weapon uses.
@export var kind: Kind = Kind.PROJECTILE
## Muzzle velocity (PROJECTILE) or cruise speed (GUIDED), in pixels/second.
@export var projectile_speed: float = 1000.0
## Damage a single round deals on impact.
@export var damage: float = 1.0
## Mass of one round; drives recoil (recoil = speed × ammo_mass for projectiles).
@export var ammo_mass: float = 0.004
## Cadence: shots per second while firing.
@export_range(0.1, 30.0, 0.1) var fire_rate: float = 12.0
## Homing agility for GUIDED weapons, in radians/second. Ignored for projectiles.
@export_range(0.0, 20.0, 0.1) var homing_turn_rate: float = 4.0
## Tracer / body color of the spawned round.
@export var projectile_color: Color = Color("ffd36b")
## Round spawned per shot. Presets preload the matching bolt/missile scene.
@export var projectile_scene: PackedScene


## Recoil impulse of a single shot, in momentum units (px/s × mass). Projectile
## recoil is the round's momentum leaving the barrel; guided weapons launch soft,
## so their recoil is negligible.
func recoil() -> float:
	if kind == Kind.GUIDED:
		return 0.0
	return projectile_speed * ammo_mass


## Infrequent, hard-hitting projectile: massive muzzle speed and impact damage at
## roughly one shot per second, with heavy recoil to match.
static func railgun() -> WeaponConfig:
	var w := WeaponConfig.new()
	w.weapon_name = "Railgun"
	w.kind = Kind.PROJECTILE
	w.projectile_speed = 2400.0
	w.damage = 8.0
	w.ammo_mass = 0.03
	w.fire_rate = 1.0
	w.projectile_color = Color("9be7ff")
	w.projectile_scene = preload("res://scenes/ship/projectile.tscn")
	return w


## High-cadence projectile: many small bolts, low damage each, and light recoil.
static func autocannon() -> WeaponConfig:
	var w := WeaponConfig.new()
	w.weapon_name = "Autocannon"
	w.kind = Kind.PROJECTILE
	w.projectile_speed = 1000.0
	w.damage = 1.0
	w.ammo_mass = 0.004
	w.fire_rate = 12.0
	w.projectile_color = Color("ffd36b")
	w.projectile_scene = preload("res://scenes/ship/projectile.tscn")
	return w


## Guided missile: slow launch, homes on the nearest target, heavy warhead, and
## no meaningful recoil (soft-launched).
static func missile() -> WeaponConfig:
	var w := WeaponConfig.new()
	w.weapon_name = "Missile"
	w.kind = Kind.GUIDED
	w.projectile_speed = 420.0
	w.damage = 12.0
	w.ammo_mass = 0.0
	w.fire_rate = 0.6
	w.homing_turn_rate = 4.0
	w.projectile_color = Color("ff9f68")
	w.projectile_scene = preload("res://scenes/ship/missile.tscn")
	return w
