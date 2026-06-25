@tool
class_name YggdrasilNodesService
extends YggdrasilBaseService

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")

signal node_created(node: YggdrasilNodeButton)
signal node_pressed(node: YggdrasilNodeButton)
signal node_hovered(node: YggdrasilNodeButton, is_hovered: bool)

var _nodes: Dictionary[int, YggdrasilNodeButton] = {}

func load_tree(tree_data: YggdrasilTree) -> void:
	_tree_data = tree_data
	
	for node_data in _tree_data.nodes:
		_create_node_from_data(node_data)

func delete_node(node: YggdrasilNodeButton) -> void:
	_nodes.erase(node.id)

func _build_node(node_type: YggdrasilNode.NodeType, icon_texture: Texture2D = null, border_texture: Texture2D = null) -> YggdrasilNodeButton:
	var node = _scene.instantiate()
	
	var node_size: Vector2 = _tree_data.get_node_size(node_type)
	node.size = node_size

	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon_texture:
		icon.texture = icon_texture
	else:
		icon.texture = Yggdrasil.BlankIcon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.add_child(icon)
	node.tree = _tree_data
	node.tree_view = _tree_view

	var border = TextureRect.new()
	border.name = "Border"
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	border.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.add_child(border)

	if border_texture:
		border.texture = border_texture
		border.size = node.size * _tree_data.border_scale
		border.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	
	node.node_hovered.connect(node_hovered.emit)

	return node

func _create_node_from_data(node_data: YggdrasilNode) -> YggdrasilNodeButton:
	var node = _build_node(node_data.type, node_data.icon, node_data.border_normal)
	node.node_data = node_data
	_tree_view.nodes_container.add_child(node)
	
	_position(node, node_data.position)
	
	node.id = node_data.id
	node.name = "Node_%d" % node.id
	
	_nodes[node.id] = node

	if node.is_root and _tree_data.allocation:
		node.set_state(Yggdrasil.AllocationState.INTERMEDIATE)
	else:
		node.set_state(Yggdrasil.AllocationState.NORMAL)

	node.pressed.connect(_on_node_pressed.bind(node))
	node_created.emit(node)

	return node

func create_node(position: Vector2, node_type: YggdrasilNode.NodeType) -> YggdrasilNodeButton:
	var node = _build_node(node_type)

	node.node_data = YggdrasilNode.new()
	
	node.id = _tree_data.get_next_id()
	node.name = "Node_%d" % node.id
	node.node_name = node.name
	node.type = node_type
	node.icon = Yggdrasil.BlankIcon
	node.tree = _tree_data
	node.tree_view = _tree_view
	_nodes[node.id] = node

	_tree_view.nodes_container.add_child(node)
	
	_position(node, position)

	node.node_data.position = _tree_view.translate_node_position(node)
	_tree_data.nodes.append(node.node_data)
	node.pressed.connect(_on_node_pressed.bind(node))
	node_created.emit(node)
	
	return node

func create_from_prefab(position: Vector2, prefab: YggdrasilPrefab) -> YggdrasilNodeButton:
	var node = _build_node(prefab.type, prefab.icon, prefab.border_normal)
	
	node.node_data = YggdrasilNode.new()

	node.id = _tree_data.get_next_id()
	node.name = "Node_%d" % node.id
	node.node_name = node.name
	node.type = prefab.type
	node.icon = prefab.icon
	node.border_normal = prefab.border_normal
	node.border_intermediate = prefab.border_intermediate
	node.border_active = prefab.border_active
	node.tree = _tree_data
	node.tree_view = _tree_view
	_nodes[node.id] = node

	_tree_view.nodes_container.add_child(node)
	
	_position(node, position)

	node.node_data.position = _tree_view.translate_node_position(node)
	_tree_data.nodes.append(node.node_data)
	node.pressed.connect(_on_node_pressed.bind(node))
	node_created.emit(node)

	node.node_name = prefab.node_name
	node.description = prefab.description
	node.attributes = prefab.attributes.duplicate(true)
	node.max_allocations = prefab.max_allocations

	if not prefab.reference_id.is_empty():
		node.prefab = prefab
		node.reference_id = prefab.reference_id
		prefab.add_node(node)
	
	return node

func _on_node_pressed(node: YggdrasilNodeButton):
	node_pressed.emit(node)

