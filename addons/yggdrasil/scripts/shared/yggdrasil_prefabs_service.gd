@tool
class_name YggdrasilPrefabsService
extends YggdrasilBaseService

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")

signal prefab_created(prefab: YggdrasilPrefab)

var prefabs: Dictionary[YggdrasilNode.NodeType, Array] = {}
var _ref_id_to_prefab: Dictionary[String, YggdrasilPrefab] = {}

func load_tree(tree_data: YggdrasilTree) -> void:
	_tree_data = tree_data
	
	for node_type in _tree_data.prefabs.keys():
		prefabs[node_type] = []
		var prefabs_list = _tree_data.prefabs[node_type]
		for prefab in prefabs_list:
			prefabs[node_type].append(prefab)
			_ref_id_to_prefab[prefab.reference_id] = prefab
			prefab_created.emit(prefab)

	for node in _tree_view.nodes_container.get_children():
		if not node.reference_id.is_empty():
			var prefab = _ref_id_to_prefab.get(node.reference_id, null)
			if prefab:
				node.prefab = prefab
				prefab.add_node(node)

func create_prefab(node: YggdrasilNodeButton, is_copy: bool = false):
	var prefab = YggdrasilPrefab.new()
	prefab.type = node.type
	prefab.node_name = node.node_name
	prefab.description = node.description
	prefab.icon = node.icon
	prefab.border_normal = node.border_normal
	prefab.attributes = node.attributes.duplicate(true)
	prefab.max_allocations = node.max_allocations

	if not is_copy:
		prefab.reference_id = Yggdrasil.UUIDGenerator.v4()
		node.reference_id = prefab.reference_id
		node.prefab = prefab

	if not _tree_data.prefabs.has(node.type):
		_tree_data.prefabs[node.type] = []

	_tree_data.prefabs[node.type].append(prefab)
	_ref_id_to_prefab[prefab.reference_id] = prefab
	prefab.add_node(node)
	prefab_created.emit(prefab)

func make_unique(node: YggdrasilNodeButton) -> void:
	if not node.prefab:
		return
	
	node.prefab.remove_node(node)
	node.reference_id = ""
	node.prefab = null

func get_prefab_by_reference_id(reference_id: String) -> YggdrasilPrefab:
	return _ref_id_to_prefab.get(reference_id, null)
