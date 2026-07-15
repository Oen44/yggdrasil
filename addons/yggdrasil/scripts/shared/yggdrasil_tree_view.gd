@tool
class_name YggdrasilTreeView
extends Control

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")

signal decoration_created(decoration: YggdrasilNode)
signal node_created(node: YggdrasilNode)
signal node_allocated(node: YggdrasilNode)
signal node_deallocated(node: YggdrasilNode)
signal prefab_created(prefab: YggdrasilPrefab)
signal line_created(line: YggdrasilConnection, from_node_id: int, to_node_id: int)
signal tree_version_mismatch(tree: YggdrasilTree, saved_version: int)

var main_container: Control
var background_container: Control
var decorations_container: Control
var lines_container: Control
var nodes_container: Control

var camera: YggdrasilCamera

var decorations_service: YggdrasilDecorationsService
var nodes_service: YggdrasilNodesService
var connections_service: YggdrasilConnectionsService
var prefabs_service: YggdrasilPrefabsService
var allocation_service: YggdrasilAllocationService

var _tooltip_scene: PackedScene
var _tooltip: YggdrasilTooltip

var _tree_data: YggdrasilTree

func load_tree(tree_data: YggdrasilTree, decoration_scene: PackedScene, node_scene: PackedScene, line_scene: PackedScene, tooltip_scene: PackedScene) -> void:
	_tree_data = tree_data

	if _tree_data.tree_state.version != _tree_data.version:
		tree_version_mismatch.emit(_tree_data, _tree_data.tree_state.version)

	_tooltip_scene = tooltip_scene

	_create_containers()
	_create_background()
	_create_camera()
	_create_services(decoration_scene, node_scene, line_scene)

func _create_containers() -> void:
	main_container = Control.new()
	main_container.name = "MainContainer"
	main_container.mouse_filter = MOUSE_FILTER_IGNORE
	main_container.set_size(_tree_data.size)
	main_container.set_anchors_and_offsets_preset(PRESET_CENTER, PRESET_MODE_KEEP_SIZE)

	background_container = Control.new()
	background_container.name = "BackgroundContainer"
	background_container.mouse_filter = MOUSE_FILTER_IGNORE
	background_container.set_anchors_preset(PRESET_FULL_RECT)
	main_container.add_child(background_container)

	decorations_container = Control.new()
	decorations_container.name = "DecorationsContainer"
	decorations_container.mouse_filter = MOUSE_FILTER_IGNORE
	decorations_container.set_anchors_preset(PRESET_FULL_RECT)
	main_container.add_child(decorations_container)

	lines_container = Control.new()
	lines_container.name = "LinesContainer"
	lines_container.mouse_filter = MOUSE_FILTER_IGNORE
	lines_container.set_anchors_preset(PRESET_FULL_RECT)
	main_container.add_child(lines_container)

	nodes_container = Control.new()
	nodes_container.name = "NodesContainer"
	nodes_container.mouse_filter = MOUSE_FILTER_IGNORE
	nodes_container.set_anchors_preset(PRESET_FULL_RECT)
	main_container.add_child(nodes_container)
	
	add_child(main_container)

func _create_background():
	var color_rect = ColorRect.new()
	color_rect.name = "BackgroundColor"
	color_rect.color = _tree_data.bg_color
	color_rect.mouse_filter = MOUSE_FILTER_IGNORE
	color_rect.set_anchors_preset(PRESET_FULL_RECT)
	background_container.add_child(color_rect)

	var texture_rect = TextureRect.new()
	texture_rect.name = "BackgroundTexture"
	texture_rect.texture = _tree_data.bg_texture
	texture_rect.stretch_mode = TextureRect.STRETCH_TILE
	texture_rect.mouse_filter = MOUSE_FILTER_IGNORE
	texture_rect.set_anchors_preset(PRESET_FULL_RECT)
	background_container.add_child(texture_rect)

func _create_camera() -> void:
	camera = YggdrasilCamera.new()
	camera.set_viewport(main_container)
	var half_size = _tree_data.size / 2
	camera.set_bounds(Rect2(-half_size, half_size))

