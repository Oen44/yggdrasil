@tool
class_name TreeEditorInspector
extends Control

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")

signal changed

@export var editor: YggdrasilEditor
@export var icon_selector: YggdrasilIconSelector

@export_group("Root")
@export var root_panel: Control
@export var root_check: CheckBox

@export_group("Info")
@export var info_panel: Control
@export var id_input: LineEdit
@export var name_input: LineEdit
@export var description_input: TextEdit
@export var max_allocation_input: SpinBox

@export_group("Transform")
@export var transform_panel: FoldableContainer
@export var position_x: SpinBox
@export var position_y: SpinBox

@export_group("Visuals")
@export var visuals_panel: FoldableContainer
@export var icon_input: InspectorTextureInput
@export var border_normal_input: InspectorTextureInput
@export var border_intermediate_input: InspectorTextureInput
@export var border_active_input: InspectorTextureInput

@export_group("Attributes")
@export var attributes_panel: FoldableContainer
@export var attributes_tree: YggdrasilTreeUI

@export_group("Connection")
@export var connection_panel: FoldableContainer
@export var connection_entry_scene: PackedScene

var _selected_node: YggdrasilNodeButton
var _tree_view: YggdrasilTreeView

func init(tree_view: YggdrasilTreeView):
	_tree_view = tree_view
	root_panel.hide()
	info_panel.hide()
	transform_panel.hide()
	visuals_panel.hide()
	attributes_panel.hide()
	connection_panel.hide()

	editor.node_selected.connect(_on_node_selected)
	editor.node_moved.connect(_on_node_moved)
	editor.node_attribute_changed.connect(_on_node_attribute_changed)

	root_check.toggled.connect(_on_root_toggled)
	name_input.text_changed.connect(_on_name_changed)
	description_input.text_changed.connect(_on_description_changed)
	max_allocation_input.value_changed.connect(_on_max_allocation_changed)
	
	icon_selector.init()
	icon_selector.icon_selected.connect(_on_icon_selected)

	icon_input.load_button.pressed.connect(_on_icon_picker_pressed)
	icon_input.clear_button.pressed.connect(_on_icon_texture_cleared)
	icon_input.texture_dropped.connect(_on_icon_texture_changed)

	border_normal_input.load_button.pressed.connect(func():
		EditorInterface.popup_quick_open(_on_border_normal_changed, ["Texture2D"])
	)
	border_normal_input.clear_button.pressed.connect(_on_border_normal_cleared)
	border_normal_input.texture_dropped.connect(_on_border_normal_changed)

	border_intermediate_input.load_button.pressed.connect(func():
		EditorInterface.popup_quick_open(_on_border_intermediate_changed, ["Texture2D"])
	)
	border_intermediate_input.clear_button.pressed.connect(_on_border_intermediate_cleared)
	border_intermediate_input.texture_dropped.connect(_on_border_intermediate_changed)

	border_active_input.load_button.pressed.connect(func():
		EditorInterface.popup_quick_open(_on_border_active_changed, ["Texture2D"])
	)
	border_active_input.clear_button.pressed.connect(_on_border_active_cleared)
	border_active_input.texture_dropped.connect(_on_border_active_changed)

	attributes_tree.init()
	attributes_tree.button_clicked.connect(_on_attribute_button_clicked)
	attributes_tree.item_edited.connect(_on_attribute_edited)
	attributes_tree.item_activated.connect(_on_attribute_activated)
	attributes_tree.edit_started.connect(_on_attribute_edit_started)
	attributes_tree.edit_canceled.connect(_on_attribute_edit_canceled)

func connect_signals(tree_view: YggdrasilTreeView):
	tree_view.connections_service.node_connected.connect(_on_node_connected)
	tree_view.connections_service.node_disconnected.connect(_on_node_disconnected)

