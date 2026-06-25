@tool
class_name YggdrasilTree
extends Resource

@export_storage var version: int = 1
@export_storage var id: String
@export_storage var name: String
@export_storage var revealed: bool = true
@export_storage var allocation: bool = true
@export_storage var preallocation: bool = true
@export_storage var multiallocation: bool = false

@export_group("Visuals")
@export_storage var size: Vector2 = Vector2(5000, 5000)
@export_storage var bg_color: Color = Color(0.1, 0.1, 0.1)
@export_storage var bg_texture: Texture2D
@export_storage var line_texture_normal: Texture2D
@export_storage var line_texture_intermediate: Texture2D
@export_storage var line_texture_active: Texture2D

@export_storage var id_counter: int = 0
@export_storage var border_scale: float = 1.5
@export_storage var icon_sizes # : Dictionary[YggdrasilNode.NodeType, Vector2]
@export_storage var icons # : Dictionary[YggdrasilNode.NodeType, Texture2D]
@export_storage var node_size # : Dictionary[YggdrasilNode.NodeType, Vector2]
@export_storage var nodes # : Array[YggdrasilNode]
@export_storage var decorations # : Array[YggdrasilNode]
@export_storage var prefabs # : Dictionary[YggdrasilNode.NodeType, Array]
@export_storage var attributes # : Dictionary[String, YggdrasilAttribute]

var tree_state: YggdrasilTreeState

func _init():
	nodes = []
	decorations = []
	prefabs = {}
	attributes = {}
	icon_sizes = {
		YggdrasilNode.NodeType.SMALL: Vector2.ZERO,
		YggdrasilNode.NodeType.MEDIUM: Vector2.ZERO,
		YggdrasilNode.NodeType.LARGE: Vector2.ZERO
	}
	icons = {
		YggdrasilNode.NodeType.SMALL: null,
		YggdrasilNode.NodeType.MEDIUM: null,
		YggdrasilNode.NodeType.LARGE: null
	}
	node_size = {
		YggdrasilNode.NodeType.SMALL: Vector2(27, 27),
		YggdrasilNode.NodeType.MEDIUM: Vector2(48, 48),
		YggdrasilNode.NodeType.LARGE: Vector2(64, 64)
	}
	tree_state = YggdrasilTreeState.new()

func get_node_size(node_type: YggdrasilNode.NodeType) -> Vector2:
	return node_size.get(node_type, Vector2.ZERO)

func get_next_id() -> int:
	id_counter += 1
	return id_counter
