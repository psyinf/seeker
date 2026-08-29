class_name VectorArrow
extends Node2D
## A directional arrow built from scene nodes (a Line2D shaft and a Polygon2D
## head). Orient it with `rotation` and size it with `length`; it points along
## local +X. No custom drawing.

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		_apply_color()
@export var width: float = 2.0:
	set(value):
		width = value
		if is_node_ready():
			_shaft.width = value
@export var head_size: float = 12.0:
	set(value):
		head_size = value
		_apply_head()

## Shaft length in pixels, from the origin to the arrow tip.
var length: float = 70.0:
	set(value):
		length = value
		_apply_length()

@onready var _shaft: Line2D = $Shaft
@onready var _head: Polygon2D = $Head


func _ready() -> void:
	_shaft.width = width
	_apply_color()
	_apply_head()
	_apply_length()


func _apply_length() -> void:
	if not is_node_ready():
		return
	_shaft.points = PackedVector2Array([Vector2.ZERO, Vector2(length, 0.0)])
	_head.position = Vector2(length, 0.0)


func _apply_head() -> void:
	if not is_node_ready():
		return
	_head.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(-head_size, -head_size * 0.5),
		Vector2(-head_size, head_size * 0.5),
	])


func _apply_color() -> void:
	if not is_node_ready():
		return
	_shaft.default_color = color
	_head.color = color