func _on_node_selected(node: YggdrasilNodeButton):
	if _selected_node and _selected_node.prefab:
		if _selected_node.prefab.name_changed.is_connected(_on_prefab_name_changed):
			_selected_node.prefab.name_changed.disconnect(_on_prefab_name_changed)

	_selected_node = node

	for child in connection_panel.get_node("VBoxContainer").get_children():
		child.free()
	
	root_panel.hide()
	attributes_panel.hide()
	info_panel.hide()
	border_normal_input.hide()
	border_intermediate_input.hide()
	border_active_input.hide()
	transform_panel.hide()
	visuals_panel.hide()
	connection_panel.hide()
	max_allocation_input.get_parent().hide()

	if not node:
		return

	if node.type != YggdrasilNode.NodeType.DECORATION:
		id_input.text = node.node_data.name.to_snake_case()
		name_input.text = node.node_data.name
		description_input.text = node.node_data.description
		root_check.button_pressed = node.is_root
		max_allocation_input.set_value_no_signal(node.max_allocations)
		info_panel.show()
		border_normal_input.show()
		border_intermediate_input.show()
		border_active_input.show()
		root_panel.show()
		if node.tree.multiallocation:
			max_allocation_input.get_parent().show()
	
	transform_panel.show()

	var pos = _tree_view.translate_node_position(node)
	position_x.value = pos.x
	position_y.value = pos.y
	
	visuals_panel.show()
	if node.icon:
		icon_input.texture_rect.texture = node.icon
		icon_input.empty_label.hide()
		icon_input.clear_button.show()
	else:
		icon_input.texture_rect.texture = null
		icon_input.empty_label.show()
		icon_input.clear_button.hide()
	
	if node.border_normal:
		border_normal_input.texture_rect.texture = node.border_normal
		border_normal_input.empty_label.hide()
		border_normal_input.clear_button.show()
	else:
		border_normal_input.texture_rect.texture = null
		border_normal_input.empty_label.show()
		border_normal_input.clear_button.hide()
	
	if node.border_intermediate:
		border_intermediate_input.texture_rect.texture = node.border_intermediate
		border_intermediate_input.empty_label.hide()
		border_intermediate_input.clear_button.show()
	else:
		border_intermediate_input.texture_rect.texture = null
		border_intermediate_input.empty_label.show()
		border_intermediate_input.clear_button.hide()
	
	if node.border_active:
		border_active_input.texture_rect.texture = node.border_active
		border_active_input.empty_label.hide()
		border_active_input.clear_button.show()
	else:
		border_active_input.texture_rect.texture = null
		border_active_input.empty_label.show()
		border_active_input.clear_button.hide()

	if node.type != YggdrasilNode.NodeType.DECORATION:
		if not node.line_data.is_empty():
			connection_panel.show()

			for to_node_id in node.line_data.keys():
				_create_connection_entry(node, to_node_id)
		
		if not node.attributes.is_empty():
			attributes_panel.show()
			attributes_tree.clear()
			attributes_tree.create_item()
			_update_attributes(node)
	
	if node.prefab and not node.prefab.name_changed.is_connected(_on_prefab_name_changed):
		node.prefab.name_changed.connect(_on_prefab_name_changed)

func _on_icon_picker_pressed():
	if not _selected_node:
		return

	if _selected_node.type == YggdrasilNode.NodeType.DECORATION:
		EditorInterface.popup_quick_open(_on_icon_texture_changed, ["Texture2D"])
		return
	
	icon_selector.load_icons(_selected_node.type)
	icon_selector.popup_centered()

func _on_icon_texture_changed(path: String):
	if not _selected_node:
		return
	
	if _selected_node.type != YggdrasilNode.NodeType.DECORATION:
		return
	
	if path.is_empty():
		_on_icon_texture_cleared()
		return

	var texture = ResourceLoader.load(path)
	if texture and texture is Texture2D:
		icon_input.texture_rect.texture = texture
		icon_input.empty_label.hide()
		icon_input.clear_button.show()
		update_node_icon(_selected_node, texture)
		changed.emit()

