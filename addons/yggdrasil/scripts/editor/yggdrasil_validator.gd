@tool
class_name YggdrasilValidator
extends Control

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")
const FadeOut = preload("res://addons/yggdrasil/scripts/editor/ui/fade_out.gd")

@export var editor: YggdrasilEditor

@export var prints_container: Control
@export var warning_btn: Button
@export var error_btn: Button

enum WarningEntry {
	TREE_WIDTH_TOO_SMALL,
	TREE_HEIGHT_TOO_SMALL,
	BORDER_SCALE_INVALID,
	NORMAL_LINE_TEXTURE_NOT_SET,
	INTERMEDIATE_LINE_TEXTURE_NOT_SET,
	ACTIVE_LINE_TEXTURE_NOT_SET,
	PREALLOCATION_WITHOUT_ALLOCATION,
	MULTIALLOCATION_WITHOUT_ALLOCATION,
}

enum ErrorEntry {
	NO_ROOT_NODE,
	SMALL_ICON_SIZE_INVALID,
	MEDIUM_ICON_SIZE_INVALID,
	LARGE_ICON_SIZE_INVALID,
	SMALL_NODE_SIZE_INVALID,
	MEDIUM_NODE_SIZE_INVALID,
	LARGE_NODE_SIZE_INVALID,
}

const WarningMessages = {
	WarningEntry.TREE_WIDTH_TOO_SMALL: "Tree width is too small. Recommended at least 100 pixels.",
	WarningEntry.TREE_HEIGHT_TOO_SMALL: "Tree height is too small. Recommended at least 100 pixels.",
	WarningEntry.BORDER_SCALE_INVALID: "Border scale is invalid. Recommended at least 0.1.",
	WarningEntry.NORMAL_LINE_TEXTURE_NOT_SET: "Normal line texture is not set.",
	WarningEntry.INTERMEDIATE_LINE_TEXTURE_NOT_SET: "Intermediate line texture is not set.",
	WarningEntry.ACTIVE_LINE_TEXTURE_NOT_SET: "Active line texture is not set.",
	WarningEntry.PREALLOCATION_WITHOUT_ALLOCATION: "Pre-allocation is enabled without allocation.",
	WarningEntry.MULTIALLOCATION_WITHOUT_ALLOCATION: "Multi-allocation is enabled without allocation.",
}

const ErrorMessages = {
	ErrorEntry.NO_ROOT_NODE: "No root node is set. Select at least one node as root.",
	ErrorEntry.SMALL_ICON_SIZE_INVALID: "Small icon size is invalid. Recommended at least 1 pixel.",
	ErrorEntry.MEDIUM_ICON_SIZE_INVALID: "Medium icon size is invalid. Recommended at least 1 pixel.",
	ErrorEntry.LARGE_ICON_SIZE_INVALID: "Large icon size is invalid. Recommended at least 1 pixel.",
	ErrorEntry.SMALL_NODE_SIZE_INVALID: "Small node size is invalid. Recommended at least 1 pixel.",
	ErrorEntry.MEDIUM_NODE_SIZE_INVALID: "Medium node size is invalid. Recommended at least 1 pixel.",
	ErrorEntry.LARGE_NODE_SIZE_INVALID: "Large node size is invalid. Recommended at least 1 pixel.",
}

# Delayed validation to prevent spam
const VALIDATION_DELAY = 500 # milliseconds
var _validation_start: float = 0.0
var _validation_scheduled: bool = false

var _warnings: Array[WarningEntry]
var _errors: Array[ErrorEntry]

func init():
	prints_container.visible = false
	warning_btn.visible = false
	error_btn.visible = false
	warning_btn.pressed.connect(_on_warning_btn_pressed)
	error_btn.pressed.connect(_on_error_btn_pressed)

func _process(delta):
	if _validation_scheduled and Time.get_ticks_msec() - _validation_start >= VALIDATION_DELAY:
		_run_validation()
		_validation_scheduled = false

