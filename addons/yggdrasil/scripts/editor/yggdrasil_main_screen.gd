@tool
class_name YggdrasilMainScreen
extends Control

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")

signal update_available(version: String)
signal dirty_changed(editor: YggdrasilEditor, dirty: bool)
signal tree_closed(editor: YggdrasilEditor)

@export var tab_container: TabContainer
@export var browser: YggdrasilBrowser
@export var editor_scene: PackedScene
@export var save_confirmation: ConfirmationDialog
@export var http_request: HTTPRequest

var initialized = false

var _open_editors: Array[YggdrasilEditor] = []

const UPDATE_INTERVAL = 5 * 1000 # 5 seconds
var _last_update_check: int = 0

func init():
	initialized = true
	browser.init()
	
	tab_container.set_tab_title(0, "")
	tab_container.set_tab_icon(0, get_theme_icon("Add", Yggdrasil.ICON_THEME))
	tab_container.tab_button_pressed.connect(_on_tab_button_pressed)
	
	save_confirmation.add_button("Don't Save", true, "no_save")
	save_confirmation.custom_action.connect(_dont_save)
	save_confirmation.confirmed.connect(_confirm_save)
	
	http_request.request_completed.connect(_on_request_completed)
	_check_for_updates()

func open_tree(path: String):
	var tree_resource = YggdrasilLoader.load_tree(path)

	for i in range(_open_editors.size()):
		var open_editor = _open_editors[i]
		if open_editor.tree.resource_path == path:
			tab_container.current_tab = i
			return

	var editor: YggdrasilEditor = editor_scene.instantiate()
	editor.name = tree_resource.name
	tab_container.add_child(editor)

	var editor_index = tab_container.get_tab_count() - 2
	tab_container.move_child(editor, editor_index)
	tab_container.set_tab_title(editor_index, tree_resource.name)
	tab_container.set_tab_button_icon(editor_index, get_theme_icon("Close", Yggdrasil.ICON_THEME))
	
	editor.init()
	editor.tree_closed.connect(_on_tree_closed)
	editor.edit_tree(path)
	editor.dirty_changed.connect(_on_tree_dirty_changed)

	tab_container.current_tab = editor_index
	_open_editors.append(editor)
	_check_for_updates()

func _on_tree_closed(editor: YggdrasilEditor):
	_open_editors.erase(editor)
	tree_closed.emit(editor)
	editor.queue_free()
	_check_for_updates()

func _on_tree_dirty_changed(editor: YggdrasilEditor, dirty: bool):
	var index = editor.get_index()
	if dirty:
		tab_container.set_tab_title(index, "%s(*)" % editor.tree.name)
	else:
		tab_container.set_tab_title(index, editor.tree.name)
	dirty_changed.emit(editor, dirty)

func _on_tab_button_pressed(tab_index: int):
	var editor: YggdrasilEditor = tab_container.get_child(tab_index)
	_show_close_confirmation(editor)

func _show_close_confirmation(editor: YggdrasilEditor):
	if editor.dirty:
		save_confirmation.dialog_text = "Tree \"%s\" has unsaved changes.\nLast saved: %s\n\nSave before closing?" % [editor.tree.name, editor.get_last_modified_time()]
		save_confirmation.popup_centered()
		save_confirmation.set_meta("editor", editor)
	else:
		editor.close_tree()

func _confirm_save():
	var editor: YggdrasilEditor = save_confirmation.get_meta("editor")
	ResourceSaver.save(editor.tree, editor.tree.resource_path)
	EditorInterface.get_resource_filesystem().scan()
	editor.close_tree()

func _dont_save(_action: String):
	var editor: YggdrasilEditor = save_confirmation.get_meta("editor")
	editor.close_tree()
	save_confirmation.hide()

func _check_for_updates():
	var time = Time.get_ticks_msec()
	if time - _last_update_check < UPDATE_INTERVAL:
		return
	
	_last_update_check = time
	http_request.request("https://api.github.com/repos/Oen44/yggdrasil/releases/latest")

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return
	
	var json = JSON.parse_string(body.get_string_from_utf8())
	if not json:
		return
	
	var tag: String = json.tag_name
	var version = tag.substr(1)
	if Yggdrasil.get_version_number() < Yggdrasil.get_version_number(version):
		update_available.emit(version)
