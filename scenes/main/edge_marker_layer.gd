class_name EdgeMarkerLayer
extends CanvasLayer
## Screen-space overlay that pins directional markers to the viewport border,
## one per off-screen node in a tracked group, pointing where that node lies.
##
## This is the entry point of the edge-marker system: it reads the world (via a
## group, so it stays decoupled from whoever spawns the tracked nodes), converts
## each node to screen space through the camera, and drives a pool of reusable
## `EdgeMarker` primitives. To visualize another kind of thing, drop in a second
## layer pointed at a different group/color — no code changes needed.

## Nodes in this group get an edge marker while off-screen. Empty tracks nothing.
@export var target_group: StringName = &"targets"
## Fill color applied to every marker this layer spawns.
@export var marker_color: Color = Color("ff6b6b")
## Silhouette every marker this layer spawns uses.
@export var marker_shape: EdgeMarker.Shape = EdgeMarker.Shape.TRIANGLE
## Size passed to each marker, in pixels.
@export var marker_size: float = 14.0
## Inset from the viewport edge, in pixels, so markers are not clipped.
@export var margin: float = 28.0
## Only mark nodes within this world distance from the view center; 0 disables
## the range check and marks every off-screen node in the group.
@export var max_distance: float = 2200.0

## Reused marker nodes; grown on demand, hidden when not needed this frame.
var _pool: Array[EdgeMarker] = []


func _process(_delta: float) -> void:
	var tree := get_tree()
	if tree == null:
		_hide_from(0)
		return
	var nodes := tree.get_nodes_in_group(target_group)
	var viewport := get_viewport()
	var view_size := viewport.get_visible_rect().size
	var to_screen := viewport.get_canvas_transform()
	# Screen center in world space is the inverse-mapped center of the viewport.
	var view_center := to_screen.affine_inverse() * (view_size * 0.5)
	var half := view_size * 0.5 - Vector2(margin, margin)
	var used := 0
	for node in nodes:
		var node_2d := node as Node2D
		if node_2d == null or not node_2d.is_inside_tree():
			continue
		var world_pos := node_2d.global_position
		if max_distance > 0.0 and world_pos.distance_to(view_center) > max_distance:
			continue
		var screen_pos := to_screen * world_pos
		# On-screen nodes speak for themselves; only mark ones past the edge.
		if Rect2(Vector2.ZERO, view_size).has_point(screen_pos):
			continue
		var offset := screen_pos - view_size * 0.5
		if offset == Vector2.ZERO:
			continue
		var marker := _marker_at(used)
		marker.position = view_size * 0.5 + _clamp_to_border(offset, half)
		marker.rotation = offset.angle()
		marker.visible = true
		used += 1
	_hide_from(used)


## Scales `offset` so it lands on the inner border rectangle of half-size `half`
## (the nearest edge along its own direction), keeping the marker on-screen.
func _clamp_to_border(offset: Vector2, half: Vector2) -> Vector2:
	var scale := INF
	if not is_zero_approx(offset.x):
		scale = minf(scale, half.x / absf(offset.x))
	if not is_zero_approx(offset.y):
		scale = minf(scale, half.y / absf(offset.y))
	return offset * scale


## Returns the pooled marker at `index`, creating and styling it on first use.
func _marker_at(index: int) -> EdgeMarker:
	while index >= _pool.size():
		var marker := EdgeMarker.new()
		add_child(marker)
		_pool.append(marker)
	var m := _pool[index]
	m.color = marker_color
	m.shape = marker_shape
	m.marker_size = marker_size
	return m


## Hides pooled markers from `index` onward (unused this frame).
func _hide_from(index: int) -> void:
	for i in range(index, _pool.size()):
		_pool[i].visible = false
