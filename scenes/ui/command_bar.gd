class_name CommandBar
extends CanvasLayer
## Bottom command bar for the tactical mode. Hosts action toggles; for now it
## carries the fire-control module selector, which cycles
## None -> Mk1 -> Mk2 -> Mk3 and always shows the active module.

## Emitted when the player cycles the module (FireControl.Mode int: 0/1/2/3).
signal fire_control_mode_changed(mode: int)

## Emitted when the player toggles align-gated thrust (point-then-burn) on/off.
signal align_thrust_toggled(enabled: bool)

## Emitted when the player toggles sustained fire for a weapon group on/off.
signal group_fire_toggled(group: int, active: bool)

const _FIRE_CONTROL_LABELS := [
	"Fire Control: None",
	"Fire Control: Mk1",
	"Fire Control: Mk2",
	"Fire Control: Mk3",
]

## Fixed number of weapon firing groups the bar can trigger.
const GROUP_COUNT := 4

@onready var _fire_control_button: Button = $Root/Bar/Margin/Buttons/FireControl
@onready var _align_thrust_button: Button = $Root/Bar/Margin/Buttons/AlignThrust
@onready var _buttons: HBoxContainer = $Root/Bar/Margin/Buttons

var _fire_control_mode: int = 0
var _align_thrust: bool = true


func _ready() -> void:
	_update_fire_control_label()
	_update_align_thrust_label()
	_fire_control_button.pressed.connect(_on_fire_control_pressed)
	_align_thrust_button.pressed.connect(_on_align_thrust_pressed)
	_build_group_buttons()


## One sustained-fire toggle per firing group (fixed count). Selecting a group
## fires every weapon assigned to it.
func _build_group_buttons() -> void:
	for group in range(1, GROUP_COUNT + 1):
		var button := Button.new()
		button.toggle_mode = true
		button.text = "Fire G%d" % group
		button.toggled.connect(_on_group_toggled.bind(group))
		_buttons.add_child(button)


func _on_fire_control_pressed() -> void:
	_fire_control_mode = (_fire_control_mode + 1) % _FIRE_CONTROL_LABELS.size()
	_update_fire_control_label()
	fire_control_mode_changed.emit(_fire_control_mode)


func _on_align_thrust_pressed() -> void:
	_align_thrust = not _align_thrust
	_update_align_thrust_label()
	align_thrust_toggled.emit(_align_thrust)


func _update_fire_control_label() -> void:
	_fire_control_button.text = _FIRE_CONTROL_LABELS[_fire_control_mode]


func _update_align_thrust_label() -> void:
	_align_thrust_button.text = "Align Thrust: On" if _align_thrust else "Align Thrust: Off"


func _on_group_toggled(pressed: bool, group: int) -> void:
	group_fire_toggled.emit(group, pressed)