func _on_node_moved(node: YggdrasilNodeButton, new_position: Vector2):
	position_x.value = new_position.x
	position_y.value = new_position.y

func _on_name_changed(new_text: String):
	if not _selected_node:
		return
	
	if _selected_node.type == YggdrasilNode.NodeType.DECORATION:
		return
	
	if _selected_node.prefab and _selected_node.prefab.name_changed.is_connected(_on_prefab_name_changed):
		_selected_node.prefab.name_changed.disconnect(_on_prefab_name_changed)
	
	if new_text.is_empty():
		new_text = "Node_%d" % _selected_node.id
	
	id_input.text = new_text.to_snake_case()
	update_node_name(_selected_node, new_text)
	
	if _selected_node.prefab and not _selected_node.prefab.name_changed.is_connected(_on_prefab_name_changed):
		_selected_node.prefab.name_changed.connect(_on_prefab_name_changed)

func _on_description_changed():
	if not _selected_node:
		return
	
	if _selected_node.type == YggdrasilNode.NodeType.DECORATION:
		return
	
	update_node_description(_selected_node, description_input.text)

func _on_max_allocation_changed(value: float):
	if not _selected_node:
		return
	
	if _selected_node.type == YggdrasilNode.NodeType.DECORATION:
		return
	
	if _selected_node.prefab:
		_selected_node.prefab.set_max_allocations(int(value))
	else:
		_selected_node.max_allocations = int(value)
	changed.emit()

func _on_icon_selected(node_type: int, texture: Texture2D, region: Vector2):
	if not _selected_node:
		return
	
	update_node_texture(node_type, texture, region)
	icon_input.texture_rect.texture = _selected_node.icon
	icon_input.empty_label.hide()
	icon_input.clear_button.show()

func _on_icon_texture_cleared():
	if not _selected_node:
		return
	
	icon_input.texture_rect.texture = null
	icon_input.empty_label.show()
	icon_input.clear_button.hide()
	update_node_icon(_selected_node, null)
	changed.emit()

func _on_border_normal_changed(path: String):
	if not _selected_node:
		return
	
	if path.is_empty():
		_on_border_normal_cleared()
		return
	
	var texture = ResourceLoader.load(path)
	if texture and texture is Texture2D:
		border_normal_input.texture_rect.texture = texture
		border_normal_input.empty_label.hide()
		border_normal_input.clear_button.show()
		update_node_border_normal(_selected_node, texture)
		changed.emit()

func _on_border_intermediate_changed(path: String):
	if not _selected_node:
		return
	
	if path.is_empty():
		_on_border_intermediate_cleared()
		return
	
	var texture = ResourceLoader.load(path)
	if texture and texture is Texture2D:
		border_intermediate_input.texture_rect.texture = texture
		border_intermediate_input.empty_label.hide()
		border_intermediate_input.clear_button.show()
		update_node_border_intermediate(_selected_node, texture)
		changed.emit()

func _on_border_active_changed(path: String):
	if not _selected_node:
		return
	
	if path.is_empty():
		_on_border_active_cleared()
		return
	
	var texture = ResourceLoader.load(path)
	if texture and texture is Texture2D:
		border_active_input.texture_rect.texture = texture
		border_active_input.empty_label.hide()
		border_active_input.clear_button.show()
		update_node_border_active(_selected_node, texture)
		changed.emit()

func _on_border_normal_cleared():
	if not _selected_node:
		return
	
	border_normal_input.texture_rect.texture = null
	border_normal_input.empty_label.show()
	border_normal_input.clear_button.hide()
	update_node_border_normal(_selected_node, null)
	changed.emit()

func _on_border_intermediate_cleared():
	if not _selected_node:
		return
	
	border_intermediate_input.texture_rect.texture = null
	border_intermediate_input.empty_label.show()
	border_intermediate_input.clear_button.hide()
	update_node_border_intermediate(_selected_node, null)
	changed.emit()

