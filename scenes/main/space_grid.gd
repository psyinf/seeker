class_name SpaceGrid
extends CanvasLayer
## A world-fixed reference grid rendered by a shader on a full-screen ColorRect,
## kept behind the gameplay layer. Follows the camera so free-flight motion reads
## against otherwise empty space. Assumes camera zoom of 1.

## The camera the grid tracks.
@export var camera_path: NodePath
@export var grid_spacing: float = 128.0:
	set(value):
		grid_spacing = value
		_push_params()
@export var grid_color: Color = Color(1.0, 1.0, 1.0, 0.06):
	set(value):
		grid_color = value
		_push_params()
@export var line_width: float = 1.0:
	set(value):
		line_width = value
		_push_params()

@onready var camera := get_node_or_null(camera_path) as Camera2D
@onready var _mat: ShaderMaterial = $Grid.material


func _ready() -> void:
	_push_params()


func _process(_delta: float) -> void:
	if camera == null:
		return
	var offset := camera.global_position - get_viewport().get_visible_rect().size * 0.5
	_mat.set_shader_parameter("world_offset", offset)


func _push_params() -> void:
	if not is_node_ready():
		return
	_mat.set_shader_parameter("grid_spacing", grid_spacing)
	_mat.set_shader_parameter("grid_color", grid_color)
	_mat.set_shader_parameter("line_width", line_width)
