@tool
class_name YggdrasilNodeButton
extends BaseButton

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")

signal node_hovered(node: YggdrasilNodeButton, is_hovered: bool)

var tree: YggdrasilTree
var tree_view: YggdrasilTreeView

var node_data: YggdrasilNode
var prefab: YggdrasilPrefab
var is_mouse_over: bool = false
var preallocated: bool = false
var refund: bool = false
var allocated: bool = false
var allocation_level: int = 0
var state: Yggdrasil.AllocationState = Yggdrasil.AllocationState.NORMAL

var is_root: bool:
	get:
		return node_data.is_root
	set(value):
		node_data.is_root = value

var id: int:
	get:
		return node_data.id
	set(value):
		node_data.id = value

var reference_id: String:
	get:
		return node_data.reference_id
	set(value):
		node_data.reference_id = value

var node_name: String:
	get:
		return node_data.name
	set(value):
		node_data.name = value

var description: String:
	get:
		return node_data.description
	set(value):
		node_data.description = value

var type: YggdrasilNode.NodeType:
	get:
		return node_data.type
	set(value):
		node_data.type = value

var icon: Texture2D:
	get:
		return node_data.icon
	set(value):
		node_data.icon = value

var border_normal: Texture2D:
	get:
		return node_data.border_normal
	set(value):
		node_data.border_normal = value

var border_intermediate: Texture2D:
	get:
		return node_data.border_intermediate
	set(value):
		node_data.border_intermediate = value

var border_active: Texture2D:
	get:
		return node_data.border_active
	set(value):
		node_data.border_active = value

var out_nodes: Array:
	get:
		return node_data.out_nodes
	set(value):
		node_data.out_nodes = value

var in_nodes: Array:
	get:
		return node_data.in_nodes
	set(value):
		node_data.in_nodes = value

var line_data: Dictionary:
	get:
		return node_data.line_data
	set(value):
		node_data.line_data = value

var attributes: Dictionary:
	get:
		return node_data.attributes
	set(value):
		node_data.attributes = value

var locked: bool:
	get:
		return node_data.locked
	set(value):
		node_data.locked = value

var max_allocations: int:
	get:
		return node_data.max_allocations
	set(value):
		node_data.max_allocations = value

func _ready():
	button_mask = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT
	mouse_filter = MOUSE_FILTER_PASS
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _gui_input(event):
	if not is_visible_in_tree():
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and (button_mask & MOUSE_BUTTON_MASK_LEFT):
			if not event.pressed and is_mouse_over:
				pressed.emit()
			get_viewport().set_input_as_handled()

func _on_mouse_entered():
	is_mouse_over = true
	node_hovered.emit(self, true)

func _on_mouse_exited():
	is_mouse_over = false
	node_hovered.emit(self, false)

func format_tooltip():
	var regex = RegEx.new()
	regex.compile('#')

	var str = ""

	if tree.multiallocation:
		str = "[b][color=#f9e6ca]%s[/color][/b] (%d/%d)\n\n" % [node_name, allocation_level, max_allocations]
	else:
		str = "[b][color=#f9e6ca]%s[/color][/b]\n\n" % node_name

	for attr_id in attributes.keys():
		var attribute: YggdrasilAttribute = tree.attributes[attr_id]
		var matches = regex.search_all(attribute.effect)
		if matches.size() != attribute.value_count:
			push_error("Attribute (id=%s) effect string has mismatched number (found=%d, expected=%d) of placeholders (char=#) for attribute values." % [attribute.id, matches.size(), attribute.value_count])
			continue
		
		var tooltip = attribute.effect
		for i in attribute.value_count:
			var value = attributes[attr_id][i]
			tooltip = regex.sub(tooltip, str(value))
		str += "[color=#8a8aff]%s[/color]\n" % tooltip

	if not description.is_empty():
		str += "\n[color=orange]%s[/color]" % description

	str = str.strip_edges()
	return str

func set_state(new_state: Yggdrasil.AllocationState):
	state = new_state

	match state:
		Yggdrasil.AllocationState.NORMAL:
			_update_border(border_normal)
			if not tree.revealed:
				visible = false
		Yggdrasil.AllocationState.INTERMEDIATE:
			_update_border(border_intermediate)
			visible = true
		Yggdrasil.AllocationState.ACTIVE:
			_update_border(border_active)
			visible = true
		Yggdrasil.AllocationState.PREALLOCATED_INTERMEDIATE:
			_update_border(border_intermediate)
			visible = true
		Yggdrasil.AllocationState.PREALLOCATED_ACTIVE:
			_update_border(border_active, Color(1, 0.8, 0))
			visible = true
		Yggdrasil.AllocationState.REFUND:
			_update_border(border_active, Color(1, 0.0, 0.0))
			visible = true

func _update_border(texture: Texture2D, color: Color = Color(1, 1, 1)):
	var border = get_node("Border")
	border.texture = texture
	border.modulate = color
	border.size = size * tree.border_scale
	border.set_anchors_and_offsets_preset(PRESET_CENTER, PRESET_MODE_KEEP_SIZE)
