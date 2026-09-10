class_name CommandBar
extends CanvasLayer
## Bottom command bar for the tactical mode. Hosts action toggles; for now it
## carries the fire-control module selector, which cycles
## None -> Mk1 -> Mk2 -> Mk3 and always shows the active module.

## Emitted when the player cycles the module (FireControl.Mode int: 0/1/2/3).
signal fire_control_mode_changed(mode: int)

## Emitted when the player toggles align-gated thrust (point-then-burn) on/off.
signal align_thrust_toggled(enabled: bool)

const _FIRE_CONTROL_LABELS := [
	"Fire Control: None",
	"Fire Control: Mk1",
	"Fire Control: Mk2",
	"Fire Control: Mk3",
]

@onready var _fire_control_button: Button = $Root/Bar/Margin/Buttons/FireControl
@onready var _align_thrust_button: Button = $Root/Bar/Margin/Buttons/AlignThrust

var _fire_control_mode: int = 0
var _align_thrust: bool = true


func _ready() -> void:
	_update_fire_control_label()
	_update_align_thrust_label()
	_fire_control_button.pressed.connect(_on_fire_control_pressed)
	_align_thrust_button.pressed.connect(_on_align_thrust_pressed)


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
