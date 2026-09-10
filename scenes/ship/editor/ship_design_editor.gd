extends Node2D
## In-game ship design editor. Edits a `ShipDesign` on a grid: left-click places
## the selected module kind, right-click removes, mouse wheel / R rotates the
## placement facing (and any directional cell under the cursor). A code-built
## palette picks the kind, a stats panel shows the ship's derived totals, and the
## bottom bar saves/loads/clears. The `Hull` child (SegmentedHull) renders the
## design; `Hover` draws the cursor highlight. Standalone for now; wiring into
## ModeManager comes later.

const SAVE_PATH := "user://ship_designs/current.tres"

## Kinds shown in the palette, in order, with their labels.
const PALETTE := [
	[ShipSegment.Kind.CORE, "Core"],
	[ShipSegment.Kind.HULL, "Hull"],
	[ShipSegment.Kind.ARMOR, "Armor"],
	[ShipSegment.Kind.THRUSTER, "Thruster"],
	[ShipSegment.Kind.WEAPON, "Weapon"],
	[ShipSegment.Kind.REACTOR, "Reactor"],
	[ShipSegment.Kind.DRONE_BAY, "Drone Bay"],
	[ShipSegment.Kind.CARGO_HOLD, "Cargo Hold"],
	[ShipSegment.Kind.SHIELD, "Shield"],
	[ShipSegment.Kind.SENSOR, "Sensor"],
	[ShipSegment.Kind.FUEL_TANK, "Fuel Tank"],
	[ShipSegment.Kind.RADIATOR, "Radiator"],
]

var design: ShipDesign
var selected_kind: ShipSegment.Kind = ShipSegment.Kind.HULL
var place_facing: ShipSegment.Facing = ShipSegment.Facing.UP
var hover_cell: Vector2i = Vector2i.ZERO
var has_hover: bool = false

@onready var _hull: Node2D = $Hull
@onready var _hover: Node2D = $Hover

var _palette_buttons: Array[Button] = []
var _stats_label: Label
var _status_label: Label


func _ready() -> void:
	design = ShipDesign.create_default()
	_hull.design = design
	_hover.editor = self
	design.changed.connect(_on_design_changed)
	_build_ui()
	_select_kind(selected_kind)
	_refresh_stats()
	queue_redraw()


## Local-space unit vector the placement facing points along.
func place_facing_dir() -> Vector2:
	match place_facing:
		ShipSegment.Facing.RIGHT:
			return Vector2.RIGHT
		ShipSegment.Facing.DOWN:
			return Vector2.DOWN
		ShipSegment.Facing.LEFT:
			return Vector2.LEFT
		_:
			return Vector2.UP


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover()
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_place()
			MOUSE_BUTTON_RIGHT:
				_erase()
			MOUSE_BUTTON_WHEEL_UP:
				_rotate(1)
			MOUSE_BUTTON_WHEEL_DOWN:
				_rotate(-1)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_rotate(1)


func _update_hover() -> void:
	var world := get_global_mouse_position()
	var cell := Vector2i((world / design.cell_size).round())
	if not has_hover or cell != hover_cell:
		hover_cell = cell
		has_hover = true
		_hover.queue_redraw()


func _place() -> void:
	if not has_hover:
		return
	design.place(selected_kind, hover_cell, place_facing)


func _erase() -> void:
	if has_hover:
		design.remove_at(hover_cell)


func _rotate(dir: int) -> void:
	place_facing = (int(place_facing) + dir + 4) % 4
	var segment: ShipSegment = design.get_segment_at(hover_cell) if has_hover else null
	if segment != null and ShipSegment.is_directional(segment.kind):
		segment.facing = place_facing
	_hover.queue_redraw()


func _on_design_changed() -> void:
	_refresh_stats()


