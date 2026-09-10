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
## The flight indicators overlay (owns the retrograde-marker click).
@export var indicators_path: NodePath

@onready var ship := get_node_or_null(ship_path) as Ship
@onready var camera := get_node_or_null(camera_path) as Camera2D
@onready var command_bar := get_node_or_null(command_bar_path) as CommandBar
@onready var context_menu := get_node_or_null(context_menu_path) as ContextMenu
@onready var indicators := get_node_or_null(indicators_path) as FlightIndicators

## The design being test-flown, kept so the "Back to Designer" button can hand it
## back to the editor. Null when the mode was not entered from the editor.
var _design: ShipDesign = null


func _ready() -> void:
	if ship != null and context_menu != null:
		ship.context_menu_requested.connect(context_menu.open_at_mouse)
		context_menu.full_stop_requested.connect(ship.full_stop)
	if ship != null and command_bar != null:
		command_bar.fire_control_mode_changed.connect(ship.set_fire_control_mode)
		command_bar.align_thrust_toggled.connect(ship.set_require_alignment)
		command_bar.group_fire_toggled.connect(ship.set_group_firing)
	if ship != null and indicators != null:
		indicators.retro_burn_requested.connect(ship.set_retro_burn)
	if ship != null:
		ship.projectile_fired.connect(_on_ship_projectile_fired)


## Receives a payload from `ModeManager.switch_to`. A `ShipDesign` (from the ship
## editor's Test Flight) is applied to the ship so you fly what you just built,
## and a "Back to Designer" button is shown to return with the same design.
func setup(payload: Variant) -> void:
	if payload is ShipDesign and ship != null:
		_design = payload
		ship.apply_design(_design)
		_add_back_button()


## A top-left button that returns to the ship editor, carrying the flown design.
func _add_back_button() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var button := Button.new()
	button.text = "< Back to Designer"
	button.position = Vector2(12, 12)
	button.pressed.connect(_return_to_designer)
	layer.add_child(button)


func _return_to_designer() -> void:
	var manager := get_parent() as ModeManager
	if manager == null:
		return
	manager.switch_to(ModeManager.Mode.SHIP_EDITOR, _design)


## Places a turret bolt in the world so it flies free of the ship's transform.
func _on_ship_projectile_fired(projectile: Node2D) -> void:
	add_child(projectile)


func _process(_delta: float) -> void:
	if ship != null and camera != null:
		camera.global_position = ship.global_position
