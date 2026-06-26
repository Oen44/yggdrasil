@tool
class_name YggdrasilDecorationsService
extends YggdrasilBaseService

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")

signal decoration_created(decoration: YggdrasilNodeButton)
signal decoration_pressed(node: YggdrasilNodeButton)

func load_tree(tree_data: YggdrasilTree) -> void:
	_tree_data = tree_data

	for decoration_data in tree_data.decorations:
		var node = _scene.instantiate()

		node.node_data = decoration_data
		node.size = node.icon.get_size()

		var icon = TextureRect.new()
		icon.name = "Icon"
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = node.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		node.add_child(icon)

		_position(node, decoration_data.position)

		_tree_view.decorations_container.add_child(node)
		decoration_created.emit(node)
		node.pressed.connect(_on_node_pressed.bind(node))

func create_decoration(at_position: Vector2) -> YggdrasilNodeButton:
	var node = _scene.instantiate()
	node.node_data = YggdrasilNode.new()
	node.id = _tree_data.get_next_id()
	node.name = "Decoration_%d" % node.id
	node.type = YggdrasilNode.NodeType.DECORATION
	node.icon = Yggdrasil.BlankIcon
	node.size = node.icon.get_size()

	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = node.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.add_child(icon)

	_position(node, at_position)

	node.node_data.position = _tree_view.translate_node_position(node)

	_tree_view.decorations_container.add_child(node)

	node.pressed.connect(_on_node_pressed.bind(node))

	_tree_data.decorations.append(node.node_data)

	decoration_created.emit(node)
	return node

func create_from_prefab(position: Vector2, prefab: YggdrasilPrefab) -> void:
	var node = _scene.instantiate()
	node.node_data = YggdrasilNode.new()

	if not prefab.reference_id.is_empty():
		node.prefab = prefab
		node.reference_id = prefab.reference_id
		prefab.add_node(node)
	
	node.type = prefab.type
	node.icon = prefab.icon
	node.size = node.icon.get_size()

	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = prefab.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.add_child(icon)

	_position(node, position)
	node.node_data.position = _tree_view.translate_node_position(node)

	_tree_view.decorations_container.add_child(node)
	node.pressed.connect(_on_node_pressed.bind(node))
	
	decoration_created.emit(node)

func _on_node_pressed(node: YggdrasilNodeButton):
	decoration_pressed.emit(node)

func delete_decoration(node: YggdrasilNodeButton) -> void:
	_tree_view.decorations_container.remove_child(node)

func restore_decoration(node: YggdrasilNodeButton) -> void:
	_tree_view.decorations_container.add_child(node)
	_tree_data.decorations.append(node.node_data)
	decoration_created.emit(node)