func duplicate_node(original_node: YggdrasilNodeButton) -> YggdrasilNodeButton:
	var node_data = YggdrasilNode.new()
	node_data.id = _tree_data.get_next_id()
	node_data.name = original_node.node_name
	node_data.description = original_node.description
	node_data.type = original_node.type
	node_data.icon = original_node.icon
	node_data.border_normal = original_node.border_normal
	node_data.border_intermediate = original_node.border_intermediate
	node_data.border_active = original_node.border_active
	node_data.attributes = original_node.attributes.duplicate(true)
	node_data.max_allocations = original_node.max_allocations

	var node = _build_node(node_data.type, node_data.icon, node_data.border_normal)

	if original_node.prefab:
		node_data.reference_id = original_node.reference_id
		node.prefab = original_node.prefab

	node.node_data = node_data

	_tree_view.nodes_container.add_child(node)
	_tree_data.nodes.append(node_data)

	_position(node, original_node.node_data.position + Vector2(20, 20))
	
	node.id = node_data.id
	node.name = "Node_%d" % node.id
	
	_nodes[node.id] = node

	node.pressed.connect(_on_node_pressed.bind(node))
	node_created.emit(node)

	if not node_data.reference_id.is_empty():
		var prefab = _tree_view.prefabs_service.get_prefab_by_reference_id(node_data.reference_id)
		node.prefab = prefab
		prefab.add_node(node)
	
	return node

func on_node_preallocated(node: YggdrasilNodeButton):
	if node.type == YggdrasilNode.NodeType.DECORATION:
		return
	
	node.set_state(Yggdrasil.AllocationState.PREALLOCATED_ACTIVE)

	var neighbors = node.out_nodes + node.in_nodes
	for neighbor_id in neighbors:
		var neighbor_node: YggdrasilNodeButton = _tree_view.nodes_service.get_node(neighbor_id)
		_refresh_node_state(neighbor_node)

func on_node_unpreallocated(node: YggdrasilNodeButton):
	if node.type == YggdrasilNode.NodeType.DECORATION:
		return
	
	if node.allocated:
		node.set_state(Yggdrasil.AllocationState.ACTIVE)
	else:
		node.set_state(Yggdrasil.AllocationState.INTERMEDIATE)

	var neighbors = node.out_nodes + node.in_nodes
	for neighbor_id in neighbors:
		var neighbor_node: YggdrasilNodeButton = _tree_view.nodes_service.get_node(neighbor_id)
		_refresh_node_state(neighbor_node)

func on_node_allocated(node: YggdrasilNodeButton):
	if node.type == YggdrasilNode.NodeType.DECORATION:
		return
	
	node.set_state(Yggdrasil.AllocationState.ACTIVE)

	var neighbors = node.out_nodes + node.in_nodes
	for neighbor_id in neighbors:
		var neighbor_node: YggdrasilNodeButton = get_node(neighbor_id)
		_refresh_node_state(neighbor_node)

func on_node_deallocated(node: YggdrasilNodeButton):
	if node.type == YggdrasilNode.NodeType.DECORATION:
		return
	
	if _tree_data.multiallocation:
		if node.allocation_level > 0:
			node.set_state(Yggdrasil.AllocationState.ACTIVE)
		else:
			node.set_state(Yggdrasil.AllocationState.INTERMEDIATE)
	else:
		node.set_state(Yggdrasil.AllocationState.INTERMEDIATE)

	var neighbors = node.out_nodes + node.in_nodes
	for neighbor_id in neighbors:
		var neighbor_node: YggdrasilNodeButton = get_node(neighbor_id)
		_refresh_node_state(neighbor_node)

func on_node_refund_added(node: YggdrasilNodeButton):
	if node.type == YggdrasilNode.NodeType.DECORATION:
		return

	node.set_state(Yggdrasil.AllocationState.REFUND)

	var neighbors = node.out_nodes + node.in_nodes
	for neighbor_id in neighbors:
		var neighbor_node: YggdrasilNodeButton = get_node(neighbor_id)
		_refresh_node_state(neighbor_node)

func on_node_refund_removed(node: YggdrasilNodeButton):
	if node.type == YggdrasilNode.NodeType.DECORATION:
		return

	node.set_state(Yggdrasil.AllocationState.ACTIVE)

	var neighbors = node.out_nodes + node.in_nodes
	for neighbor_id in neighbors:
		var neighbor_node: YggdrasilNodeButton = get_node(neighbor_id)
		_refresh_node_state(neighbor_node)

func _refresh_node_state(node: YggdrasilNodeButton):
	if node.type == YggdrasilNode.NodeType.DECORATION:
		return

	if node.preallocated:
		node.set_state(Yggdrasil.AllocationState.PREALLOCATED_ACTIVE)
		return

	if node.allocated:
		if node.refund:
			node.set_state(Yggdrasil.AllocationState.REFUND)
		else:
			node.set_state(Yggdrasil.AllocationState.ACTIVE)
		return

	var neighbors = node.out_nodes + node.in_nodes
	for neighbor_id in neighbors:
		var neighbor_node: YggdrasilNodeButton = get_node(neighbor_id)
		if neighbor_node.allocated and not neighbor_node.refund:
			node.set_state(Yggdrasil.AllocationState.INTERMEDIATE)
			return
		if neighbor_node.preallocated:
			node.set_state(Yggdrasil.AllocationState.PREALLOCATED_INTERMEDIATE)
			return

	node.set_state(Yggdrasil.AllocationState.NORMAL)

func get_node(node_id: int) -> YggdrasilNodeButton:
	return _nodes.get(node_id, null)
