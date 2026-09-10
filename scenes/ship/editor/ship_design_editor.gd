extends Node2D
## In-game ship design editor. Edits a `ShipDesign` on a grid: left-click places
## the selected module kind, right-click removes, mouse wheel zooms, R rotates the
## placement facing (and any directional cell under the cursor). Normal mode only
## builds within the class's hull footprint; H toggles hull-design mode (extend/
## shrink the hull — a new hull type) when `allow_hull_design` is on. A code-built
## palette picks the kind, a stats panel shows the ship's derived totals, and the
## bottom bar news/clears/saves/loads and starts a Test Flight. The `Hull` child
## (SegmentedHull) renders the design; `Hover` draws the cursor highlight. Hosted
## by `ModeManager` as the `SHIP_EDITOR` mode (also runs standalone).
##
## The palette is KSP-style: a left column of category tabs (Command, Structure,
## Propulsion, Power, Combat, Utility) picks a category and only that category's
## parts are listed beside it.

const SAVE_PATH := "user://ship_designs/current.tres"
const ZOOM_MIN := 0.3
const ZOOM_MAX := 4.0
const ZOOM_STEP := 1.1

## When false, hull-design mode can't be entered, so this editor only ever lets
## the player build modules within the fixed hull (the in-game default). Turn it
## on to author new hull types by extending the footprint (H toggles it).
@export var allow_hull_design: bool = true

## Part palette grouped into KSP-style category tabs. Each entry is
## `[category_label, [[kind, part_label], ...]]`; the tab strip picks a category
## and only that category's parts are shown. Keep kinds listed once.
const CATEGORIES := [
	["Command", [
		[ShipSegment.Kind.CORE, "Core"],
		[ShipSegment.Kind.SENSOR, "Sensor"],
	]],
	["Structure", [
		[ShipSegment.Kind.HULL, "Hull"],
		[ShipSegment.Kind.ARMOR, "Armor"],
	]],
	["Propulsion", [
		[ShipSegment.Kind.THRUSTER, "Drive"],
		[ShipSegment.Kind.FUEL_TANK, "Fuel Tank"],
	]],
	["Power", [
		[ShipSegment.Kind.REACTOR, "Reactor"],
		[ShipSegment.Kind.RADIATOR, "Radiator"],
	]],
	["Combat", [
		[ShipSegment.Kind.WEAPON, "Weapon"],
		[ShipSegment.Kind.SHIELD, "Shield"],
		[ShipSegment.Kind.DRONE_BAY, "Drone Bay"],
	]],
	["Utility", [
		[ShipSegment.Kind.CARGO_HOLD, "Cargo Hold"],
	]],
]

var design: ShipDesign
var selected_kind: ShipSegment.Kind = ShipSegment.Kind.HULL
var place_facing: ShipSegment.Facing = ShipSegment.Facing.UP
var hover_cell: Vector2i = Vector2i.ZERO
var has_hover: bool = false
## True while editing the hull footprint (extend/shrink the shell) instead of
## placing modules within it. Only reachable when `allow_hull_design` is on.
var _hull_design: bool = false

@onready var _hull: Node2D = $Hull
@onready var _hover: Node2D = $Hover
@onready var _camera: Camera2D = $Camera2D

var _category_buttons: Array[Button] = []
var _parts_box: VBoxContainer
var selected_category: int = 0
var _stats_label: Label
var _status_label: Label


func _ready() -> void:
	design = ShipDesign.create_default()
	_hull.design = design
	_hover.editor = self
	design.changed.connect(_on_design_changed)
	_build_ui()
	_select_category(_category_of_kind(selected_kind))
	_select_kind(selected_kind)
	_refresh_stats()
	queue_redraw()


## Receives a payload from `ModeManager.switch_to`; a `ShipDesign` (handed back by
## tactical combat's "Back to Designer") is restored so editing continues.
func setup(payload: Variant) -> void:
	if payload is ShipDesign:
		_replace_design(payload)
		_set_status("Back from test flight")


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
				_apply_zoom(ZOOM_STEP)
			MOUSE_BUTTON_WHEEL_DOWN:
				_apply_zoom(1.0 / ZOOM_STEP)
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				_rotate(1)
			KEY_H:
				_toggle_hull_design()


## Zoom the view around the point under the cursor so it stays put.
func _apply_zoom(factor: float) -> void:
	var before := get_global_mouse_position()
	var z := clampf(_camera.zoom.x * factor, ZOOM_MIN, ZOOM_MAX)
	_camera.zoom = Vector2(z, z)
	var after := get_global_mouse_position()
	_camera.global_position += before - after


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
	if _hull_design:
		var seg := design.get_segment_at(hover_cell)
		if seg != null and seg.fixed:
			_set_status("Cell locked")
			return
		if design.add_to_footprint(hover_cell):
			_set_status("Hull extended")
		return
	if not design.is_in_footprint(hover_cell):
		_set_status("Outside hull")
		return
	var existing := design.get_segment_at(hover_cell)
	if existing != null and existing.fixed:
		_set_status("Cell locked")
		return
	design.place(selected_kind, hover_cell, place_facing)


