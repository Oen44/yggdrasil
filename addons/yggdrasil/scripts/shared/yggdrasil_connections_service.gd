@tool
class_name YggdrasilConnectionsService
extends YggdrasilBaseService

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")

signal line_created(line: YggdrasilConnection, from_node_id: int, to_node_id: int)
signal line_disconnected(from_node: YggdrasilNodeButton, to_node: YggdrasilNodeButton)
signal node_connected(from_node: YggdrasilNodeButton, to_node_id: int)
signal node_disconnected(from_node: YggdrasilNodeButton, to_node_id: int)

func load_tree(tree_data: YggdrasilTree) -> void:
	_tree_data = tree_data

	for node_data in _tree_data.nodes:
		var node = _tree_view.nodes_service.get_node(node_data.id)
		for out_node_id in node_data.out_nodes:
			var target_node = _tree_view.nodes_service.get_node(out_node_id)
			var line = _scene.instantiate()
			line.name = "Line_%d_%d" % [node_data.id, out_node_id]
			line.texture = _tree_data.line_texture_normal
			line.texture_mode = Line2D.LINE_TEXTURE_TILE
			line.width = 16.0
			line.joint_mode = Line2D.LINE_JOINT_BEVEL
			
			var line_data = node_data.line_data.get(out_node_id, YggdrasilLineData.new())
			_connect_nodes(line, node, target_node, line_data)
			_tree_view.lines_container.add_child(line)
			if not _tree_data.revealed:
				line.visible = false
			line_created.emit(line, node_data.id, out_node_id)
			node_connected.emit(node, out_node_id)

func create_connection(from_node: YggdrasilNodeButton, to_node: YggdrasilNodeButton) -> void:
	var existing_line = _tree_view.lines_container.get_node_or_null("Line_%d_%d" % [from_node.id, to_node.id])
	if existing_line:
		from_node.line_data.erase(to_node.id)
		from_node.out_nodes.erase(to_node.id)
		to_node.in_nodes.erase(from_node.id)
		existing_line.queue_free()
		line_disconnected.emit(from_node, to_node)
		node_disconnected.emit(from_node, to_node.id)
		return

	var line = _scene.instantiate()
	line.name = "Line_%d_%d" % [from_node.id, to_node.id]
	line.texture = _tree_data.line_texture_normal
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line.width = 16.0
	line.joint_mode = Line2D.LINE_JOINT_BEVEL
	
	var line_data = YggdrasilLineData.new()
	line_data.line_type = YggdrasilLineData.LineType.STRAIGHT

	_connect_nodes(line, from_node, to_node, line_data)
	_tree_view.lines_container.add_child(line)

	from_node.line_data[to_node.id] = line_data

	from_node.out_nodes.append(to_node.id)
	to_node.in_nodes.append(from_node.id)
	line_created.emit(line, from_node.id, to_node.id)
	node_connected.emit(from_node, to_node.id)

func _connect_nodes(line: Line2D, node1: Control, node2: Control, line_data: YggdrasilLineData):
	line.position = _get_center_position(node1)
	match line_data.line_type:
		YggdrasilLineData.LineType.STRAIGHT:
			line.points = [Vector2.ZERO, _get_center_position(node2) - _get_center_position(node1)]
		YggdrasilLineData.LineType.BEZIER:
			var p0: Vector2 = Vector2.ZERO
			var p2: Vector2 = _get_center_position(node2) - _get_center_position(node1)

			if line_data.segments < 2 or line_data.curve_height < 0.01:
				line.points = [p0, p2]
				return

			var center: Vector2 = p2 * 0.5
			var len: float = p2.length()

			if len < 0.1:
				return

			var n: Vector2 = Vector2(-p2.y, p2.x) / len

			var p1: Vector2 = Vector2.ZERO
			if line_data.reversed:
				p1 = center - n * line_data.curve_height
			else:
				p1 = center + n * line_data.curve_height

			line.points = _bezier_points(line_data.segments, p0, p1, p2)
		YggdrasilLineData.LineType.ARC:
			var p0: Vector2 = Vector2.ZERO
			var p2: Vector2 = _get_center_position(node2) - _get_center_position(node1)

			if line_data.segments < 2:
				line.points = [p0, p2]
				return

			var chord: Vector2 = p2 - p0
			var diameter: float = chord.length()
			if diameter < 0.001:
				return

			var center: Vector2 = p2 * 0.5
			var radius: float = diameter * 0.5

			line.points = _arc_points(line_data.segments, center, line_data.reversed)

