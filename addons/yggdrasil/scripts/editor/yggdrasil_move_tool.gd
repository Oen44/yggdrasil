@tool
class_name YggdrasilMoveTool
extends Control

signal moved(positions: Array[Vector2])
signal released(positions: Array[Vector2], start_positions: Array[Vector2])

const MOVE_HANDLE_DISTANCE: float = 25.0

var _dragging = false
var _drag_start_mouse: Vector2
var _node_start_pos: Array[Vector2] = []
var _positions: Array[Vector2]
var nodes: Array[YggdrasilNodeButton] = []

func _process(delta):
	queue_redraw()

func _draw():
	if nodes.is_empty():
		return
	
	var parent: Control = get_parent()
	var move_factor: Vector2 = Vector2(MOVE_HANDLE_DISTANCE, MOVE_HANDLE_DISTANCE)

	var points = [
		Vector2(move_factor.x / parent.offset_transform_scale.x, 5 / parent.offset_transform_scale.y),
		Vector2(move_factor.x / parent.offset_transform_scale.x, -5 / parent.offset_transform_scale.y),
		Vector2(move_factor.x / parent.offset_transform_scale.x + 10 / parent.offset_transform_scale.x, 0),
	]

	draw_colored_polygon(points, get_theme_color("axis_x_color", &"Editor"))
	draw_line(Vector2.ZERO, Vector2(move_factor.x / parent.offset_transform_scale.x, 0), get_theme_color("axis_x_color", &"Editor"))

	points.clear()
	points.push_back(Vector2(5 / parent.offset_transform_scale.x, move_factor.y / parent.offset_transform_scale.y))
	points.push_back(Vector2(-5 / parent.offset_transform_scale.x, move_factor.y / parent.offset_transform_scale.y))
	points.push_back(Vector2(0, move_factor.y / parent.offset_transform_scale.y + 10 / parent.offset_transform_scale.y))

	draw_colored_polygon(points, get_theme_color("axis_y_color", &"Editor"))
	draw_line(Vector2.ZERO, Vector2(0, move_factor.y / parent.offset_transform_scale.y), get_theme_color("axis_y_color", &"Editor"))

func input(event):
	if nodes.is_empty():
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			if _dragging:
				_drag_start_mouse = event.position
				_node_start_pos.clear()
				for node in nodes:
					_node_start_pos.append(node.position)
			else:
				if _drag_start_mouse != event.position:
					released.emit(_positions, _node_start_pos)
	
	if event is InputEventMouseMotion and _dragging:
		_positions = []
		for i in range(nodes.size()):
			var new_pos = _node_start_pos[i] + (event.position - _drag_start_mouse) / get_parent().offset_transform_scale
			_positions.append(new_pos)
		moved.emit(_positions)
