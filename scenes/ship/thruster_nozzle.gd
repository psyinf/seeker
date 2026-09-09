@tool
class_name ThrusterNozzle
extends Resource
## One thruster mount as data: where it sits on the hull, which way it expels
## gas (the reaction force pushes the opposite way), how big its plume draws, and
## which flight commands fire it. A `Resource`, so it serializes into a
## `PropulsionConfig` and can be authored in the inspector or saved/loaded.

## Command channels that can fire a nozzle. Values are bit flags so a nozzle can
## respond to several at once; they match the order of the `channels` export.
enum Channel {
	MAIN = 1,        ## the main-engine throttle (forward thrust)
	ROTATION = 2,    ## the rotation command, when this nozzle's torque matches its sign
	TRANSLATION = 4, ## the translation command (retro-burn), when its reaction force helps
}

## Mount position in the ship's local space, in pixels.
@export var position: Vector2 = Vector2.ZERO
## Unit direction the nozzle expels gas; the reaction force on the hull is the opposite.
@export var direction: Vector2 = Vector2.DOWN
## Plume length at full command, in pixels.
@export var length: float = 16.0
## Plume width at its base, in pixels.
@export var width: float = 6.0
## Bright core color of the plume.
@export var inner_color: Color = Color(0.85, 0.96, 1.0)
## Outer flare color of the plume.
@export var outer_color: Color = Color(0.42, 0.72, 1.0, 0.7)
## Which `Channel` flags fire this nozzle.
@export_flags("Main", "Rotation", "Translation") var channels: int = Channel.ROTATION | Channel.TRANSLATION
