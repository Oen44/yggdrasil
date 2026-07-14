class_name YggdrasilLineData
extends Resource

enum LineType {
	STRAIGHT,
	BEZIER,
	ARC
}

@export var line_type: LineType = LineType.STRAIGHT
@export var curve_height: float = 48.0
@export var segments: int = 16
@export var reversed: bool = false
