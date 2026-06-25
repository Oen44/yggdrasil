@tool
class_name YggdrasilSettingsEditor
extends Control

signal changed
signal size_changed
signal border_scale_changed
signal background_changed
signal icon_size_changed
signal node_size_changed
signal line_texture_changed
signal revealed_changed
signal allocation_changed
signal preallocation_changed
signal multiallocation_changed

@export var editor: YggdrasilEditor

@export_group("Version")
@export var version_input: SpinBox
@export_group("Size")
@export var size_x_input: SpinBox
@export var size_y_input: SpinBox
@export_group("Border")
@export var border_scale_input: SpinBox
@export_group("Background")
@export var bg_color_picker: ColorPickerButton
@export var bg_texture_input: InspectorTextureInput
@export_group("Icon Size")
@export var small_icon_x_input: SpinBox
@export var small_icon_y_input: SpinBox
@export var medium_icon_x_input: SpinBox
@export var medium_icon_y_input: SpinBox
@export var large_icon_x_input: SpinBox
@export var large_icon_y_input: SpinBox
@export_group("Node Size")
@export var small_size_x_input: SpinBox
@export var small_size_y_input: SpinBox
@export var medium_size_x_input: SpinBox
@export var medium_size_y_input: SpinBox
@export var large_size_x_input: SpinBox
@export var large_size_y_input: SpinBox
@export_group("Line Textures")
@export var line_normal_input: InspectorTextureInput
@export var line_intermediate_input: InspectorTextureInput
@export var line_active_input: InspectorTextureInput
@export_group("Interaction")
@export var revelead_checkbox: CheckBox
@export var allocation_checkbox: CheckBox
@export var preallocation_checkbox: CheckBox
@export var multiallocation_checkbox: CheckBox

func init():
	version_input.value_changed.connect(_on_version_changed)

	size_x_input.value_changed.connect(_on_size_changed)
	size_y_input.value_changed.connect(_on_size_changed)

	border_scale_input.value_changed.connect(_on_border_scale_changed)

	bg_color_picker.color_changed.connect(_on_bg_color_changed)
	bg_texture_input.load_button.pressed.connect(func():
		EditorInterface.popup_quick_open(_on_bg_texture_changed, ["Texture2D"])
	)
	bg_texture_input.clear_button.pressed.connect(_on_bg_texture_cleared)
	bg_texture_input.texture_dropped.connect(_on_bg_texture_changed)

	small_icon_x_input.value_changed.connect(_on_small_icon_size_changed)
	small_icon_y_input.value_changed.connect(_on_small_icon_size_changed)
	medium_icon_x_input.value_changed.connect(_on_medium_icon_size_changed)
	medium_icon_y_input.value_changed.connect(_on_medium_icon_size_changed)
	large_icon_x_input.value_changed.connect(_on_large_icon_size_changed)
	large_icon_y_input.value_changed.connect(_on_large_icon_size_changed)

	small_size_x_input.value_changed.connect(_on_small_size_changed)
	small_size_y_input.value_changed.connect(_on_small_size_changed)
	medium_size_x_input.value_changed.connect(_on_medium_size_changed)
	medium_size_y_input.value_changed.connect(_on_medium_size_changed)
	large_size_x_input.value_changed.connect(_on_large_size_changed)
	large_size_y_input.value_changed.connect(_on_large_size_changed)

	line_normal_input.load_button.pressed.connect(func():
		EditorInterface.popup_quick_open(_on_line_normal_changed, ["Texture2D"])
	)
	line_normal_input.clear_button.pressed.connect(_on_line_normal_cleared)
	line_normal_input.texture_dropped.connect(_on_line_normal_changed)

	line_intermediate_input.load_button.pressed.connect(func():
		EditorInterface.popup_quick_open(_on_line_intermediate_changed, ["Texture2D"])
	)
	line_intermediate_input.clear_button.pressed.connect(_on_line_intermediate_cleared)
	line_intermediate_input.texture_dropped.connect(_on_line_intermediate_changed)

	line_active_input.load_button.pressed.connect(func():
		EditorInterface.popup_quick_open(_on_line_active_changed, ["Texture2D"])
	)
	line_active_input.clear_button.pressed.connect(_on_line_active_cleared)
	line_active_input.texture_dropped.connect(_on_line_active_changed)

	revelead_checkbox.toggled.connect(_on_revealed_toggled)
	allocation_checkbox.toggled.connect(_on_allocation_toggled)
	preallocation_checkbox.toggled.connect(_on_preallocation_toggled)
	multiallocation_checkbox.toggled.connect(_on_multiallocation_toggled)

