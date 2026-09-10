extends Node2D
## Top overlay for the ship design editor: highlights the hovered cell and shows
## the placement facing arrow. Pure drawing; the parent editor owns all state and
## calls `queue_redraw()` when the hover or facing changes.

var editor: Node = null


func _draw() -> void:
	if editor == null or not editor.has_hover:
		return
	var cs: float = editor.design.cell_size
	var center := Vector2(editor.hover_cell) * cs
	var half := cs * 0.5
	var rect := Rect2(center - Vector2(half, half), Vector2(cs, cs))
	var occupied := editor.design.get_segment_at(editor.hover_cell) != null
	var color := Color("ffd166") if not occupied else Color("ff6b6b")
	draw_rect(rect, color, false, 2.0)
	if ShipSegment.is_directional(editor.selected_kind) and not occupied:
		_draw_facing(center, editor.place_facing_dir(), half)


func _draw_facing(center: Vector2, dir: Vector2, half: float) -> void:
	var tip := center + dir * half * 0.8
	var side := Vector2(-dir.y, dir.x)
	var points := PackedVector2Array([
		tip,
		center - dir * half * 0.2 + side * half * 0.35,
		center - dir * half * 0.2 - side * half * 0.35,
	])
	draw_colored_polygon(points, Color("ffd166"))
