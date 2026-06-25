@tool
class_name YggdrasilEditor
extends Control

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")

signal dirty_changed(editor: YggdrasilEditor, dirty: bool)
signal tree_closed(editor: YggdrasilEditor)
signal node_deleted(node: YggdrasilNodeButton)
signal node_selected(node: YggdrasilNodeButton)
signal node_moved(node: YggdrasilNodeButton, new_position: Vector2)
signal node_attribute_changed(node: YggdrasilNodeButton, attribute_id: String, removed: bool)

@export_group("Editors")
@export var view_parent: Control
@export var menu_bar: MenuBar
@export var hierarchy: TreeHierarchy
@export var prefabs_tab: YggdrasilPrefabsBar
@export var inspector: TreeEditorInspector
@export var settings_editor: YggdrasilSettingsEditor
@export var attributes_editor: YggdrasilAttributesEditor
@export var context_menu: YggdrasilEditorContext
@export var validator: YggdrasilValidator

@export_group("Tool Bar")
@export var tools_group: ButtonGroup
@export var select_tool_button: BaseButton
@export var move_tool_button: BaseButton
@export var grid_snap_button: BaseButton
@export var grid_x_input: SpinBox
@export var grid_y_input: SpinBox
@export var zoom_label: Label
@export var zoom_slider: HSlider

@export_group("Shortcuts")
@export var save_shortcut: Shortcut
@export var close_shortcut: Shortcut
@export var duplicate_shortcut: Shortcut
@export var delete_shortcut: Shortcut

enum ToolType {
	SELECT,
	MOVE
}

var _tree_view: YggdrasilTreeView
var _selected_tool: ToolType = ToolType.SELECT
var _selection_box: YggdrasilSelectionBox
var _move_tool: YggdrasilMoveTool
var _last_click_pos: Vector2
var _grid: YggdrasilProceduralGrid
var _prefab_dropper: YggdrasilPrefabDrop

var tree: YggdrasilTree
var selected_nodes: Array[YggdrasilNodeButton] = []
var last_saved_time: int = 0
var dirty: bool = false

func init():
	prefabs_tab.changed.connect(_mark_dirty)
	inspector.changed.connect(_mark_dirty)
	attributes_editor.changed.connect(_mark_dirty)
	settings_editor.changed.connect(_mark_dirty)
	hierarchy.changed.connect(_mark_dirty)
	
	prefabs_tab.init()
	hierarchy.init()
	settings_editor.init()
	attributes_editor.init()
	context_menu.init()
	validator.init()

	context_menu.new_node.connect(_on_new_node_requested)
	context_menu.duplicate_node.connect(_duplicate_selected_nodes)
	context_menu.delete_node.connect(_delete_selected_nodes)
	context_menu.save_as_prefab.connect(_save_as_prefab)
	context_menu.save_as_copy.connect(_save_as_copy)
	context_menu.make_unique.connect(_make_selected_node_unique)

	var file_menu: PopupMenu = menu_bar.get_node("File")
	file_menu.add_item("Save Tree", 0)
	file_menu.set_item_shortcut(0, save_shortcut)
	file_menu.add_item("Close Tree", 1)
	file_menu.set_item_shortcut(1, close_shortcut)
	file_menu.id_pressed.connect(_on_file_menu_item_pressed)
	
	tools_group.pressed.connect(_on_tool_selected)

	grid_snap_button.toggled.connect(_on_grid_snap_toggled)
	grid_x_input.value_changed.connect(_on_grid_snap_changed)
	grid_y_input.value_changed.connect(_on_grid_snap_changed)

func destroy():
	prefabs_tab.destroy()
	inspector.destroy()
	hierarchy.destroy()
	
	hierarchy.clear()
	var file_menu: PopupMenu = menu_bar.get_node("File")
	file_menu.clear()

func _shortcut_input(event):
	if not is_visible_in_tree():
		return
	
	if event.pressed and not event.is_echo():
		if delete_shortcut.matches_event(event):
			_delete_selected_nodes()
			get_viewport().set_input_as_handled()
		elif duplicate_shortcut.matches_event(event):
			_duplicate_selected_nodes()
			get_viewport().set_input_as_handled()

