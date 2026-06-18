@tool
extends Button

@export var icon_name: String = "Node":
	set(value):
		icon_name = value
		_update_icon()

const theme_name: StringName = &"EditorIcons"

func _enter_tree():
	_update_icon()

func _update_icon():
	if not Engine.is_editor_hint():
		return
	
	if EditorInterface.get_editor_theme().has_icon(icon_name, theme_name):
		icon = EditorInterface.get_editor_theme().get_icon(icon_name, theme_name)
	else:
		icon = null