func _on_border_active_cleared():
	if not _selected_node:
		return
	
	border_active_input.texture_rect.texture = null
	border_active_input.empty_label.show()
	border_active_input.clear_button.hide()
	update_node_border_active(_selected_node, null)
	changed.emit()

func _on_node_connected(node: YggdrasilNodeButton, to_node_id: int):
	connection_panel.show()
	_create_connection_entry(node, to_node_id)

func _on_node_disconnected(node: YggdrasilNodeButton, to_node_id: int):
	var entry = connection_panel.get_node("VBoxContainer/ConnectionEntry_%d" % to_node_id)
	if entry:
		entry.queue_free()
	
	if node.line_data.is_empty():
		connection_panel.hide()

func _create_connection_entry(node, to_node_id):
	var entry: FoldableContainer = connection_entry_scene.instantiate()
	entry.name = "ConnectionEntry_%d" % to_node_id
	entry.title = "Node %d" % to_node_id
	connection_panel.get_node("VBoxContainer").add_child(entry)

	var line_data = node.line_data[to_node_id]
	var inputs = entry.get_node("Inputs")
	var line_type_dropdown: OptionButton = inputs.get_node("LineType/LineTypeDropdown")
	var curve_panel: HBoxContainer = inputs.get_node("Curve")
	var curve_height: SpinBox = curve_panel.get_node("CurveInput")
	var segments_panel: HBoxContainer = inputs.get_node("Segments")
	var segments: SpinBox = segments_panel.get_node("SegmentsInput")
	var reversed_panel: HBoxContainer = inputs.get_node("Reversed")
	var reversed: CheckBox = reversed_panel.get_node("ReversedCheck")

	line_type_dropdown.item_selected.connect(_on_line_type_changed.bind(to_node_id))
	curve_height.value_changed.connect(_on_curve_height_changed.bind(to_node_id))
	segments.value_changed.connect(_on_segments_changed.bind(to_node_id))
	reversed.toggled.connect(_on_reversed_toggled.bind(to_node_id))

	match line_data.line_type:
		YggdrasilLineData.LineType.STRAIGHT:
			line_type_dropdown.select(0)
			curve_panel.hide()
			segments_panel.hide()
			reversed_panel.hide()
		YggdrasilLineData.LineType.BEZIER:
			line_type_dropdown.select(1)
			curve_panel.show()
			segments_panel.show()
			reversed_panel.show()
			curve_height.set_value_no_signal(line_data.curve_height)
			segments.set_value_no_signal(line_data.segments)
			reversed.set_pressed_no_signal(line_data.reversed)
		YggdrasilLineData.LineType.ARC:
			line_type_dropdown.select(2)
			curve_panel.hide()
			segments_panel.show()
			reversed_panel.show()
			segments.set_value_no_signal(line_data.segments)
			reversed.set_pressed_no_signal(line_data.reversed)

func _on_line_type_changed(index: int, to_node_id: int):
	if not _selected_node or not _selected_node.line_data:
		return
	
	var panel = connection_panel.get_node("VBoxContainer/ConnectionEntry_%d" % to_node_id)
	var inputs = panel.get_node("Inputs")
	var curve_panel: HBoxContainer = inputs.get_node("Curve")
	var curve_height: SpinBox = curve_panel.get_node("CurveInput")
	var segments_panel: HBoxContainer = inputs.get_node("Segments")
	var segments: SpinBox = segments_panel.get_node("SegmentsInput")
	var reversed_panel: HBoxContainer = inputs.get_node("Reversed")
	var reversed: CheckBox = reversed_panel.get_node("ReversedCheck")

	var line_data = _selected_node.line_data[to_node_id]
	match index:
		0:
			line_data.line_type = YggdrasilLineData.LineType.STRAIGHT
			curve_panel.hide()
			segments_panel.hide()
			reversed_panel.hide()
			_tree_view.connections_service.update_connected_lines(_selected_node)
		1:
			line_data.line_type = YggdrasilLineData.LineType.BEZIER
			curve_panel.show()
			segments_panel.show()
			reversed_panel.show()
			curve_height.set_value_no_signal(48.0)
			segments.set_value_no_signal(16)
			reversed.set_pressed_no_signal(false)
			_tree_view.connections_service.update_connected_lines(_selected_node)
		2:
			line_data.line_type = YggdrasilLineData.LineType.ARC
			curve_panel.hide()
			segments_panel.show()
			reversed_panel.show()
			segments.set_value_no_signal(16)
			reversed.set_pressed_no_signal(false)
			_tree_view.connections_service.update_connected_lines(_selected_node)
	
	changed.emit()

