class_name ModeManager
extends Node
## Owns the active game mode and swaps between them. Each mode is a self-contained
## scene instanced as the manager's only child. Tactical combat is the first mode;
## the strategic (in-system) map and system-jump modes are scaffolded but not yet
## built. Switch with `switch_to(...)`.

enum Mode { TACTICAL_COMBAT, STRATEGIC_MAP, SYSTEM_JUMP, SHIP_EDITOR }

## Emitted after the active mode changes.
signal mode_changed(mode: Mode)

## Real-time mouse-aimed combat/free-flight.
@export var tactical_combat_scene: PackedScene
## Zoomed-out travel within a star system (not built yet).
@export var strategic_map_scene: PackedScene
## Jumping between star systems (not built yet).
@export var system_jump_scene: PackedScene
## Grid ship-design editor; its "Test Flight" hands the design to tactical combat.
@export var ship_editor_scene: PackedScene
@export var initial_mode: Mode = Mode.TACTICAL_COMBAT

var current_mode: Mode
var _current: Node


func _ready() -> void:
	switch_to(initial_mode)


## Swap to `mode`. If the new mode node has a `setup(payload)` method and a
## non-null `payload` is given, it is handed over after the node enters the tree
## (e.g. the editor passes its `ShipDesign` to tactical combat for a test flight).
func switch_to(mode: Mode, payload: Variant = null) -> void:
	var scene := _scene_for(mode)
	if scene == null:
		push_warning("ModeManager: no scene assigned for mode %d" % mode)
		return
	if _current != null:
		_current.queue_free()
	_current = scene.instantiate()
	add_child(_current)
	if payload != null and _current.has_method("setup"):
		_current.setup(payload)
	current_mode = mode
	mode_changed.emit(mode)


func _scene_for(mode: Mode) -> PackedScene:
	match mode:
		Mode.TACTICAL_COMBAT:
			return tactical_combat_scene
		Mode.STRATEGIC_MAP:
			return strategic_map_scene
		Mode.SYSTEM_JUMP:
			return system_jump_scene
		Mode.SHIP_EDITOR:
			return ship_editor_scene
	return null
