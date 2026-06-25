@tool
class_name YggdrasilAttributesEditor
extends Control

signal changed

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")
const FuzzySearch = Yggdrasil.FuzzySearch

const MAX_ATTRIBUTES = 4

@export var editor: YggdrasilEditor
@export var add_button: Button
@export var filter_input: LineEdit
@export var tree: YggdrasilTreeUI

var _current_node: YggdrasilNodeButton
var _fuzzy = FuzzySearch.new()

func init():
	editor.node_selected.connect(_on_node_selected)
	editor.node_attribute_changed.connect(_on_node_attribute_changed)
	tree.init()
	
	tree.item_activated.connect(_on_item_activated)
	tree.item_edited.connect(_on_item_edited)
	tree.edit_canceled.connect(_on_edit_canceled)
	tree.edit_started.connect(_on_item_edit_started)

	add_button.pressed.connect(_on_add_button_pressed)

	filter_input.text_changed.connect(_on_filter_text_changed)

func load_tree():
	for attr_id in editor.tree.attributes.keys():
		var attribute = editor.tree.attributes[attr_id]
		var attribute_root = tree.get_root().create_child()
		attribute_root.set_text(0, attribute.id)
		attribute_root.set_metadata(0, attribute)

		var name_item = attribute_root.create_child()
		name_item.set_text(0, "Name: %s" % attribute.name)

		var effect_item = attribute_root.create_child()
		effect_item.set_edit_multiline(0, true)
		effect_item.set_text(0, "Effect: %s" % attribute.effect)

		var value_count_item = attribute_root.create_child()
		value_count_item.set_text(0, "Value Count: %d" % attribute.value_count)

		attribute_root.set_collapsed(true)

func _on_filter_text_changed(new_text: String):
	var search_text = new_text.strip_edges()
	if search_text.is_empty():
		for attr_item in tree.get_root().get_children():
			attr_item.visible = true
		return

	_fuzzy.allow_subsequences = false
	_fuzzy.set_query(search_text, false)
	var ids: Array[int] = []
	var results: Array[TreeItem] = []

	for attr_item in tree.get_root().get_children():
		ids.append(attr_item.get_index())
	
	var targets_by_id = PackedStringArray(ids.map(func(id: int) -> String:
		var target_item = tree.get_root().get_child(id)
		var attribute = target_item.get_metadata(0)
		return attribute.id
	))
	var results_by_id: Array[FuzzySearch.FuzzySearchResult] = []
	_fuzzy.search_all(targets_by_id, results_by_id)

	for r in results_by_id:
		var item = tree.get_root().get_child(ids[r.original_index])
		results.append(item)

	var targets_by_name = PackedStringArray(ids.map(func(id: int) -> String:
		var target_item = tree.get_root().get_child(id)
		var attribute = target_item.get_metadata(0)
		return attribute.name
	))
	var results_by_name: Array[FuzzySearch.FuzzySearchResult] = []
	_fuzzy.search_all(targets_by_name, results_by_name)
	for r in results_by_name:
		var item = tree.get_root().get_child(ids[r.original_index])
		results.append(item)

	var targets_by_effect = PackedStringArray(ids.map(func(id: int) -> String:
		var target_item = tree.get_root().get_child(id)
		var attribute = target_item.get_metadata(0)
		return attribute.effect
	))
	var results_by_effect: Array[FuzzySearch.FuzzySearchResult] = []
	_fuzzy.search_all(targets_by_effect, results_by_effect)
	for r in results_by_effect:
		var item = tree.get_root().get_child(ids[r.original_index])
		results.append(item)
	
	for attr_item in tree.get_root().get_children():
		attr_item.visible = false
	
	for result_item in results:
		result_item.visible = true

func _on_node_selected(node: YggdrasilNodeButton):
	_current_node = node

	if _current_node and _current_node.type == YggdrasilNode.NodeType.DECORATION:
		_current_node = null

	for child in tree.get_root().get_children():
		var attribute = child.get_metadata(0)
		if not _current_node:
			child.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
			child.set_editable(0, false)
			child.set_text(0, attribute.id)
		else:
			child.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
			child.set_editable(0, true)
			child.set_text(0, attribute.id)
			child.set_checked(0, node.attributes.has(attribute.id))

func _on_node_attribute_changed(node: YggdrasilNodeButton, attribute_id: String, removed: bool):
	if not removed:
		return
	
	if not _current_node or _current_node != node:
		return
	
	for child in tree.get_root().get_children():
		var attribute = child.get_metadata(0)
		if attribute.id == attribute_id:
			child.set_checked(0, false)
			return

func _on_add_button_pressed():
	var attribute_root = tree.get_root().create_child()
	attribute_root.set_text(0, "New Attribute")
	attribute_root.set_metadata(0, {"new_attr": true})
	await get_tree().create_timer(0.01).timeout
	attribute_root.select(0)
	tree.edit_selected(true)
	tree.grab_focus(true)