func _on_curve_height_changed(value: float, to_node_id: int):
	if not _selected_node or not _selected_node.line_data:
		return
	
	_selected_node.line_data[to_node_id].curve_height = value
	_tree_view.connections_service.update_connected_lines(_selected_node)
	changed.emit()

func _on_segments_changed(value: int, to_node_id: int):
	if not _selected_node or not _selected_node.line_data:
		return
	
	_selected_node.line_data[to_node_id].segments = value
	_tree_view.connections_service.update_connected_lines(_selected_node)
	changed.emit()

func _on_reversed_toggled(pressed: bool, to_node_id: int):
	if not _selected_node or not _selected_node.line_data:
		return
	
	_selected_node.line_data[to_node_id].reversed = pressed
	_tree_view.connections_service.update_connected_lines(_selected_node)
	changed.emit()

func _on_prefab_name_changed(prefab: YggdrasilPrefab):
	id_input.text = prefab.id
	name_input.text = prefab.node_name

func _update_attributes(node: YggdrasilNodeButton):
	var regex = RegEx.new()
	regex.compile('#')
	var icon = EditorInterface.get_editor_theme().get_icon("Close", "EditorIcons")

	for attr_id in node.attributes.keys():
		var attribute: YggdrasilAttribute = editor.tree.attributes[attr_id]
		var item: TreeItem = attributes_tree.get_root().create_child()
		item.set_text(0, attribute.id)
		item.add_button(0, icon, -1, false, "Remove Attribute")
		item.set_metadata(0, attr_id)

		for i in attribute.value_count:
			var value_item = item.create_child()
			value_item.set_text(0, "Value %d: %s" % [i + 1, str(node.attributes[attr_id][i])])
		
		var matches = regex.search_all(attribute.effect)
		if matches.size() != attribute.value_count:
			push_error("Attribute (id=%s) effect string has mismatched number (found=%d, expected=%d) of placeholders (char=#) for attribute values." % [attribute.id, matches.size(), attribute.value_count])
			continue
		
		var tooltip = attribute.effect
		for i in attribute.value_count:
			var value = node.attributes[attr_id][i]
			tooltip = regex.sub(tooltip, str(value))
		item.set_tooltip_text(0, tooltip)

func _on_node_attribute_changed(node: YggdrasilNodeButton, attribute_id: String, removed: bool):
	if not _selected_node or _selected_node != node:
		return
	
	if not node.attributes.is_empty():
		attributes_panel.show()
		attributes_tree.clear()
		attributes_tree.create_item()
		_update_attributes(node)
	else:
		attributes_panel.hide()

func _on_attribute_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int):
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	var attr_id = item.get_metadata(0)
	
	if _selected_node.prefab:
		_selected_node.prefab.remove_attribute(attr_id)
	else:
		_selected_node.attributes.erase(attr_id)
		editor.node_attribute_changed.emit(_selected_node, attr_id, true)
	changed.emit()

func _on_attribute_edited():
	var edited = attributes_tree.get_edited()
	
	var attribute_id = edited.get_parent().get_metadata(0)
	var index = edited.get_index()
	var value = edited.get_range(0)

	if str(value).ends_with(".0"):
		value = int(value)

	if _selected_node.prefab:
		_selected_node.prefab.set_attribute_value(attribute_id, index, value)
	else:
		_selected_node.attributes[attribute_id][index] = value
		editor.node_attribute_changed.emit(_selected_node, attribute_id, false)
	
	changed.emit()

