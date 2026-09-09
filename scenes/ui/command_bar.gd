class_name CommandBar
extends CanvasLayer
## Bottom command bar for the tactical mode. Hosts action toggles; for now it
## carries the fire-control module selector, which cycles
## None -> Mk1 -> Mk2 -> Mk3 and always shows the active module.

## Emitted when the player cycles the module (FireControl.Mode int: 0/1/2/3).
signal fire_control_mode_changed(mode: int)

const _FIRE_CONTROL_LABELS := [
	"Fire Control: None",
	"Fire Control: Mk1",
	"Fire Control: Mk2",
	"Fire Control: Mk3",
]

@onready var _fire_control_button: Button = $Root/Bar/Margin/Buttons/FireControl

var _fire_control_mode: int = 0


func _ready() -> void:
	_update_fire_control_label()
	_fire_control_button.pressed.connect(_on_fire_control_pressed)


func _on_fire_control_pressed() -> void:
	_fire_control_mode = (_fire_control_mode + 1) % _FIRE_CONTROL_LABELS.size()
	_update_fire_control_label()
	fire_control_mode_changed.emit(_fire_control_mode)


func _update_fire_control_label() -> void:
	_fire_control_button.text = _FIRE_CONTROL_LABELS[_fire_control_mode]
