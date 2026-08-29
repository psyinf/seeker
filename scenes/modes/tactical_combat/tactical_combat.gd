class_name TacticalCombat
extends Node2D
## Real-time tactical combat mode: mouse-aimed Newtonian free flight. Keeps the
## camera centered on the ship; the reference grid and flight indicators are
## self-contained child scenes.

## The ship the camera follows.
@export var ship_path: NodePath
## The camera to reposition each frame (kept unrotated so the view never spins).
@export var camera_path: NodePath

@onready var ship := get_node_or_null(ship_path) as Node2D
@onready var camera := get_node_or_null(camera_path) as Camera2D


func _process(_delta: float) -> void:
	if ship != null and camera != null:
		camera.global_position = ship.global_position
