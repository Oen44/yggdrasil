@tool
extends EditorPlugin

const MainScreen = preload("res://addons/node_tree_toolkit/scenes/main_screen.tscn")

var _main_screen_instance = null

func _enable_plugin():
	pass

func _disable_plugin():
	pass

func _enter_tree():
	_main_screen_instance = MainScreen.instantiate()
	EditorInterface.get_editor_main_screen().add_child(_main_screen_instance)
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

func _get_plugin_name():
	return "Node Tree"

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")