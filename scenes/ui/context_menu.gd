class_name ContextMenu
extends CanvasLayer
## Context menu shown at the cursor on a double-click. A full-screen catcher
## behind the panel dismisses it and blocks flight clicks while it is open.
## Emits high-level orders as signals so the mode wires them to the ship.

## Emitted when the player picks "Full Stop".
signal full_stop_requested

@onready var _catcher: Control = $Catcher
@onready var _panel: PanelContainer = $Catcher/Menu
@onready var _full_stop: Button = $Catcher/Menu/VBox/FullStop
@onready var _cancel: Button = $Catcher/Menu/VBox/Cancel


func _ready() -> void:
	_catcher.visible = false
	_catcher.gui_input.connect(_on_catcher_input)
	_full_stop.pressed.connect(_on_full_stop)
	_cancel.pressed.connect(close)


func open_at_mouse() -> void:
	_panel.position = get_viewport().get_mouse_position()
	_catcher.visible = true


func close() -> void:
	_catcher.visible = false


func _on_catcher_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close() # a click outside the panel dismisses the menu


func _on_full_stop() -> void:
	full_stop_requested.emit()
	close()