func _on_file_menu_item_pressed(id: int):
	match id:
		0:
			save_tree()
		1:
			close_tree()

func save_tree():
	last_saved_time = Time.get_ticks_msec()
	set_dirty(false)
	ResourceSaver.save(tree, tree.resource_path)
	EditorInterface.get_resource_filesystem().scan()

func edit_tree(path: String):
	tree = YggdrasilLoader.load_tree(path)

	settings_editor.load_tree(tree)

	_build_tree_view()
	_create_grid_view()
	_create_prefab_dropper()
	_create_selection_box()
	_create_move_tool()

	view_parent.move_child(validator, view_parent.get_child_count() - 1)

	settings_editor.background_changed.connect(_on_background_changed)
	settings_editor.size_changed.connect(_on_size_changed)
	settings_editor.border_scale_changed.connect(_on_border_scale_changed)
	settings_editor.icon_size_changed.connect(_on_icon_size_changed)
	settings_editor.node_size_changed.connect(_on_node_size_changed)
	settings_editor.line_texture_changed.connect(_on_line_texture_changed)
	settings_editor.revealed_changed.connect(_on_revealed_changed)
	settings_editor.allocation_changed.connect(_on_allocation_changed)
	settings_editor.preallocation_changed.connect(_on_preallocation_changed)
	settings_editor.multiallocation_changed.connect(_on_multiallocation_changed)
	
	_tree_view.camera.zoom_changed.connect(_on_camera_zoom_changed)
	inspector.init(_tree_view)
	
	attributes_editor.load_tree()
	
	inspector.connect_signals(_tree_view)
	zoom_slider.value_changed.connect(_tree_view.camera.set_camera_zoom)
	_tree_view.nodes_service.node_pressed.connect(_on_node_pressed)
	_tree_view.decorations_service.decoration_pressed.connect(_on_node_pressed)

	validator.validate()

func _build_tree_view():
	var builder = YggdrasilBuilder.new(tree)
	builder.set_parent(view_parent)
	builder.node_created_callback(_on_node_created)
	builder.decoration_created_callback(_on_decoration_created)
	builder.prefab_created_callback(_on_prefab_created)
	builder.line_created_callback(_on_line_created)
	_tree_view = builder.build()

	_tree_view.gui_input.connect(_on_tree_view_input)

func _create_selection_box():
	_selection_box = YggdrasilSelectionBox.new()
	_selection_box.set_view(_tree_view)
	_selection_box.selected.connect(_on_selection_box_selected)
	_tree_view.add_child(_selection_box)

func _create_move_tool():
	_move_tool = YggdrasilMoveTool.new()
	_move_tool.z_index = 100
	_move_tool.hide()
	_tree_view.main_container.add_child(_move_tool)
	_move_tool.moved.connect(_on_tool_moved)
	_move_tool.released.connect(_on_move_released)

func close_tree():
	_tree_view.queue_free()
	tree_closed.emit(self)

func set_dirty(is_dirty: bool):
	if dirty != is_dirty:
		dirty = is_dirty
		dirty_changed.emit(self, dirty)

func get_last_modified_time() -> String:
	var elapsed_time = Time.get_ticks_msec() - last_saved_time
	var hours = int(elapsed_time / 3600000)
	var minutes = int((elapsed_time % 3600000) / 60000)
	var seconds = int((elapsed_time % 60000) / 1000)
	var time_string = ""
	if hours > 0:
		time_string = str(hours) + " hours"
	elif minutes > 0:
		time_string = str(minutes) + " minutes"
	else:
		time_string = str(seconds) + " seconds"
	return time_string + " ago."

func _mark_dirty():
	validator.validate()
	set_dirty(true)

func _on_tool_selected(button: BaseButton):
	match button:
		select_tool_button:
			_selected_tool = ToolType.SELECT
			_tree_view.set_default_cursor_shape(CURSOR_ARROW)
			_move_tool.hide()
			if not selected_nodes.is_empty():
				selected_nodes[0].button_mask = MOUSE_BUTTON_MASK_RIGHT
				selected_nodes[0].button_mask = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT
		move_tool_button:
			_selected_tool = ToolType.MOVE
			_tree_view.set_default_cursor_shape(CURSOR_MOVE)
			if not selected_nodes.is_empty():
				_move_tool.show()
			if not selected_nodes.is_empty():
				selected_nodes[0].button_mask = MOUSE_BUTTON_MASK_RIGHT

