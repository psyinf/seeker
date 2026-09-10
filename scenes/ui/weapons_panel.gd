class_name WeaponsPanel
extends CanvasLayer
## Top-right tactical HUD: one row per mounted weapon showing its name, a firing
## group selector (1..GROUPS), and a charge/readiness bar. Reads the ship's
## weapon accessors; group changes are pushed back with `set_weapon_group`. The
## command bar's group toggles decide which groups actually fire.

## The ship whose weapons to list.
@export var ship_path: NodePath
## Number of assignable firing groups (matches the command bar's toggles).
@export var group_count: int = 4

@onready var _ship := get_node_or_null(ship_path) as Ship

## Per-row widgets, indexed by weapon: charge bars and group selectors.
var _bars: Array[ProgressBar] = []
var _rows: VBoxContainer


func _ready() -> void:
	_build_ui()
	if _ship != null:
		_ship.weapons_changed.connect(_rebuild)
		_rebuild()


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.position = Vector2(-12, 12)
	panel.offset_left = -232.0
	panel.offset_right = -12.0
	panel.offset_top = 12.0
	add_child(panel)
	var col := VBoxContainer.new()
	panel.add_child(col)
	var title := Label.new()
	title.text = "Weapons"
	col.add_child(title)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 4)
	col.add_child(_rows)


## Rebuilds one row per weapon from the ship's current loadout.
func _rebuild() -> void:
	for child in _rows.get_children():
		child.queue_free()
	_bars.clear()
	if _ship == null:
		return
	for i in _ship.weapon_count():
		_add_row(i)


func _add_row(index: int) -> void:
	var row := VBoxContainer.new()
	row.custom_minimum_size = Vector2(210, 0)
	var header := HBoxContainer.new()
	row.add_child(header)
	var name_label := Label.new()
	name_label.text = _ship.weapon_label(index)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	var group_select := OptionButton.new()
	for group in range(1, group_count + 1):
		group_select.add_item("G%d" % group, group)
	group_select.select(group_select.get_item_index(_ship.weapon_group(index)))
	group_select.item_selected.connect(_on_group_selected.bind(index, group_select))
	header.add_child(group_select)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	row.add_child(bar)
	_bars.append(bar)
	_rows.add_child(row)


func _on_group_selected(_item: int, index: int, select: OptionButton) -> void:
	_ship.set_weapon_group(index, select.get_selected_id())


func _process(_delta: float) -> void:
	if _ship == null:
		return
	for i in _bars.size():
		var bar := _bars[i]
		bar.value = _ship.weapon_readiness(i) * 100.0
		bar.modulate = Color(0.7, 1.0, 0.7) if _ship.weapon_ready(i) else Color(1.0, 0.72, 0.5)
