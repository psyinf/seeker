class_name FlightIndicators
extends Node2D
## Positions two arrow scenes on the ship: the desired heading (aim) and the
## actual velocity (prograde). Reads the ship's public state; does not drive it.

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

@onready var ship := get_node_or_null(ship_path) as Ship
@onready var _aim: VectorArrow = $AimArrow
@onready var _velocity: VectorArrow = $VelocityArrow


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