func load_tree(tree_data: YggdrasilTree):
	version_input.set_value_no_signal(tree_data.version)

	size_x_input.set_value_no_signal(tree_data.size.x)
	size_y_input.set_value_no_signal(tree_data.size.y)

	border_scale_input.set_value_no_signal(tree_data.border_scale)
	
	bg_color_picker.color = tree_data.bg_color

	if tree_data.bg_texture:
		bg_texture_input.texture_rect.texture = tree_data.bg_texture
		bg_texture_input.empty_label.hide()
		bg_texture_input.clear_button.show()
	else:
		bg_texture_input.texture_rect.texture = null
		bg_texture_input.empty_label.show()
		bg_texture_input.clear_button.hide()

	small_icon_x_input.set_value_no_signal(tree_data.icon_sizes[YggdrasilNode.NodeType.SMALL].x)
	small_icon_y_input.set_value_no_signal(tree_data.icon_sizes[YggdrasilNode.NodeType.SMALL].y)
	medium_icon_x_input.set_value_no_signal(tree_data.icon_sizes[YggdrasilNode.NodeType.MEDIUM].x)
	medium_icon_y_input.set_value_no_signal(tree_data.icon_sizes[YggdrasilNode.NodeType.MEDIUM].y)
	large_icon_x_input.set_value_no_signal(tree_data.icon_sizes[YggdrasilNode.NodeType.LARGE].x)
	large_icon_y_input.set_value_no_signal(tree_data.icon_sizes[YggdrasilNode.NodeType.LARGE].y)

	small_size_x_input.set_value_no_signal(tree_data.node_size[YggdrasilNode.NodeType.SMALL].x)
	small_size_y_input.set_value_no_signal(tree_data.node_size[YggdrasilNode.NodeType.SMALL].y)
	medium_size_x_input.set_value_no_signal(tree_data.node_size[YggdrasilNode.NodeType.MEDIUM].x)
	medium_size_y_input.set_value_no_signal(tree_data.node_size[YggdrasilNode.NodeType.MEDIUM].y)
	large_size_x_input.set_value_no_signal(tree_data.node_size[YggdrasilNode.NodeType.LARGE].x)
	large_size_y_input.set_value_no_signal(tree_data.node_size[YggdrasilNode.NodeType.LARGE].y)

	line_normal_input.texture_rect.texture = tree_data.line_texture_normal
	if tree_data.line_texture_normal:
		line_normal_input.empty_label.hide()
		line_normal_input.clear_button.show()
	else:
		line_normal_input.texture_rect.texture = null
		line_normal_input.empty_label.show()
		line_normal_input.clear_button.hide()

	line_intermediate_input.texture_rect.texture = tree_data.line_texture_intermediate
	if tree_data.line_texture_intermediate:
		line_intermediate_input.empty_label.hide()
		line_intermediate_input.clear_button.show()
	else:
		line_intermediate_input.texture_rect.texture = null
		line_intermediate_input.empty_label.show()
		line_intermediate_input.clear_button.hide()

	line_active_input.texture_rect.texture = tree_data.line_texture_active
	if tree_data.line_texture_active:
		line_active_input.empty_label.hide()
		line_active_input.clear_button.show()
	else:
		line_active_input.texture_rect.texture = null
		line_active_input.empty_label.show()
		line_active_input.clear_button.hide()
	
	revelead_checkbox.set_pressed_no_signal(tree_data.revealed)
	allocation_checkbox.set_pressed_no_signal(tree_data.allocation)
	preallocation_checkbox.set_pressed_no_signal(tree_data.preallocation)
	multiallocation_checkbox.set_pressed_no_signal(tree_data.multiallocation)

func _on_version_changed(value: float):
	editor.tree.version = int(version_input.value)
	changed.emit()

func _on_size_changed(value: float):
	editor.tree.size = Vector2(size_x_input.value, size_y_input.value)
	size_changed.emit()
	changed.emit()

func _on_border_scale_changed(value: float):
	editor.tree.border_scale = border_scale_input.value
	border_scale_changed.emit()
	changed.emit()

func _on_bg_color_changed(color: Color):
	editor.tree.bg_color = color
	background_changed.emit()
	changed.emit()

func _on_bg_texture_changed(path: String):
	if path.is_empty():
		bg_texture_input.clear_button.hide()
		bg_texture_input.empty_label.show()
	else:
		var texture = ResourceLoader.load(path)
		if texture and texture is Texture2D:
			bg_texture_input.texture_rect.texture = texture
			editor.tree.bg_texture = texture
			bg_texture_input.empty_label.hide()
			bg_texture_input.clear_button.show()
	background_changed.emit()
	changed.emit()

func _on_bg_texture_cleared():
	bg_texture_input.texture_rect.texture = null
	editor.tree.bg_texture = null
	bg_texture_input.empty_label.show()
	bg_texture_input.clear_button.hide()
	background_changed.emit()
	changed.emit()

