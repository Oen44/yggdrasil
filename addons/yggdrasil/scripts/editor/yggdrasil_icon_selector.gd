@tool
class_name YggdrasilIconSelector
extends Popup

signal icon_selected(node_type: int, texture: Texture2D, region: Vector2)

@export var icon_type_dropdown: OptionButton
@export var path_input: LineEdit
@export var browse_button: Button
@export var clear_button: Button
@export var icons_list: ItemList
@export var apply_button: Button
@export var close_button: Button
@export var editor: YggdrasilEditor

func init():
	browse_button.pressed.connect(_on_browse_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	icons_list.item_activated.connect(_on_icon_selected)
	apply_button.pressed.connect(_on_apply_pressed)
	close_button.pressed.connect(_on_close_pressed)

func load_icons(node_type: YggdrasilNode.NodeType):
	icons_list.clear()
	icon_type_dropdown.selected = node_type

	var icons_texture = editor.tree.icons[node_type]
	if not icons_texture:
		path_input.text = ""
		clear_button.hide()
		return
	
	var icon_size = editor.tree.icon_sizes[node_type]
	if icon_size == Vector2.ZERO:
		return
	
	icons_list.fixed_icon_size = icon_size
	clear_button.show()
	path_input.text = icons_texture.resource_path

	var columns = floor(icons_texture.get_width() / icon_size.x)
	var rows = floor(icons_texture.get_height() / icon_size.y)
	for y in range(rows):
		for x in range(columns):
			var region = Rect2(x * icon_size.x, y * icon_size.y, icon_size.x, icon_size.y)
			if _is_region_empty(icons_texture, region):
				continue
			
			var icon = AtlasTexture.new()
			icon.atlas = icons_texture
			icon.region = region
			icons_list.add_icon_item(icon)

func _is_region_empty(texture: Texture2D, region: Rect2) -> bool:
	var img = texture.get_image()
	for y in range(region.size.y):
		for x in range(region.size.x):
			var pixel = img.get_pixel(region.position.x + x, region.position.y + y)
			if pixel.a > 0:
				return false
	return true

func _on_browse_pressed():
	EditorInterface.popup_quick_open(_on_icon_texture_selected, ["Texture2D"])

func _on_clear_pressed():
	path_input.text = ""
	clear_button.hide()

func _on_icon_selected(index: int):
	_on_apply_pressed()

func _on_apply_pressed():
	var texture = ResourceLoader.load(path_input.text, "Texture2D")
	icon_selected.emit(icon_type_dropdown.selected, texture, _get_selected_region(texture))
	hide()

func _on_close_pressed():
	hide()

func _on_icon_texture_selected(path: String):
	hide()
	await get_tree().create_timer(0.1).timeout
	popup()

	var texture = ResourceLoader.load(path)

	var node_type = icon_type_dropdown.selected
	editor.tree.icons[node_type] = texture
	path_input.text = path
	clear_button.show()
	
	load_icons(node_type)

func _get_selected_region(texture: Texture2D) -> Vector2:
	var selected = icons_list.get_selected_items()
	if selected.is_empty():
		return Vector2.ZERO
	
	var index = selected[0]
	var icon_size = editor.tree.icon_sizes[icon_type_dropdown.selected]
	var columns = floori(texture.get_width() / icon_size.x)
	var x = (index % columns) * icon_size.x
	var y = floori(index / columns) * icon_size.y
	return Vector2(x, y)
