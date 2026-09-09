class_name TacticalCombat
extends Node2D
## Real-time tactical combat mode: mouse-aimed Newtonian free flight. Keeps the
## camera centered on the ship; the reference grid and flight indicators are
## self-contained child scenes.

## The ship the camera follows.
@export var ship_path: NodePath
## The camera to reposition each frame (kept unrotated so the view never spins).
@export var camera_path: NodePath
## The bottom command bar whose toggles drive ship modes.
@export var command_bar_path: NodePath
## The context menu shown on a double-click.
@export var context_menu_path: NodePath

@onready var ship := get_node_or_null(ship_path) as Ship
@onready var camera := get_node_or_null(camera_path) as Camera2D
@onready var command_bar := get_node_or_null(command_bar_path) as CommandBar
@onready var context_menu := get_node_or_null(context_menu_path) as ContextMenu


func _ready() -> void:
	if ship != null and context_menu != null:
		ship.context_menu_requested.connect(context_menu.open_at_mouse)
		context_menu.full_stop_requested.connect(ship.full_stop)


func _process(_delta: float) -> void:
	if ship != null and camera != null:
		camera.global_position = ship.global_position
