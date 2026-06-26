class_name YggdrasilNode
extends Resource

enum NodeType {
	SMALL,
	MEDIUM,
	LARGE,
	DECORATION
}

@export_storage var is_root: bool
@export_storage var reference_id: String
@export_storage var id: int
@export_storage var external_id: String
@export_storage var name: String
@export_storage var description: String

@export_storage var type: NodeType
@export_storage var icon: Texture2D
@export_storage var border_normal: Texture2D
@export_storage var border_intermediate: Texture2D
@export_storage var border_active: Texture2D

@export_storage var position: Vector2

@export_storage var line_data # : Dictionary[int, YggdrasilLineData] Each outgoing connection can have its own line data
@export_storage var out_nodes # : Array[int] # Connection from this to other nodes
@export_storage var in_nodes # : Array[int] # Connection from other nodes to this

@export_storage var attributes # : Dictionary[String, Array]

@export_storage var max_allocations: int

# Editor-only properties
@export_storage var locked: bool

func _init():
	line_data = {}
	out_nodes = []
	in_nodes = []
	attributes = {}
	max_allocations = 1

func get_attribute_value(attribute_id: String) -> Array:
	return attributes.get(attribute_id, [])