func _on_attribute_activated():
	var selected = attributes_tree.get_selected()

	if selected.get_parent() == attributes_tree.get_root():
		selected.set_collapsed(not selected.is_collapsed())
		return
	
	_edit_attribute(selected)

	attributes_tree.edit_selected(true)

func _on_attribute_edit_started(item: TreeItem):
	if item.get_parent() == attributes_tree.get_root():
		attributes_tree.deselect_all()
		return
	
	_edit_attribute(item)

func _edit_attribute(item: TreeItem):
	var attribute_id = item.get_parent().get_metadata(0)
	var value = _selected_node.attributes[attribute_id][item.get_index()]
	item.set_cell_mode(0, TreeItem.CELL_MODE_RANGE)
	item.set_range_config(0, 0, 32000, 0.1, true)
	item.set_range(0, value)

func _on_attribute_edit_canceled(item: TreeItem):
	var attribute_id = item.get_parent().get_metadata(0)
	var value = _selected_node.attributes[attribute_id][item.get_index()]

	item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	item.set_text(0, "Value %d: %s" % [item.get_index() + 1, str(value)])

func _on_root_toggled(toggled_on: bool):
	if not _selected_node:
		return
	
	_selected_node.is_root = toggled_on
	if editor.tree.allocation:
		if toggled_on:
			_selected_node.set_state(Yggdrasil.AllocationState.INTERMEDIATE)
		else:
			_selected_node.set_state(Yggdrasil.AllocationState.NORMAL)
	changed.emit()

func update_node_name(node: YggdrasilNodeButton, new_name: String):
	if node.prefab:
		node.prefab.set_node_name(new_name)
	else:
		node.node_name = new_name
	changed.emit()

func update_node_description(node: YggdrasilNodeButton, new_description: String):
	if node.prefab:
		node.prefab.set_description(new_description)
	else:
		node.description = new_description
	changed.emit()

func update_node_icon(node: YggdrasilNodeButton, texture: Texture2D):
	if node.prefab:
		node.prefab.set_icon(texture)
	else:
		var icon: TextureRect = node.get_node("Icon")
		icon.texture = texture if texture else Yggdrasil.BlankIcon
		node.icon = texture
		if node.type == YggdrasilNode.NodeType.DECORATION:
			node.size = icon.texture.get_size()
	changed.emit()

func update_node_border_normal(node: YggdrasilNodeButton, texture: Texture2D):
	if node.prefab:
		node.prefab.set_border_normal(texture)
	else:
		var border: TextureRect = node.get_node("Border")
		if texture:
			border.texture = texture
			border.size = node.size * editor.tree.border_scale
			border.set_anchors_and_offsets_preset(PRESET_CENTER, PRESET_MODE_KEEP_SIZE)
		else:
			border.texture = null
		
		node.border_normal = texture
	changed.emit()

func update_node_border_intermediate(node: YggdrasilNodeButton, texture: Texture2D):
	if node.prefab:
		node.prefab.set_border_intermediate(texture)
	else:
		node.border_intermediate = texture
	changed.emit()

func update_node_border_active(node: YggdrasilNodeButton, texture: Texture2D):
	if node.prefab:
		node.prefab.set_border_active(texture)
	else:
		node.border_active = texture
	changed.emit()

func update_node_texture(node_type: YggdrasilNode.NodeType, texture: Texture2D, region: Vector2):
	editor.tree.icons[node_type] = texture

	changed.emit()

	if editor.selected_nodes.is_empty():
		return

	var selected = editor.selected_nodes[0]
	if selected.type == node_type:
		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(region, editor.tree.icon_sizes[node_type])
		update_node_icon(selected, atlas)

func update_multiallocation(multiallocation: bool):
	if not _selected_node:
		return
	
	max_allocation_input.get_parent().visible = multiallocation
