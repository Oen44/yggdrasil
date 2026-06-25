@tool
extends Button

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")

@export var icon_name: String = "Node":
	set(value):
		icon_name = value
		_update_icon()

func _enter_tree():
	_update_icon()

func _update_icon():
	if not Engine.is_editor_hint():
		return
	
	if EditorInterface.get_editor_theme().has_icon(icon_name, Yggdrasil.ICON_THEME):
		icon = EditorInterface.get_editor_theme().get_icon(icon_name, Yggdrasil.ICON_THEME)
	else:
		icon = null