func _on_tree_view_input(event):
	if not is_visible_in_tree():
		return
	
	if _selected_tool == ToolType.SELECT and event is InputEventMouse:
		_selection_box.input(event)
	elif _selected_tool == ToolType.MOVE:
		_move_tool.input(event)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			context_menu.update_items(selected_nodes[0] if not selected_nodes.is_empty() else null)
			context_menu.popup(Rect2i(_tree_view.get_screen_transform() * event.position, Vector2i.ZERO))
			_last_click_pos = _get_mouse_in_view()

func deselect_node(node: YggdrasilNodeButton):
	node.get_node("Focus").free()
	node.button_mask = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT

	for out_node_id in node.out_nodes:
		var line: YggdrasilConnection = _tree_view.lines_container.get_node("Line_%d_%d" % [node.id, out_node_id])
		line.self_modulate = Color.WHITE

func _clear_selection():
	var cleared = not selected_nodes.is_empty()
	
	for node in selected_nodes:
		deselect_node(node)
	
	selected_nodes.clear()
	
	if cleared:
		node_selected.emit(null)

func _focus_node(node: YggdrasilNodeButton):
	var focus = ReferenceRect.new()
	focus.name = "Focus"
	focus.border_width = 2.5
	focus.mouse_filter = MOUSE_FILTER_IGNORE
	focus.set_anchors_preset(PRESET_FULL_RECT)
	node.add_child(focus)

	for out_node_id in node.out_nodes:
		var line: YggdrasilConnection = _tree_view.lines_container.get_node("Line_%d_%d" % [node.id, out_node_id])
		line.self_modulate = Color.GREEN

func select_node(node: YggdrasilNodeButton, add_to_selection: bool = false):
	if node and node.locked:
		return

	if add_to_selection and selected_nodes.has(node):
		deselect_node(node)
		selected_nodes.erase(node)
	else:
		if add_to_selection:
			_focus_node(node)
			selected_nodes.append(node)
		else:
			_clear_selection()
			_focus_node(node)
			selected_nodes = [node]
	
	if not selected_nodes.is_empty():
		node_selected.emit(selected_nodes[0])
		selected_nodes[0].get_node("Focus").border_color = Color(0, 1, 1, 1)

		_move_tool.nodes = selected_nodes
		_update_move_tool_position()
		if _selected_tool == ToolType.MOVE:
			selected_nodes[0].button_mask = MOUSE_BUTTON_MASK_RIGHT
			_move_tool.show()

func _on_selection_box_selected(rect: Rect2):
	if rect.size.x == 0.0 or rect.size.y == 0.0:
		_clear_selection()
		return
	
	if not Input.is_key_pressed(KEY_CTRL):
		_clear_selection()
	
	for decoration in _tree_view.decorations_container.get_children():
		if rect.intersects(decoration.get_rect()):
			select_node(decoration, true)
	
	for node in _tree_view.nodes_container.get_children():
		if rect.intersects(node.get_rect()):
			select_node(node, true)

func _on_tool_moved(new_positions: Array[Vector2]):
	if selected_nodes.is_empty():
		return
	
	for i in range(selected_nodes.size()):
		var node = selected_nodes[i]
		var pos = new_positions[i]
		if is_grid_snapping_enabled():
			var center_local = pos + (node.size * 0.5)
			var center = center_local - (tree.size * 0.5)
			center = _snap_to_grid(center)
			center_local = center + (tree.size * 0.5)
			pos = center_local - (node.size * 0.5)
		node.position = pos
		node.node_data.position = _tree_view.translate_node_position(node)
		_tree_view.connections_service.update_connected_lines(node)
	
	_update_move_tool_position()

func _update_move_tool_position():
	if selected_nodes.size() == 1:
		_move_tool.position = _get_center_position(selected_nodes[0])
	elif selected_nodes.size() > 1:
		var mid_pos: Vector2 = Vector2.ZERO
		for node in selected_nodes:
			mid_pos += node.position + (node.size * 0.5)
		mid_pos /= selected_nodes.size()
		_move_tool.position = mid_pos