## A faint reference grid behind the ship (root draws before its children).
func _draw() -> void:
	var cs := design.cell_size
	var reach := 12
	var extent := (reach + 0.5) * cs
	var col := Color(1, 1, 1, 0.06)
	for i in range(-reach, reach + 2):
		var o := (i - 0.5) * cs
		draw_line(Vector2(o, -extent), Vector2(o, extent), col, 1.0)
		draw_line(Vector2(-extent, o), Vector2(extent, o), col, 1.0)


# --- UI ---------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var palette_panel := PanelContainer.new()
	palette_panel.position = Vector2(12, 12)
	layer.add_child(palette_panel)
	var palette_box := VBoxContainer.new()
	palette_panel.add_child(palette_box)
	var title := Label.new()
	title.text = "Modules"
	palette_box.add_child(title)
	for entry in PALETTE:
		var kind: ShipSegment.Kind = entry[0]
		var button := Button.new()
		button.text = entry[1]
		button.toggle_mode = true
		button.pressed.connect(_select_kind.bind(kind))
		palette_box.add_child(button)
		_palette_buttons.append(button)

	var stats_panel := PanelContainer.new()
	stats_panel.position = Vector2(get_viewport().get_visible_rect().size.x - 220, 12)
	layer.add_child(stats_panel)
	_stats_label = Label.new()
	_stats_label.custom_minimum_size = Vector2(200, 0)
	stats_panel.add_child(_stats_label)

	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	layer.add_child(bottom)
	var bar := HBoxContainer.new()
	bottom.add_child(bar)
	_add_button(bar, "New", _on_new)
	_add_button(bar, "Clear", _on_clear)
	_add_button(bar, "Save", _on_save)
	_add_button(bar, "Load", _on_load)
	_status_label = Label.new()
	_status_label.text = "LMB place  ·  RMB remove  ·  wheel/R rotate"
	bar.add_child(_status_label)


func _add_button(parent: Node, text: String, handler: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(handler)
	parent.add_child(button)


func _select_kind(kind: ShipSegment.Kind) -> void:
	selected_kind = kind
	for i in _palette_buttons.size():
		_palette_buttons[i].button_pressed = PALETTE[i][0] == kind
	_hover.queue_redraw()


func _refresh_stats() -> void:
	if _stats_label == null:
		return
	_stats_label.text = "\n".join([
		"Class: %s" % design.ship_class,
		"Cells: %d" % design.segments.size(),
		"Mass: %.0f" % design.total_mass(),
		"Net power: %+.0f" % design.net_power(),
		"Hull HP: %.0f" % design.total_hp(),
		"Cargo: %.0f" % design.cargo_capacity_total(),
		"Scan: %.0f" % design.scan_range_total(),
		"Cost: %.0f" % design.build_cost_total(),
	])


func _on_new() -> void:
	_replace_design(ShipDesign.create_default())
	_set_status("New Nomad design")


func _on_clear() -> void:
	var empty := ShipDesign.new()
	empty.ship_class = design.ship_class
	empty.cell_size = design.cell_size
	_replace_design(empty)
	_set_status("Cleared")


func _on_save() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_PATH.get_base_dir())
	var err := ResourceSaver.save(design, SAVE_PATH)
	_set_status("Saved" if err == OK else "Save failed (%d)" % err)


func _on_load() -> void:
	if not ResourceLoader.exists(SAVE_PATH):
		_set_status("No saved design")
		return
	var loaded := ResourceLoader.load(SAVE_PATH, "ShipDesign", ResourceLoader.CACHE_MODE_IGNORE) as ShipDesign
	if loaded == null:
		_set_status("Load failed")
		return
	_replace_design(loaded)
	_set_status("Loaded")


func _replace_design(next: ShipDesign) -> void:
	if design.changed.is_connected(_on_design_changed):
		design.changed.disconnect(_on_design_changed)
	design = next
	design.changed.connect(_on_design_changed)
	_hull.design = design
	_refresh_stats()
	queue_redraw()
	_hover.queue_redraw()


func _set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text