func _on_warning_btn_pressed():
	prints_container.visible = true
	var color = get_theme_color("warning_color", &"Editor")
	var icon = EditorInterface.get_editor_theme().get_icon("StatusWarning", Yggdrasil.ICON_THEME)

	for warning in _warnings:
		_create_info_panel(icon, color, WarningMessages[warning])

func _on_error_btn_pressed():
	prints_container.visible = true
	var color = get_theme_color("error_color", &"Editor")
	var icon = EditorInterface.get_editor_theme().get_icon("StatusError", Yggdrasil.ICON_THEME)

	for error in _errors:
		_create_info_panel(icon, color, ErrorMessages[error])

func _create_info_panel(icon: Texture2D, color: Color, message: String):
	var panel_container = FadeOut.new()
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.fit_content = true
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_image(icon)
	label.append_text(" ")
	label.push_color(color)
	label.append_text(message)
	label.pop()
	panel_container.add_child(label)
	prints_container.add_child(panel_container)

func validate():
	_validation_start = Time.get_ticks_msec()
	_validation_scheduled = true

func _run_validation():
	# Warnings first
	_warnings = []
	if editor.tree.size.x < 100:
		_warnings.append(WarningEntry.TREE_WIDTH_TOO_SMALL)
	if editor.tree.size.y < 100:
		_warnings.append(WarningEntry.TREE_HEIGHT_TOO_SMALL)
	if editor.tree.border_scale < 0.1:
		_warnings.append(WarningEntry.BORDER_SCALE_INVALID)
	if not editor.tree.line_texture_normal:
		_warnings.append(WarningEntry.NORMAL_LINE_TEXTURE_NOT_SET)
	if not editor.tree.line_texture_intermediate:
		_warnings.append(WarningEntry.INTERMEDIATE_LINE_TEXTURE_NOT_SET)
	if not editor.tree.line_texture_active:
		_warnings.append(WarningEntry.ACTIVE_LINE_TEXTURE_NOT_SET)
	if editor.tree.preallocation and not editor.tree.allocation:
		_warnings.append(WarningEntry.PREALLOCATION_WITHOUT_ALLOCATION)
	if editor.tree.multiallocation and not editor.tree.allocation:
		_warnings.append(WarningEntry.MULTIALLOCATION_WITHOUT_ALLOCATION)
	
	warning_btn.text = str(_warnings.size())

	# Errors
	_errors = []
	if editor.tree.allocation:
		var root_found = false
		for node_data in editor.tree.nodes:
			if node_data.is_root:
				root_found = true
				break
		if not root_found:
			_errors.append(ErrorEntry.NO_ROOT_NODE)
	if editor.tree.icon_sizes[YggdrasilNode.NodeType.SMALL].length_squared() < 2:
		_errors.append(ErrorEntry.SMALL_ICON_SIZE_INVALID)
	if editor.tree.icon_sizes[YggdrasilNode.NodeType.MEDIUM].length_squared() < 2:
		_errors.append(ErrorEntry.MEDIUM_ICON_SIZE_INVALID)
	if editor.tree.icon_sizes[YggdrasilNode.NodeType.LARGE].length_squared() < 2:
		_errors.append(ErrorEntry.LARGE_ICON_SIZE_INVALID)
	if editor.tree.node_size[YggdrasilNode.NodeType.SMALL].length_squared() < 2:
		_errors.append(ErrorEntry.SMALL_NODE_SIZE_INVALID)
	if editor.tree.node_size[YggdrasilNode.NodeType.MEDIUM].length_squared() < 2:
		_errors.append(ErrorEntry.MEDIUM_NODE_SIZE_INVALID)
	if editor.tree.node_size[YggdrasilNode.NodeType.LARGE].length_squared() < 2:
		_errors.append(ErrorEntry.LARGE_NODE_SIZE_INVALID)
		
	error_btn.text = str(_errors.size())

	visible = _warnings.size() > 0 or _errors.size() > 0
	warning_btn.visible = _warnings.size() > 0
	error_btn.visible = _errors.size() > 0
