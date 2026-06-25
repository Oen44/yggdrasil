@tool
extends EditorPlugin

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")

var _distraction = false
var _scene_container = null

var _main_screen_instance: YggdrasilMainScreen = null
var _dirty_trees = {}

func _enable_plugin():
	add_autoload_singleton("YggdrasilLoader", Yggdrasil.Loader)
	add_autoload_singleton("YggdrasilSerializer", Yggdrasil.Serializer)

func _disable_plugin():
	remove_autoload_singleton("YggdrasilLoader")
	remove_autoload_singleton("YggdrasilSerializer")

func _enter_tree():
	_distraction = EditorInterface.distraction_free_mode
	_scene_container = EditorInterface.get_base_control().find_children("*", "EditorSceneTabs", true, false)[0]
	
	if not ProjectSettings.has_setting(Yggdrasil.ROOT_PATH_SETTING):
		ProjectSettings.set_setting(Yggdrasil.ROOT_PATH_SETTING, Yggdrasil.DEFAULT_ROOT_PATH)

	ProjectSettings.set_as_basic(Yggdrasil.ROOT_PATH_SETTING, true)
	ProjectSettings.set_initial_value(Yggdrasil.ROOT_PATH_SETTING, Yggdrasil.DEFAULT_ROOT_PATH)

	if not ProjectSettings.has_setting(Yggdrasil.REGISTRY_FILENAME_SETTING):
		ProjectSettings.set_setting(Yggdrasil.REGISTRY_FILENAME_SETTING, Yggdrasil.DEFAULT_REGISTRY_FILENAME)

	ProjectSettings.set_as_basic(Yggdrasil.REGISTRY_FILENAME_SETTING, true)
	ProjectSettings.set_initial_value(Yggdrasil.REGISTRY_FILENAME_SETTING, Yggdrasil.DEFAULT_REGISTRY_FILENAME)

	var property_info = {
		"name": Yggdrasil.ROOT_PATH_SETTING,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR,
		"hint_string": "res://"
	}
	ProjectSettings.add_property_info(property_info)
	
	_main_screen_instance = Yggdrasil.MainScreen.instantiate()
	EditorInterface.get_editor_main_screen().add_child(_main_screen_instance)
	
	_main_screen_instance.dirty_changed.connect(_on_tree_dirty_changed)
	_main_screen_instance.tree_closed.connect(_on_tree_closed)
	_make_visible(false)

func _exit_tree():
	if _main_screen_instance:
		_main_screen_instance.queue_free()
		_main_screen_instance = null

func _has_main_screen():
	return true

func _make_visible(visible):
	if _main_screen_instance:
		_main_screen_instance.visible = visible
		_scene_container.visible = not visible
		if visible:
			if not _main_screen_instance.initialized:
				_main_screen_instance.init()
			_distraction = EditorInterface.distraction_free_mode
			EditorInterface.distraction_free_mode = true
		else:
			EditorInterface.distraction_free_mode = _distraction

func _get_plugin_name():
	return "Yggdrasil"

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", Yggdrasil.ICON_THEME)

func _on_tree_dirty_changed(editor: YggdrasilEditor, dirty: bool):
	if dirty:
		_dirty_trees[editor] = true
	else:
		_dirty_trees.erase(editor)

func _on_tree_closed(editor: YggdrasilEditor):
	_dirty_trees.erase(editor)

func _get_unsaved_status(for_scene: String) -> String:
	if _dirty_trees.size() > 0 and _main_screen_instance.visible:
		var trees = ""
		for editor in _dirty_trees.keys():
			trees += "%s, " % editor.name
		trees = trees.substr(0, trees.length() - 2)
		return "Unsaved changes found: %s" % trees
	
	return ""

func _save_external_data():
	for editor in _dirty_trees.keys():
		editor.save_tree()