func _on_item_edited():
	var edited = tree.get_edited()
	
	var metadata = edited.get_metadata(0)
	if not metadata:
		var index = edited.get_index()
		var attribute = edited.get_parent().get_metadata(0)
		match index:
			0:
				attribute.name = edited.get_text(0)
				edited.set_text(0, "Name: %s" % attribute.name)
			1:
				attribute.effect = edited.get_text(0)
				edited.set_text(0, "Effect: %s" % attribute.effect)
			2:
				attribute.value_count = int(edited.get_range(0))
				edited.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
				edited.set_text(0, "Value Count: %d" % attribute.value_count)
				editor.node_attribute_changed.emit(_current_node, attribute.id, false)
		changed.emit()
		return

	if metadata is Dictionary and metadata.has("new_attr"):
		var text = edited.get_text(0).strip_edges()
		if text.is_empty():
			edited.free()
			return
		
		var new_attr = YggdrasilAttribute.new()
		new_attr.id = text.to_snake_case()
		new_attr.name = text
		new_attr.effect = "Edit me!"
		new_attr.value_count = 0

		editor.tree.attributes[new_attr.id] = new_attr
		
		if _current_node:
			edited.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
			edited.set_editable(0, true)
		else:
			edited.set_editable(0, false)
		edited.set_metadata(0, new_attr)
		edited.set_text(0, new_attr.id)
		
		var name_item = edited.create_child()
		name_item.set_text(0, "Name: %s" % new_attr.name)

		var effect_item = edited.create_child()
		effect_item.set_text(0, "Effect: %s" % new_attr.effect)

		var value_count_item = edited.create_child()
		value_count_item.set_text(0, "Value Count: %s" % str(new_attr.value_count))
		return
	
	if edited.get_cell_mode(0) == TreeItem.CELL_MODE_CHECK:
		if not _current_node:
			return
		
		if edited.is_checked(0):
			var values = []
			for i in metadata.value_count:
				values.append(0)
			
			if _current_node.prefab:
				_current_node.prefab.set_attribute(metadata.id, values, editor.tree.multiallocation)
			else:
				if editor.tree.multiallocation:
					_current_node.attributes[metadata.id] = []
					for level in range(_current_node.max_allocations):
						_current_node.attributes[metadata.id].append(values.duplicate())
				else:
					_current_node.attributes[metadata.id] = values
				editor.node_attribute_changed.emit(_current_node, metadata.id, false)
		else:
			if _current_node.prefab:
				_current_node.prefab.remove_attribute(metadata.id)
			else:
				_current_node.attributes.erase(metadata.id)
				editor.node_attribute_changed.emit(_current_node, metadata.id, true)
	else:
		var old_id = metadata.id
		var new_id = edited.get_text(0).strip_edges().to_snake_case()

		if old_id == new_id:
			if _current_node:
				edited.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
				edited.set_checked(0, _current_node.attributes.has(old_id))
			edited.set_text(0, old_id)
			return

		metadata.id = new_id
		
		var old_attr = editor.tree.attributes[old_id]
		editor.tree.attributes.erase(old_id)
		editor.tree.attributes[metadata.id] = old_attr

		for node in editor.tree.nodes:
			if node.reference_id.is_empty() and node.attributes.has(old_id):
				var values = node.attributes[old_id]
				node.attributes.erase(old_id)
				editor.node_attribute_changed.emit(node, old_id, true)
				node.attributes[metadata.id] = values
				editor.node_attribute_changed.emit(node, metadata.id, false)
		
		for p_key in editor.tree.prefabs.keys():
			if p_key == YggdrasilNode.NodeType.DECORATION:
				continue
			
			for prefab: YggdrasilPrefab in editor.tree.prefabs[p_key]:
				if not prefab.attributes.has(old_id):
					continue
				
				var values = prefab.attributes[old_id]
				if prefab.reference_id.is_empty():
					prefab.attributes.erase(old_id)
					prefab.attributes[metadata.id] = values
				else:
					prefab.remove_attribute(old_id)
					prefab.set_attribute(metadata.id, values)
		
		if _current_node:
			edited.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
			edited.set_checked(0, _current_node.attributes.has(new_id))
		edited.set_text(0, metadata.id)

	changed.emit()

func _on_item_activated():
	var selected = tree.get_selected()
	if selected.get_parent() == tree.get_root():
		var text = selected.get_text(0)
		selected.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
		selected.set_text(0, text)
		return

	var attribute = selected.get_parent().get_metadata(0)
	if not attribute:
		return
	
	var index = selected.get_index()
	match index:
		0:
			selected.set_text(0, attribute.name)
		1:
			selected.set_text(0, attribute.effect)
		2:
			selected.set_cell_mode(0, TreeItem.CELL_MODE_RANGE)
			selected.set_range_config(0, 0, MAX_ATTRIBUTES, 1)
			selected.set_range(0, attribute.value_count)

	tree.edit_selected(true)

func _on_item_edit_started(item: TreeItem):
	if item.get_parent() == tree.get_root():
		var text = item.get_text(0)
		item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
		item.set_text(0, text)
		return
	
	var attribute = item.get_parent().get_metadata(0)
	var index = item.get_index()
	match index:
		0:
			item.set_text(0, attribute.name)
		1:
			item.set_text(0, attribute.effect)
		2:
			item.set_cell_mode(0, TreeItem.CELL_MODE_RANGE)
			item.set_range_config(0, 0, MAX_ATTRIBUTES, 1)
			item.set_range(0, attribute.value_count)

func _on_edit_canceled(item: TreeItem):
	var metadata = item.get_metadata(0)
	if not metadata:
		var attribute = item.get_parent().get_metadata(0)
		var index = item.get_index()
		match index:
			0:
				item.set_text(0, "Name: %s" % attribute.name)
			1:
				item.set_text(0, "Effect: %s" % attribute.effect)
			2:
				item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
				item.set_text(0, "Value Count: %d" % attribute.value_count)
		return
	
	if metadata is Dictionary and metadata.has("new_attr"):
		item.free()
		return

	if _current_node:
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	item.set_text(0, metadata.id)

func clear_selected_attributes():
	for child in tree.get_root().get_children():
		child.set_checked(0, false)
