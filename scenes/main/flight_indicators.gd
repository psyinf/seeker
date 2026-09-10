class_name FlightIndicators
extends Node2D
## Positions flight cues on the ship: the desired heading (aim) and actual
## velocity (prograde) arrows, plus a retrograde dot (where to point to stop).
## Reads the ship's public state; does not drive it.

## The ship whose heading/velocity to visualize.
@export var ship_path: NodePath

@export_group("Aim (desired heading)")
## Fixed length of the aim arrow, in pixels.
@export var aim_length: float = 70.0

@export_group("Velocity (prograde)")
## Pixels of arrow length per pixel/second of speed.
@export var velocity_scale: float = 0.18
## Longest the velocity arrow may get, in pixels.
@export var velocity_max_length: float = 220.0
## Below this speed the velocity arrow is hidden, in pixels/second.
@export var velocity_min_speed: float = 2.0

@export_group("Retrograde (thrust-to-stop)")
## Fixed distance from the ship at which the retrograde reticle sits, in pixels.
## It marks the heading to hold for a thrust-to-stop burn; the speed to cancel is
## already shown by the velocity arrow, so this is a direction cue only.
@export var retro_distance: float = 90.0
## Radius of the retrograde ring, in pixels.
@export var retro_radius: float = 6.0
## Line width of the retrograde reticle, in pixels.
@export var retro_width: float = 2.0
## Length the diagonal spokes stick out past the ring, in pixels.
@export var retro_spoke_length: float = 5.0
## Color of the retrograde reticle.
@export var retro_color: Color = Color(1, 0.360784, 0.360784)

@onready var ship := get_node_or_null(ship_path) as Ship
@onready var _aim: VectorArrow = $AimArrow
@onready var _velocity: VectorArrow = $VelocityArrow
@onready var _retro: Node2D = $RetroMarker


func _ready() -> void:
	_build_retro_marker()


func _process(_delta: float) -> void:
	if ship == null:
		return
	global_position = ship.global_position
	_aim.global_rotation = ship.aim_direction.angle()
	_aim.length = aim_length
	var speed := ship.velocity.length()
	_velocity.visible = speed >= velocity_min_speed
	if _velocity.visible:
		_velocity.global_rotation = ship.velocity.angle()
		_velocity.length = minf(speed * velocity_scale, velocity_max_length)
	# Place the retrograde reticle opposite the motion at a fixed distance — the
	# heading to hold for a thrust-to-stop burn. Hidden when nearly at rest.
	_retro.visible = speed >= velocity_min_speed
	if _retro.visible:
		_retro.position = -ship.velocity.normalized() * retro_distance


## Builds the retrograde reticle: an anti-aliased ring with four diagonal spokes
## sticking outward (the classic retrograde X), all in the marker's local space.
func _build_retro_marker() -> void:
	var ring := Line2D.new()
	ring.closed = true
	ring.width = retro_width
	ring.default_color = retro_color
	ring.antialiased = true
	var segments := 24
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		ring.add_point(Vector2(cos(angle), sin(angle)) * retro_radius)
	_retro.add_child(ring)
	for k in 4:
		var angle := PI / 4.0 + PI / 2.0 * float(k)
		var dir := Vector2(cos(angle), sin(angle))
		var spoke := Line2D.new()
		spoke.width = retro_width
		spoke.default_color = retro_color
		spoke.antialiased = true
		spoke.add_point(dir * retro_radius)
		spoke.add_point(dir * (retro_radius + retro_spoke_length))
		_retro.add_child(spoke)