func _on_small_icon_size_changed(value: float):
	editor.tree.icon_sizes[YggdrasilNode.NodeType.SMALL] = Vector2(small_icon_x_input.value, small_icon_y_input.value)
	icon_size_changed.emit()
	changed.emit()

func _on_medium_icon_size_changed(value: float):
	editor.tree.icon_sizes[YggdrasilNode.NodeType.MEDIUM] = Vector2(medium_icon_x_input.value, medium_icon_y_input.value)
	icon_size_changed.emit()
	changed.emit()

func _on_large_icon_size_changed(value: float):
	editor.tree.icon_sizes[YggdrasilNode.NodeType.LARGE] = Vector2(large_icon_x_input.value, large_icon_y_input.value)
	icon_size_changed.emit()
	changed.emit()

func _on_small_size_changed(value: float):
	editor.tree.node_size[YggdrasilNode.NodeType.SMALL] = Vector2(small_size_x_input.value, small_size_y_input.value)
	node_size_changed.emit()
	changed.emit()

func _on_medium_size_changed(value: float):
	editor.tree.node_size[YggdrasilNode.NodeType.MEDIUM] = Vector2(medium_size_x_input.value, medium_size_y_input.value)
	node_size_changed.emit()
	changed.emit()

func _on_large_size_changed(value: float):
	editor.tree.node_size[YggdrasilNode.NodeType.LARGE] = Vector2(large_size_x_input.value, large_size_y_input.value)
	node_size_changed.emit()
	changed.emit()

func _on_line_normal_changed(path: String):
	if path.is_empty():
		_on_line_normal_cleared()
		return
	
	var texture = ResourceLoader.load(path)
	if texture and texture is Texture2D:
		line_normal_input.texture_rect.texture = texture
		editor.tree.line_texture_normal = texture
		line_normal_input.empty_label.hide()
		line_normal_input.clear_button.show()
	line_texture_changed.emit()
	changed.emit()

func _on_line_normal_cleared():
	line_normal_input.texture_rect.texture = null
	editor.tree.line_texture_normal = null
	line_normal_input.empty_label.show()
	line_normal_input.clear_button.hide()
	line_texture_changed.emit()
	changed.emit()

func _on_line_intermediate_changed(path: String):
	if path.is_empty():
		_on_line_intermediate_cleared()
		return
	
	var texture = ResourceLoader.load(path)
	if texture and texture is Texture2D:
		line_intermediate_input.texture_rect.texture = texture
		editor.tree.line_texture_intermediate = texture
		line_intermediate_input.empty_label.hide()
		line_intermediate_input.clear_button.show()
	line_texture_changed.emit()
	changed.emit()

func _on_line_intermediate_cleared():
	line_intermediate_input.texture_rect.texture = null
	editor.tree.line_texture_intermediate = null
	line_intermediate_input.empty_label.show()
	line_intermediate_input.clear_button.hide()
	line_texture_changed.emit()
	changed.emit()

func _on_line_active_changed(path: String):
	if path.is_empty():
		_on_line_active_cleared()
		return
	
	var texture = ResourceLoader.load(path)
	if texture and texture is Texture2D:
		line_active_input.texture_rect.texture = texture
		editor.tree.line_texture_active = texture
		line_active_input.empty_label.hide()
		line_active_input.clear_button.show()
	line_texture_changed.emit()
	changed.emit()

func _on_line_active_cleared():
	line_active_input.texture_rect.texture = null
	editor.tree.line_texture_active = null
	line_active_input.empty_label.show()
	line_active_input.clear_button.hide()
	line_texture_changed.emit()
	changed.emit()

func _on_revealed_toggled(toggled_on: bool):
	editor.tree.revealed = toggled_on
	revealed_changed.emit()
	changed.emit()

func _on_allocation_toggled(toggled_on: bool):
	editor.tree.allocation = toggled_on
	allocation_changed.emit()
	changed.emit()

func _on_preallocation_toggled(toggled_on: bool):
	editor.tree.preallocation = toggled_on
	preallocation_changed.emit()
	changed.emit()

func _on_multiallocation_toggled(toggled_on: bool):
	multiallocation_checkbox.set_pressed_no_signal(not toggled_on)

	var confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.dialog_text = "Are you sure you want to change the multi-allocation setting?\nThis will remove attributes from all nodes and prefabs."
	confirmation_dialog.cancel_button_text = "Cancel"
	confirmation_dialog.ok_button_text = "Enable" if toggled_on else "Disable"
	confirmation_dialog.canceled.connect(func():
		confirmation_dialog.queue_free()
	)
	confirmation_dialog.confirmed.connect(func():
		editor.tree.multiallocation = toggled_on
		multiallocation_changed.emit()
		changed.emit()
		multiallocation_checkbox.set_pressed_no_signal(toggled_on)
		confirmation_dialog.queue_free()
	)
	add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()