func _create_services(decoration_scene: PackedScene, node_scene: PackedScene, line_scene: PackedScene):
	decorations_service = YggdrasilDecorationsService.new(self)
	decorations_service.decoration_created.connect(decoration_created.emit)
	decorations_service.set_scene(decoration_scene)
	decorations_service.load_tree(_tree_data)

	nodes_service = YggdrasilNodesService.new(self)
	nodes_service.node_created.connect(node_created.emit)
	nodes_service.node_hovered.connect(_on_node_hovered)
	nodes_service.set_scene(node_scene)
	nodes_service.load_tree(_tree_data)

	connections_service = YggdrasilConnectionsService.new(self)
	connections_service.line_created.connect(line_created.emit)
	connections_service.set_scene(line_scene)
	connections_service.load_tree(_tree_data)

	prefabs_service = YggdrasilPrefabsService.new(self)
	prefabs_service.prefab_created.connect(prefab_created.emit)
	prefabs_service.load_tree(_tree_data)

	allocation_service = YggdrasilAllocationService.new(self)
	
	allocation_service.node_preallocated.connect(nodes_service.on_node_preallocated)
	allocation_service.node_unpreallocated.connect(nodes_service.on_node_unpreallocated)
	allocation_service.node_allocated.connect(nodes_service.on_node_allocated)
	allocation_service.node_deallocated.connect(nodes_service.on_node_deallocated)
	allocation_service.node_refund_added.connect(nodes_service.on_node_refund_added)
	allocation_service.node_refund_removed.connect(nodes_service.on_node_refund_removed)

	allocation_service.node_preallocated.connect(connections_service.on_node_allocation_changed)
	allocation_service.node_unpreallocated.connect(connections_service.on_node_allocation_changed)
	allocation_service.node_allocated.connect(connections_service.on_node_allocation_changed)
	allocation_service.node_deallocated.connect(connections_service.on_node_allocation_changed)
	allocation_service.node_refund_added.connect(connections_service.on_node_allocation_changed)
	allocation_service.node_refund_removed.connect(connections_service.on_node_allocation_changed)
	
	allocation_service.node_allocated.connect(_on_node_allocated)
	allocation_service.node_deallocated.connect(_on_node_deallocated)

	allocation_service.load_tree(_tree_data)
	if _tree_data.allocation and not Engine.is_editor_hint():
		nodes_service.node_pressed.connect(allocation_service.on_node_pressed)

func _gui_input(event):
	if not is_visible_in_tree() or not _tree_data:
		return
	
	camera.input(event)

func _on_node_hovered(node: YggdrasilNodeButton, is_hovered: bool):
	if is_hovered:
		if node.type != YggdrasilNode.NodeType.DECORATION:
			if not _tooltip:
				_tooltip = _tooltip_scene.instantiate()
				add_child(_tooltip)
			_tooltip.show()
			_tooltip.reset_size()
			_tooltip.inspect(node)
			_tooltip.set_global_position(node.get_global_position() + node.size / 2)
	else:
		if _tooltip:
			_tooltip.hide()
			_tooltip.reset()

func _on_node_allocated(node: YggdrasilNodeButton):
	if _tooltip and _tooltip.visible:
		_tooltip.reset_size()
		_tooltip.inspect(node)

	node_allocated.emit(node)

func _on_node_deallocated(node: YggdrasilNodeButton):
	if _tooltip and _tooltip.visible:
		_tooltip.reset_size()
		_tooltip.inspect(node)
	
	node_deallocated.emit(node)

func get_local_space() -> Transform2D:
	return main_container.get_global_transform().affine_inverse() * get_global_transform()

func translate_node_position(node: Control) -> Vector2:
	return node.position - (_tree_data.size / 2) + (node.size / 2)

func translate_position(pos: Vector2) -> Vector2:
	return pos - (_tree_data.size / 2)

func get_mouse_position_in_tree() -> Vector2:
	return translate_position(main_container.get_local_mouse_position())

func get_tree_data() -> YggdrasilTree:
	return _tree_data