func _on_move_released():
	if selected_nodes.is_empty():
		return
	
	node_moved.emit(selected_nodes[0], _tree_view.translate_node_position(selected_nodes[0]))
	_mark_dirty()

func _get_mouse_in_view() -> Vector2:
	return _tree_view.main_container.get_local_mouse_position() - (tree.size / 2)

func _duplicate_selected_nodes():
	if selected_nodes.is_empty():
		return
	
	var created_nodes = []
	for selected_node in selected_nodes:
		var node = _tree_view.nodes_service.duplicate_node(selected_node)
		created_nodes.append(node)
	
	_clear_selection()

	for node in created_nodes:
		select_node(node, true)
	
	_mark_dirty()

func _delete_selected_nodes():
	if selected_nodes.is_empty():
		return
	
	var nodes_to_delete = selected_nodes.duplicate()
	for node in nodes_to_delete:
		delete_node(node)
	
	_clear_selection()
	_mark_dirty()

func delete_node(node: YggdrasilNodeButton):
	if node.type != YggdrasilNode.NodeType.DECORATION:
		for out_node_id in node.node_data.out_nodes:
			var line: YggdrasilConnection = _tree_view.lines_container.get_node_or_null("Line_%d_%d" % [node.id, out_node_id])
			if line:
				line.queue_free()
			var target_node = _tree_view.nodes_service.get_node(out_node_id)
			if target_node:
				target_node.in_nodes.erase(node.id)
		
		for in_node_id in node.node_data.in_nodes:
			var line: YggdrasilConnection = _tree_view.lines_container.get_node_or_null("Line_%d_%d" % [in_node_id, node.id])
			if line:
				line.queue_free()
			var source_node = _tree_view.nodes_service.get_node(in_node_id)
			if source_node:
				source_node.out_nodes.erase(node.id)
				source_node.line_data.erase(node.id)
		node.line_data.clear()
	
	if node.prefab:
		node.prefab.remove_node(node)

	if node.type == YggdrasilNode.NodeType.DECORATION:
		tree.decorations.erase(node.node_data)
	else:
		tree.nodes.erase(node.node_data)
	
	_tree_view.nodes_service.delete_node(node)
	node_deleted.emit(node)
	node.queue_free()
	_mark_dirty()

	if node in selected_nodes:
		selected_nodes.erase(node)
		if selected_nodes.is_empty():
			node_selected.emit(null)

func _create_grid_view():
	_grid = YggdrasilProceduralGrid.new()
	_grid.mouse_filter = MOUSE_FILTER_IGNORE
	_grid.visible = false
	_grid.parent = _tree_view.main_container
	_tree_view.add_child(_grid)
	_grid.set_anchors_preset(PRESET_FULL_RECT)

func _on_grid_snap_toggled(pressed: bool):
	_grid.visible = pressed

func _on_grid_snap_changed(value: float):
	_grid.cell_size = Vector2(grid_x_input.value, grid_y_input.value)

func is_grid_snapping_enabled() -> bool:
	return grid_snap_button.button_pressed

func _snap_to_grid(pos: Vector2) -> Vector2:
	if not is_grid_snapping_enabled():
		return pos
	
	return Vector2(
		round(pos.x / grid_x_input.value) * grid_x_input.value,
		round(pos.y / grid_y_input.value) * grid_y_input.value
	)

func _get_center_position(node: Control) -> Vector2:
	return node.position + (node.size / 2)

func _on_new_node_requested(node_type: YggdrasilNode.NodeType):
	if node_type == YggdrasilNode.NodeType.DECORATION:
		_tree_view.decorations_service.create_decoration(_snap_to_grid(_last_click_pos))
	else:
		_tree_view.nodes_service.create_node(_snap_to_grid(_last_click_pos), node_type)
	_mark_dirty()

func _save_as_prefab():
	for node in selected_nodes:
		_tree_view.prefabs_service.create_prefab(node)
	_mark_dirty()

func _save_as_copy():
	for node in selected_nodes:
		_tree_view.prefabs_service.create_prefab(node, true)
	_mark_dirty()