func _erase() -> void:
	if not has_hover:
		return
	var existing := design.get_segment_at(hover_cell)
	if existing != null and existing.fixed:
		_set_status("Cell locked")
		return
	if _hull_design:
		if design.remove_from_footprint(hover_cell):
			_set_status("Hull trimmed")
		return
	if not design.is_in_footprint(hover_cell):
		return
	design.remove_at(hover_cell)


func _rotate(dir: int) -> void:
	place_facing = (int(place_facing) + dir + 4) % 4
	var segment: ShipSegment = design.get_segment_at(hover_cell) if has_hover else null
	if segment != null and ShipSegment.is_directional(segment.kind):
		segment.facing = place_facing
	_hover.queue_redraw()


## True while the editor is in hull-design mode; read by the hover overlay.
func is_hull_design_mode() -> bool:
	return _hull_design


## Toggle hull-design mode (extend/shrink the hull). No-op when disabled, so a
## shipped build can lock players to module placement within the fixed hull.
func _toggle_hull_design() -> void:
	if not allow_hull_design:
		return
	_hull_design = not _hull_design
	_set_status("Hull design ON · LMB extend  RMB trim" if _hull_design else "Building within the hull")
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
	var palette_row := HBoxContainer.new()
	palette_panel.add_child(palette_row)

	# Left column: category tabs (KSP-style).
	var tabs_box := VBoxContainer.new()
	palette_row.add_child(tabs_box)
	var tabs_title := Label.new()
	tabs_title.text = "Category"
	tabs_box.add_child(tabs_title)
	for i in CATEGORIES.size():
		var cat_button := Button.new()
		cat_button.text = CATEGORIES[i][0]
		cat_button.toggle_mode = true
		cat_button.pressed.connect(_select_category.bind(i))
		tabs_box.add_child(cat_button)
		_category_buttons.append(cat_button)

	palette_row.add_child(VSeparator.new())

	# Right column: parts of the selected category (rebuilt on tab switch).
	var parts_col := VBoxContainer.new()
	palette_row.add_child(parts_col)
	var title := Label.new()
	title.text = "Modules"
	parts_col.add_child(title)
	_parts_box = VBoxContainer.new()
	parts_col.add_child(_parts_box)

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
	_add_button(bar, "Test Flight", _on_test_flight)
	_status_label = Label.new()
	var help := "LMB place  ·  RMB remove  ·  R rotate  ·  wheel zoom"
	if allow_hull_design:
		help += "  ·  H hull-design"
	_status_label.text = help
	bar.add_child(_status_label)


func _add_button(parent: Node, text: String, handler: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(handler)
	parent.add_child(button)


## Index of the category tab whose part list contains `kind` (0 if none).
func _category_of_kind(kind: ShipSegment.Kind) -> int:
	for i in CATEGORIES.size():
		for entry in CATEGORIES[i][1]:
			if entry[0] == kind:
				return i
	return 0


## Switch the active category tab and rebuild the parts list beside it.
func _select_category(index: int) -> void:
	selected_category = index
	for i in _category_buttons.size():
		_category_buttons[i].button_pressed = i == index
	for child in _parts_box.get_children():
		child.queue_free()
	for entry in CATEGORIES[index][1]:
		var kind: ShipSegment.Kind = entry[0]
		var button := Button.new()
		button.text = entry[1]
		button.toggle_mode = true
		button.button_pressed = kind == selected_kind
		button.set_meta("kind", kind)
		button.pressed.connect(_select_kind.bind(kind))
		_parts_box.add_child(button)


func _select_kind(kind: ShipSegment.Kind) -> void:
	selected_kind = kind
	# Drives vent aft by default so extensions stack toward the nose.
	if kind == ShipSegment.Kind.THRUSTER:
		place_facing = ShipSegment.Facing.DOWN
	for child in _parts_box.get_children():
		if child is Button:
			child.button_pressed = child.get_meta("kind") == kind
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
	design.clear_modules()
	_set_status("Modules cleared")


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


## Hand the current design to tactical combat and switch to it, so the player can
## fly what they just built. Only works when hosted by a `ModeManager`.
func _on_test_flight() -> void:
	var manager := get_parent() as ModeManager
	if manager == null:
		_set_status("Test flight needs ModeManager")
		return
	manager.switch_to(ModeManager.Mode.TACTICAL_COMBAT, design)


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
