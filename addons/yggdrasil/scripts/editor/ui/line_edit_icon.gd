@tool
extends LineEdit

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")

@export var icon: String = "Node":
	set(value):
		icon = value
		_update_icon()

func _enter_tree():
	_update_icon()

func _update_icon():
	if has_theme_icon(icon, Yggdrasil.ICON_THEME):
		right_icon = get_theme_icon(icon, Yggdrasil.ICON_THEME)
	else:
		right_icon = null