func _make_selected_node_unique():
	if selected_nodes.is_empty():
		return
	
	_tree_view.prefabs_service.make_unique(selected_nodes[0])
	_mark_dirty()

func _create_prefab_dropper():
	_prefab_dropper = YggdrasilPrefabDrop.new()
	_prefab_dropper.set_anchors_preset(PRESET_FULL_RECT)
	_prefab_dropper.mouse_filter = MOUSE_FILTER_PASS
	_tree_view.main_container.add_child(_prefab_dropper)
	_tree_view.main_container.move_child(_prefab_dropper, 1)

	_prefab_dropper.prefab_dropped.connect(_on_prefab_dropped)
	
	var small_prefabs_panel = prefabs_tab.get_panel(YggdrasilNode.NodeType.SMALL)
	small_prefabs_panel.list.set_drag_forwarding(small_prefabs_panel.get_drag_data, _prefab_dropper.can_drop_prefab, _prefab_dropper.drop_prefab)
	var medium_prefabs_panel = prefabs_tab.get_panel(YggdrasilNode.NodeType.MEDIUM)
	medium_prefabs_panel.list.set_drag_forwarding(medium_prefabs_panel.get_drag_data, _prefab_dropper.can_drop_prefab, _prefab_dropper.drop_prefab)
	var large_prefabs_panel = prefabs_tab.get_panel(YggdrasilNode.NodeType.LARGE)
	large_prefabs_panel.list.set_drag_forwarding(large_prefabs_panel.get_drag_data, _prefab_dropper.can_drop_prefab, _prefab_dropper.drop_prefab)
	var decoration_prefabs_panel = prefabs_tab.get_panel(YggdrasilNode.NodeType.DECORATION)
	decoration_prefabs_panel.list.set_drag_forwarding(decoration_prefabs_panel.get_drag_data, _prefab_dropper.can_drop_prefab, _prefab_dropper.drop_prefab)

func _on_prefab_dropped(prefab: YggdrasilPrefab):
	if prefab.type == YggdrasilNode.NodeType.DECORATION:
		_tree_view.decorations_service.create_from_prefab(_snap_to_grid(_tree_view.get_mouse_position_in_tree()), prefab)
	else:
		_tree_view.nodes_service.create_from_prefab(_snap_to_grid(_tree_view.get_mouse_position_in_tree()), prefab)
	_mark_dirty()

func _on_node_pressed(node: YggdrasilNodeButton):
	if selected_nodes.size() == 1 and selected_nodes[0] == node:
		return

	var ctrl_pressed = Input.is_key_pressed(KEY_CTRL)
	if ctrl_pressed:
		select_node(node, true)
		return

	var shift_pressed = Input.is_key_pressed(KEY_SHIFT)
	if shift_pressed and not node.type == YggdrasilNode.NodeType.DECORATION:
		for i in range(selected_nodes.size()):
			var selected_node = selected_nodes[i]
			if selected_node.type == YggdrasilNode.NodeType.DECORATION:
				continue

			if selected_node == node:
				continue
			
			_tree_view.connections_service.create_connection(selected_node, node)

		_mark_dirty()
		return
	
	select_node(node)

func _on_decoration_created(decoration: YggdrasilNodeButton):
	hierarchy.on_node_created(decoration)

func _on_node_created(node: YggdrasilNodeButton):
	hierarchy.on_node_created(node)

func _on_node_deleted(node: YggdrasilNodeButton):
	hierarchy.on_node_deleted(node)

func _on_line_created(line: YggdrasilConnection, from_node_id: int, to_node_id: int):
	pass

func _on_camera_zoom_changed(zoom: float, previous_zoom: float):
	zoom_label.text = "%d%%" % int(zoom * 100)
	zoom_slider.set_value_no_signal(zoom)

func _on_prefab_created(prefab: YggdrasilPrefab):
	var prefab_panel = prefabs_tab.get_panel(prefab.type)
	prefab_panel.add_prefab(prefab, prefab.reference_id.is_empty())
	_connect_prefab_signals(prefab)

