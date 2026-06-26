@tool
class_name TreeHierarchy
extends Tree

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")

signal changed

@export var editor: YggdrasilEditor

var _decorations: TreeItem
var _nodes: TreeItem

func init():
	create_item()
	select_mode = SELECT_MULTI

	_decorations = get_root().create_child()
	_decorations.set_text(0, "Decorations")
	_decorations.set_icon(0, get_theme_icon("TextureRect", Yggdrasil.ICON_THEME))

	_nodes = get_root().create_child()
	_nodes.set_text(0, "Nodes")
	_nodes.set_icon(0, get_theme_icon("Control", Yggdrasil.ICON_THEME))

	item_activated.connect(_on_item_activated)
	multi_selected.connect(_on_item_selected)
	button_clicked.connect(_on_item_button_clicked)

	editor.node_selected.connect(_on_node_selected)
	editor.node_deleted.connect(_on_node_deleted)

func _on_item_activated():
	var selected = get_selected()
	if selected.get_parent() == get_root():
		selected.set_collapsed(not selected.is_collapsed())

func _on_item_selected(item: TreeItem, column: int, selected: bool):
	if item.get_parent() == get_root():
		return
	
	if selected:
		var node = item.get_metadata(0)
		editor.select_node(node)

func _on_node_selected(selected_node: YggdrasilNodeButton):
	deselect_all()
	if not selected_node:
		return
	
	for node in editor.selected_nodes:
		if node.type == YggdrasilNode.NodeType.DECORATION:
			var id = "Decoration %d" % node.id
			for child in _decorations.get_children():
				if child.get_text(0) == id:
					child.select(0)
					break
		else:
			var id = "Node %d" % node.id
			for child in _nodes.get_children():
				if child.get_text(0) == id:
					child.select(0)
					break

func on_node_created(node: YggdrasilNodeButton):
	var item: TreeItem
	if node.type == YggdrasilNode.NodeType.DECORATION:
		item = _decorations.create_child()
		item.set_text(0, "Decoration %d" % node.id)
	else:
		item = _nodes.create_child()
		item.set_text(0, "Node %d" % node.id)
	
	if node.locked:
		item.add_button(0, EditorInterface.get_editor_theme().get_icon("Lock", Yggdrasil.ICON_THEME), 0)
		item.set_button_tooltip_text(0, 0, "Unlock Node")
	else:
		item.add_button(0, EditorInterface.get_editor_theme().get_icon("Unlock", Yggdrasil.ICON_THEME), 0)
		item.set_button_tooltip_text(0, 0, "Lock Node")

	item.add_button(0, EditorInterface.get_editor_theme().get_icon("Close", Yggdrasil.ICON_THEME), 1)
	item.set_button_tooltip_text(0, 1, "Delete Node")
	item.set_metadata(0, node)

func _on_node_deleted(node: YggdrasilNodeButton):
	if node.type == YggdrasilNode.NodeType.DECORATION:
		var id = "Decoration %d" % node.id
		for child in _decorations.get_children():
			if child.get_text(0) == id:
				_decorations.remove_child(child)
				return
	else:
		var id = "Node %d" % node.id
		for child in _nodes.get_children():
			if child.get_text(0) == id:
				_nodes.remove_child(child)
				return

func _on_item_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	var node = item.get_metadata(0)
	if id == 0:
		if node.locked:
			node.locked = false
			item.set_button(0, 0, EditorInterface.get_editor_theme().get_icon("Unlock", Yggdrasil.ICON_THEME))
			item.set_button_tooltip_text(0, 0, "Lock Node")
		else:
			node.locked = true
			item.set_button(0, 0, EditorInterface.get_editor_theme().get_icon("Lock", Yggdrasil.ICON_THEME))
			item.set_button_tooltip_text(0, 0, "Unlock Node")
		changed.emit()
	elif id == 1:
		editor.undo_redo.create_action("Delete Node")
		editor.undo_redo.add_do_method(editor.delete_node.bind(node))
		editor.undo_redo.add_undo_method(editor.undo_delete_node.bind(node))
		editor.undo_redo.commit_action()
