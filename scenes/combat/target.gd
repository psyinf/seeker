@tool
class_name Target
extends Area2D
## A free-floating practice target the player can shoot. It sits on the "targets"
## collision layer only, so turret bolts detect it but the ship (which has no
## physics body) flies straight through — targets never block movement. It draws
## itself (@tool), flashes when struck, and frees itself once its hit points run
## out, announcing the kill via `destroyed`.

## Emitted when the target is destroyed, carrying its world position (for FX/score).
signal destroyed(at: Vector2)

## Radius of the target ring, in pixels.
@export var radius: float = 16.0:
	set(value):
		radius = value
		queue_redraw()

## Hits the target can take before it is destroyed.
@export_range(1, 20, 1) var hit_points: int = 3

## Ring color while healthy.
@export var ring_color: Color = Color("ff6b6b"):
	set(value):
		ring_color = value
		queue_redraw()

## Color flashed briefly when struck.
@export var flash_color: Color = Color("fff4c2"):
	set(value):
		flash_color = value
		queue_redraw()

## Seconds the hit flash lasts.
@export var flash_time: float = 0.08

var _remaining: int = 0
var _flash: float = 0.0


func _ready() -> void:
	_remaining = hit_points
	if not Engine.is_editor_hint():
		# Match the shape to the drawn radius so hit detection lines up with visuals.
		var shape := $CollisionShape2D as CollisionShape2D
		if shape != null and shape.shape is CircleShape2D:
			(shape.shape as CircleShape2D).radius = radius


## Called by a bolt on impact; flashes, decrements HP, and dies at zero.
func hit() -> void:
	_flash = flash_time
	_remaining -= 1
	queue_redraw()
	if _remaining <= 0:
		destroyed.emit(global_position)
		queue_free()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
		if _flash == 0.0:
			queue_redraw()


func _draw() -> void:
	var color := flash_color if _flash > 0.0 else ring_color
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, color, 2.0, true)
	# Crosshair ticks so the target reads as something to aim at.
	var tick := radius * 0.5
	draw_line(Vector2(-radius, 0.0), Vector2(-radius + tick, 0.0), color, 2.0, true)
	draw_line(Vector2(radius, 0.0), Vector2(radius - tick, 0.0), color, 2.0, true)
	draw_line(Vector2(0.0, -radius), Vector2(0.0, -radius + tick), color, 2.0, true)
	draw_line(Vector2(0.0, radius), Vector2(0.0, radius - tick), color, 2.0, true)
	draw_circle(Vector2.ZERO, 2.0, color)