func _bezier_points(segments: int, p0: Vector2, p1: Vector2, p2: Vector2) -> PackedVector2Array:
	var pts = PackedVector2Array()
	pts.resize(segments + 1)
	
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var a = p0.lerp(p1, t)
		var b = p1.lerp(p2, t)
		pts[i] = a.lerp(b, t)
	
	return pts

func _arc_points(segments: int, center: Vector2, reversed: bool) -> PackedVector2Array:
	var pts = PackedVector2Array()
	pts.resize(segments + 1)

	var step: float = PI / float(segments)
	var sign = -1.0 if reversed else 1.0

	for i in range(segments + 1):
		var angle: float = sign * step * float(i)
		pts[i] = center + center.rotated(angle)
	
	return pts

func update_connected_lines(node: YggdrasilNodeButton):
	if node.type == YggdrasilNode.NodeType.DECORATION:
		return
	
	for node_id in node.out_nodes:
		var line: YggdrasilConnection = _tree_view.lines_container.get_node("Line_%d_%d" % [node.id, node_id])
		if line:
			var target_node = _tree_view.nodes_service.get_node(node_id)
			if target_node:
				line.clear_points()
				_connect_nodes(line, node, target_node, node.line_data[node_id])
	
	for node_id in node.in_nodes:
		var line: YggdrasilConnection = _tree_view.lines_container.get_node("Line_%d_%d" % [node_id, node.id])
		if line:
			var source_node = _tree_view.nodes_service.get_node(node_id)
			if source_node:
				line.clear_points()
				_connect_nodes(line, source_node, node, source_node.line_data[node.id])
	
func _get_center_position(node: Control) -> Vector2:
	return node.position + (node.size / 2)

func on_node_allocation_changed(node: YggdrasilNodeButton):
	if node.type == YggdrasilNode.NodeType.DECORATION:
		return

	var neighbors = node.out_nodes + node.in_nodes
	for neighbor_id in neighbors:
		var neighbor_node: YggdrasilNodeButton = _tree_view.nodes_service.get_node(neighbor_id)
		_refresh_line_state(node.id, neighbor_id, node.out_nodes.has(neighbor_id))

func _refresh_line_state(node_id: int, neighbor_id: int, is_out: bool):
	var from_id = node_id if is_out else neighbor_id
	var to_id = neighbor_id if is_out else node_id
	var line: YggdrasilConnection = _tree_view.lines_container.get_node("Line_%d_%d" % [from_id, to_id])

	var from_node: YggdrasilNodeButton = _tree_view.nodes_service.get_node(from_id)
	var to_node: YggdrasilNodeButton = _tree_view.nodes_service.get_node(to_id)

	var from_active = from_node.allocated and not from_node.refund or from_node.preallocated
	var to_active = to_node.allocated and not to_node.refund
	if _tree_data.multiallocation:
		if from_node.refund:
			from_active = from_node.allocation_level > 1
		else:
			from_active = from_node.preallocated or from_node.allocated

	if from_active and to_active:
		line.texture = _tree_data.line_texture_active
		line.visible = true
	elif from_active or to_active:
		line.texture = _tree_data.line_texture_intermediate
		line.visible = true
	else:
		line.texture = _tree_data.line_texture_normal
		if not _tree_data.revealed:
			line.visible = false
