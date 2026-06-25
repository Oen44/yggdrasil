@tool
class_name YggdrasilPrefab
extends Resource

signal name_changed(prefab: YggdrasilPrefab)
signal description_changed(prefab: YggdrasilPrefab)
signal icon_changed(prefab: YggdrasilPrefab)
signal border_changed(prefab: YggdrasilPrefab)
signal attribute_changed(prefab: YggdrasilPrefab, attribute_id: String, removed: bool)
signal max_allocations_changed(prefab: YggdrasilPrefab)

@export_storage var reference_id: String # If empty then this is a copy, otherwise it's a prefab that shares data with referenced nodes
@export_storage var id: String
@export_storage var node_name: String
@export_storage var description: String
@export_storage var type: YggdrasilNode.NodeType
@export_storage var icon: Texture2D
@export_storage var border_normal: Texture2D
@export_storage var border_intermediate: Texture2D
@export_storage var border_active: Texture2D
@export_storage var attributes # : Dictionary[String, Array] "id" => [value1, value2, ...]
@export_storage var max_allocations: int

var nodes: Array[YggdrasilNodeButton] = []

func _init():
	attributes = {}

func add_node(node: YggdrasilNodeButton) -> void:
	nodes.append(node)

func remove_node(node: YggdrasilNodeButton) -> void:
	nodes.erase(node)

func set_node_name(new_name: String) -> void:
	node_name = new_name
	id = new_name.to_snake_case()
	name_changed.emit(self)

func set_description(new_description: String) -> void:
	description = new_description
	description_changed.emit(self)

func set_icon(new_icon: Texture2D) -> void:
	icon = new_icon
	icon_changed.emit(self)

func set_border_normal(new_border: Texture2D) -> void:
	border_normal = new_border
	border_changed.emit(self)

func set_border_intermediate(new_border: Texture2D) -> void:
	border_intermediate = new_border
	border_changed.emit(self)

func set_border_active(new_border: Texture2D) -> void:
	border_active = new_border
	border_changed.emit(self)

func set_attribute(attribute_id: String, values: Array) -> void:
	attributes[attribute_id] = values
	attribute_changed.emit(self, attribute_id, false)

func remove_attribute(attribute_id: String) -> void:
	attributes.erase(attribute_id)
	attribute_changed.emit(self, attribute_id, true)

# Value must be int or float
func set_attribute_value(attribute_id: String, index: int, value: Variant) -> void:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		push_error("Value is of type %s, expected int or float (attribute_id=%s)" % [type_string(typeof(value)), attribute_id])
		return
	
	if not attributes.has(attribute_id):
		return
	
	var values = attributes[attribute_id]
	if index < 0 or index >= values.size():
		return
	
	values[index] = value
	attribute_changed.emit(self, attribute_id, false)

func set_max_allocations(new_max: int) -> void:
	max_allocations = new_max
	max_allocations_changed.emit(self)