func _connect_prefab_signals(prefab: YggdrasilPrefab):
	prefab.name_changed.connect(_on_prefab_name_changed)
	prefab.description_changed.connect(_on_prefab_description_changed)
	prefab.icon_changed.connect(_on_prefab_icon_changed)
	prefab.border_changed.connect(_on_prefab_border_changed)
	prefab.attribute_changed.connect(_on_prefab_attribute_changed)
	prefab.max_allocations_changed.connect(_on_prefab_max_allocation_changed)

func _on_prefab_name_changed(prefab: YggdrasilPrefab):
	for node in prefab.nodes:
		node.node_name = prefab.node_name

func _on_prefab_description_changed(prefab: YggdrasilPrefab):
	for node in prefab.nodes:
		node.description = prefab.description

func _on_prefab_icon_changed(prefab: YggdrasilPrefab):
	for node in prefab.nodes:
		var icon: TextureRect = node.get_node("Icon")
		icon.texture = prefab.icon if prefab.icon else Yggdrasil.BlankIcon
		node.icon = prefab.icon
		if node.type == YggdrasilNode.NodeType.DECORATION:
			node.size = node.icon.get_size()

func _on_prefab_border_changed(prefab: YggdrasilPrefab):
	for node in prefab.nodes:
		var border: TextureRect = node.get_node("Border")
		if prefab.border_normal:
			if not border.texture:
				border.texture = prefab.border_normal
				border.size = node.size * tree.border_scale
				border.set_anchors_and_offsets_preset(PRESET_CENTER, PRESET_MODE_KEEP_SIZE)
		else:
			border.texture = null
		
		node.border_normal = prefab.border_normal
		node.border_intermediate = prefab.border_intermediate
		node.border_active = prefab.border_active

func _on_prefab_attribute_changed(prefab: YggdrasilPrefab, attribute_id: String, removed: bool):
	for node in prefab.nodes:
		if removed:
			node.attributes.erase(attribute_id)
		else:
			node.attributes[attribute_id] = prefab.attributes[attribute_id]
		
		node_attribute_changed.emit(node, attribute_id, removed)

func _on_prefab_max_allocation_changed(prefab: YggdrasilPrefab):
	for node in prefab.nodes:
		node.max_allocations = prefab.max_allocations

func _on_background_changed():
	var color_rect = _tree_view.background_container.get_node("BackgroundColor")
	var texture_rect = _tree_view.background_container.get_node("BackgroundTexture")
	color_rect.color = tree.bg_color
	texture_rect.texture = tree.bg_texture

func _on_size_changed():
	_tree_view.main_container.set_size(tree.size)
	_tree_view.main_container.set_anchors_and_offsets_preset(PRESET_CENTER, PRESET_MODE_KEEP_SIZE)
	_tree_view.background_container.set_anchors_preset(PRESET_FULL_RECT)
	_tree_view.lines_container.set_anchors_preset(PRESET_FULL_RECT)
	_tree_view.nodes_container.set_anchors_preset(PRESET_FULL_RECT)

func _on_border_scale_changed():
	for node in _tree_view.nodes_container.get_children():
		node.set_state(node.state)

func _on_icon_size_changed():
	pass

func _on_node_size_changed():
	pass

func _on_line_texture_changed():
	for line in _tree_view.lines_container.get_children():
		line.texture = tree.line_texture_normal

func _on_revealed_changed():
	pass

func _on_allocation_changed():
	if tree.allocation:
		for node in _tree_view.nodes_container.get_children():
			if node.is_root:
				node.set_state(Yggdrasil.AllocationState.INTERMEDIATE)
	else:
		for node in _tree_view.nodes_container.get_children():
			if node.is_root:
				node.set_state(Yggdrasil.AllocationState.NORMAL)

func _on_preallocation_changed():
	pass

func _on_multiallocation_changed():
	# Go through nodes and prefabs and clear attributes dictionaries
	for node_data in tree.nodes:
		node_data.attributes.clear()
	for node_type in tree.prefabs.keys():
		if node_type == YggdrasilNode.NodeType.DECORATION:
			continue
		for prefab in tree.prefabs[node_type]:
			prefab.attributes.clear()
	inspector.update_multiallocation(tree.multiallocation)
	attributes_editor.clear_selected_attributes()
