@tool
class_name YggdrasilBrowser
extends Control

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")
const FuzzySearch = Yggdrasil.FuzzySearch

@export var main_screen: YggdrasilMainScreen

@export_group("UI")
@export var tree_ui: YggdrasilTreeUI
@export var search_bar: LineEdit
@export var group_menu: MenuButton
@export var tree_menu: MenuButton
@export var load_time_label: Label
@export var groups_count_label: Label
@export var trees_count_label: Label
@export var version_label: Label
@export var delete_confirmation: ConfirmationDialog
@export var docs_button: Button

@export_group("Shortcuts")
@export var delete_shortcut: Shortcut
@export var new_group_shortcut: Shortcut
@export var new_tree_shortcut: Shortcut
@export var duplicate_shortcut: Shortcut

var _fuzzy: FuzzySearch = FuzzySearch.new()

enum MenuOption {
	CREATE_ITEM,
	DELETE_ITEM,
	DUPLICATE_ITEM
}

func init():
	var start_time = Time.get_ticks_usec()
	tree_ui.clear()
	tree_ui.init()

	_connect_signals()
	_read_registry()
	_populate_menus()
	
	docs_button.pressed.connect(func(): OS.shell_open("https://oen44.github.io/yggdrasil"))

	var end_time = Time.get_ticks_usec()
	var load_time = (end_time - start_time) / 1_000_000.
	load_time_label.text = "Load time: %.2fs" % load_time
	version_label.text = "v%s" % Yggdrasil.VERSION

func _connect_signals():
	search_bar.text_changed.connect(_on_search_text_changed)

	tree_ui.item_selected.connect(_on_item_selected)
	tree_ui.item_activated.connect(_on_item_activated)
	tree_ui.item_edited.connect(_on_item_edited)
	tree_ui.edit_canceled.connect(_on_edit_canceled)
	tree_ui.set_drag_forwarding(_tree_get_drag_data, _tree_can_drop_data, _tree_drop_data)

	delete_confirmation.confirmed.connect(_confirm_delete)

func _read_registry():
	var registry = YggdrasilLoader.get_registry()

	for group: YggdrasilGroup in registry.groups:
		_load_group(group)
	
	_on_group_added()
	_on_tree_added()

func _load_group(group: YggdrasilGroup):
	var root = tree_ui.get_root()
	var group_item = root.create_child()
	group_item.set_text(0, group.name)
	group_item.set_icon(0, get_theme_icon(Yggdrasil.GROUP_ICON, Yggdrasil.ICON_THEME))
	group_item.set_icon_modulate(0, Yggdrasil.COLOR_CODES[root.get_child_count() % Yggdrasil.COLOR_CODES.size()])
	group_item.set_metadata(0, {"uid": ResourceLoader.get_resource_uid(group.resource_path)})

	for tree_data in group.trees:
		_load_tree(group_item, tree_data)

func _load_tree(group_item: TreeItem, tree_data: YggdrasilTree):
	var data_item = group_item.create_child()
	data_item.set_text(0, tree_data.name)
	data_item.set_icon(0, get_theme_icon(Yggdrasil.TREE_ICON, Yggdrasil.ICON_THEME))
	data_item.set_icon_modulate(0, group_item.get_icon_modulate(0))
	data_item.set_metadata(0, {"uid": ResourceLoader.get_resource_uid(tree_data.resource_path)})

func _populate_menus():
	group_menu.get_popup().clear()
	tree_menu.get_popup().clear()

	group_menu.get_popup().id_pressed.connect(_on_group_menu_id_pressed)

	group_menu.get_popup().add_item("Create", MenuOption.CREATE_ITEM)
	group_menu.get_popup().set_item_shortcut(MenuOption.CREATE_ITEM, new_group_shortcut)

	group_menu.get_popup().add_item("Delete", MenuOption.DELETE_ITEM)
	group_menu.get_popup().set_item_shortcut(MenuOption.DELETE_ITEM, delete_shortcut)
	group_menu.get_popup().set_item_disabled(MenuOption.DELETE_ITEM, true)

	group_menu.get_popup().add_item("Duplicate", MenuOption.DUPLICATE_ITEM)
	group_menu.get_popup().set_item_shortcut(MenuOption.DUPLICATE_ITEM, duplicate_shortcut)
	group_menu.get_popup().set_item_disabled(MenuOption.DUPLICATE_ITEM, true)

	tree_menu.get_popup().id_pressed.connect(_on_tree_menu_id_pressed)

	tree_menu.get_popup().add_item("Create", MenuOption.CREATE_ITEM)
	tree_menu.get_popup().set_item_shortcut(MenuOption.CREATE_ITEM, new_tree_shortcut)
	tree_menu.get_popup().set_item_disabled(MenuOption.CREATE_ITEM, true)

	tree_menu.get_popup().add_item("Delete", MenuOption.DELETE_ITEM)
	tree_menu.get_popup().set_item_shortcut(MenuOption.DELETE_ITEM, delete_shortcut)
	tree_menu.get_popup().set_item_disabled(MenuOption.DELETE_ITEM, true)

	tree_menu.get_popup().add_item("Duplicate", MenuOption.DUPLICATE_ITEM)
	tree_menu.get_popup().set_item_shortcut(MenuOption.DUPLICATE_ITEM, duplicate_shortcut)
	tree_menu.get_popup().set_item_disabled(MenuOption.DUPLICATE_ITEM, true)

func _on_group_menu_id_pressed(id: int):
	match id:
		MenuOption.CREATE_ITEM:
			_create_new_group()
		MenuOption.DELETE_ITEM:
			_delete_group()
		MenuOption.DUPLICATE_ITEM:
			_duplicate_selected_item()

func _on_tree_menu_id_pressed(id: int):
	match id:
		MenuOption.CREATE_ITEM:
			_create_new_tree()
		MenuOption.DELETE_ITEM:
			_delete_tree()
		MenuOption.DUPLICATE_ITEM:
			_duplicate_selected_item()

func _create_new_group():
	var child = tree_ui.get_root().create_child()
	child.set_text(0, "New Group")
	child.set_icon(0, get_theme_icon(Yggdrasil.GROUP_ICON, Yggdrasil.ICON_THEME))
	child.set_icon_modulate(0, Yggdrasil.COLOR_CODES[tree_ui.get_root().get_child_count() % Yggdrasil.COLOR_CODES.size()])
	child.set_metadata(0, {"new_group": true})
	await get_tree().create_timer(0.01).timeout
	child.select(0)
	tree_ui.edit_selected(true)

func _create_new_tree():
	var selected = tree_ui.get_selected()
	var group_item: TreeItem
	if selected.get_parent() != tree_ui.get_root():
		group_item = selected.get_parent()
	else:
		group_item = selected
	
	var group_metadata = group_item.get_metadata(0)
	if not group_metadata or not group_metadata.has("uid"):
		return
	
	var child = group_item.create_child()
	child.set_text(0, "New Tree")
	child.set_icon(0, get_theme_icon(Yggdrasil.TREE_ICON, Yggdrasil.ICON_THEME))
	child.set_icon_modulate(0, group_item.get_icon_modulate(0))
	child.set_metadata(0, {"new_tree": true})
	await get_tree().create_timer(0.01).timeout
	child.select(0)
	tree_ui.edit_selected(true)

func _on_group_added():
	groups_count_label.text = "Total groups: %d" % tree_ui.get_root().get_child_count()

func _on_tree_added():
	var tree_count = 0
	for group_item in tree_ui.get_root().get_children():
		tree_count += group_item.get_child_count()
	trees_count_label.text = "Total trees: %d" % tree_count

func _on_search_text_changed(new_text: String):
	var search_text = new_text.strip_edges()
	if search_text.is_empty():
		for group_item in tree_ui.get_root().get_children():
			group_item.visible = true
			for tree_item in group_item.get_children():
				tree_item.visible = true
		return

	_fuzzy.set_query(search_text)
	
	var uids: Array[int] = []
	var uid_to_item: Dictionary = {}

	for group_item in tree_ui.get_root().get_children():
		var group_metadata = group_item.get_metadata(0)
		if not group_metadata or not group_metadata.has("uid"):
			continue
		
		var group_uid = group_metadata["uid"]
		var group_name = group_item.get_text(0)
		uid_to_item[group_uid] = group_item
		uids.append(group_uid)

		for tree_item in group_item.get_children():
			var tree_metadata = tree_item.get_metadata(0)
			if not tree_metadata or not tree_metadata.has("uid"):
				continue
			
			var tree_uid = tree_metadata["uid"]
			var tree_name = tree_item.get_text(0)
			uid_to_item[tree_uid] = tree_item
			uids.append(tree_uid)

	var targets = PackedStringArray(uids.map(func(uid: int) -> String: return uid_to_item[uid].get_text(0)))
	var results: Array[FuzzySearch.FuzzySearchResult] = []
	_fuzzy.search_all(targets, results)

	var result: Array[TreeItem] = []
	for r in results:
		result.append(uid_to_item[uids[r.original_index]])

	for group_item in tree_ui.get_root().get_children():
		group_item.visible = false
		for tree_item in group_item.get_children():
			tree_item.visible = false
	
	for item in result:
		var parent = item.get_parent()
		if parent == tree_ui.get_root():
			item.visible = true
			for tree_item in item.get_children():
				tree_item.visible = true
		else:
			item.visible = true
			parent.visible = true

func _on_item_selected():
	tree_menu.disabled = false

	var selected = tree_ui.get_selected()
	var is_group = selected.get_parent() == tree_ui.get_root()
	
	group_menu.get_popup().set_item_disabled(MenuOption.DELETE_ITEM, not is_group)
	group_menu.get_popup().set_item_disabled(MenuOption.DUPLICATE_ITEM, not is_group)

	tree_menu.get_popup().set_item_disabled(MenuOption.CREATE_ITEM, false)
	tree_menu.get_popup().set_item_disabled(MenuOption.DUPLICATE_ITEM, is_group)
	tree_menu.get_popup().set_item_disabled(MenuOption.DELETE_ITEM, is_group)

func _on_item_activated():
	var selected = tree_ui.get_selected()
	if selected.get_parent() == tree_ui.get_root():
		selected.set_collapsed(not selected.is_collapsed())
		return

	var metadata = selected.get_metadata(0)
	if not metadata or not metadata.has("uid"):
		return
	
	var group_item = selected.get_parent()
	var group_metadata = group_item.get_metadata(0)
	var group = ResourceLoader.load(ResourceUID.get_id_path(group_metadata["uid"]))
	var tree_resource = ResourceLoader.load(ResourceUID.get_id_path(metadata["uid"]))
	main_screen.open_tree("%s/%s" % [group.name, tree_resource.name])

func _on_item_edited():
	var edited = tree_ui.get_edited()
	
	var metadata: Dictionary = edited.get_metadata(0)
	if metadata:
		if metadata.has("duplicate_of"):
			if metadata.has("new_group"):
				if _create_group_duplicate(edited):
					metadata.erase("new_group")
					metadata.erase("duplicate_of")
			elif metadata.has("new_tree"):
				if _create_tree_duplicate(edited):
					metadata.erase("new_tree")
					metadata.erase("duplicate_of")
		elif metadata.has("new_group"):
			edited.set_metadata(0, null)
			_create_tree_group(edited)
		elif metadata.has("new_tree"):
			edited.set_metadata(0, null)
			var group_item = edited.get_parent()
			var group_metadata = group_item.get_metadata(0)
			if group_metadata and group_metadata.has("uid"):
				var group_path = ResourceUID.get_id_path(group_metadata["uid"])
				var group_resource = ResourceLoader.load(group_path)
				_create_tree_data(group_resource, edited)
		elif metadata.has("uid"):
			var path = ResourceUID.get_id_path(metadata["uid"])
			var tree_resource = ResourceLoader.load(path)

			if tree_resource.name != edited.get_text(0):
				tree_resource.name = edited.get_text(0)
				ResourceSaver.save(tree_resource, path)

func _on_edit_canceled(item: TreeItem):
	var metadata = item.get_metadata(0)
	if not metadata:
		return
	
	var is_new = metadata.has("new_group") or metadata.has("new_tree")
	if not is_new:
		return
	
	item.free()

func _tree_get_drag_data(at_position: Vector2) -> Variant:
	if not tree_ui.get_item_at_position(at_position):
		return null
	
	var selected = tree_ui.get_selected()

	if selected.get_parent() == tree_ui.get_root():
		return null

	var layout = HBoxContainer.new()
	layout.add_theme_constant_override("separation", 0)
	
	var icon = TextureRect.new()
	icon.texture = selected.get_icon(0)
	icon.custom_minimum_size = Vector2(16, 16)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.self_modulate = selected.get_icon_modulate(0)
	layout.add_child(icon)

	var label = Label.new()
	label.text = selected.get_text(0)
	layout.add_child(label)

	set_drag_preview(layout)

	var data = {}

	data["uid"] = selected.get_metadata(0)["uid"]
	data["group_uid"] = selected.get_parent().get_metadata(0)["uid"]

	return selected

func _tree_can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data is not TreeItem:
		tree_ui.drop_mode_flags = Tree.DROP_MODE_DISABLED
		return false
	
	var metadata = data.get_metadata(0)
	if not metadata:
		tree_ui.drop_mode_flags = Tree.DROP_MODE_DISABLED
		return false
	
	if not metadata.has("uid"):
		tree_ui.drop_mode_flags = Tree.DROP_MODE_DISABLED
		return false
	
	var parent_item = data.get_parent()
	if not parent_item:
		tree_ui.drop_mode_flags = Tree.DROP_MODE_DISABLED
		return false

	var parent_metadata = parent_item.get_metadata(0)
	if not parent_metadata:
		tree_ui.drop_mode_flags = Tree.DROP_MODE_DISABLED
		return false

	var over_item = tree_ui.get_item_at_position(at_position)
	if over_item == null:
		tree_ui.drop_mode_flags = Tree.DROP_MODE_DISABLED
		return false
	
	var over_metadata = over_item.get_metadata(0)
	if not over_metadata:
		tree_ui.drop_mode_flags = Tree.DROP_MODE_DISABLED
		return false

	if over_metadata["uid"] == parent_metadata["uid"]:
		tree_ui.drop_mode_flags = Tree.DROP_MODE_DISABLED
		return false

	var parent_over_item = over_item.get_parent()
	if not parent_over_item:
		tree_ui.drop_mode_flags = Tree.DROP_MODE_DISABLED
		return false
	
	var parent_over_metadata = parent_over_item.get_metadata(0)
	if parent_over_metadata:
		if parent_over_metadata["uid"] == parent_metadata["uid"]:
			tree_ui.drop_mode_flags = Tree.DROP_MODE_DISABLED
			return false

	tree_ui.drop_mode_flags = Tree.DROP_MODE_ON_ITEM
	
	return true

func _tree_drop_data(at_position: Vector2, data: Variant) -> void:
	var item: TreeItem = data
	var drop_section = tree_ui.get_drop_section_at_position(at_position)
	var other_item = tree_ui.get_item_at_position(at_position)
	var parent_item = other_item.get_parent()

	var new_parent_item: TreeItem = null
	if parent_item == tree_ui.get_root():
		new_parent_item = other_item
	else:
		new_parent_item = parent_item
	
	var tree_uid = item.get_metadata(0)["uid"]
	var from_group_uid = item.get_parent().get_metadata(0)["uid"]
	var to_group_uid = new_parent_item.get_metadata(0)["uid"]

	item.get_parent().remove_child(item)
	new_parent_item.add_child(item)
	item.set_icon_modulate(0, new_parent_item.get_icon_modulate(0))
	_on_tree_moved(tree_uid, from_group_uid, to_group_uid)

func _create_tree_group(group_item: TreeItem):
	var group_name = group_item.get_text(0)
	var path: String = "%s/%s" % [Yggdrasil.get_root_path(), group_name]
	DirAccess.make_dir_recursive_absolute(path)

	var file_path = "%s/%s.tres" % [path, group_name.to_snake_case()]
	if FileAccess.file_exists(file_path):
		print("Group with name \"%s\" already exists." % group_name)
		return

	var group = YggdrasilGroup.new()
	group.name = group_name
	group.trees = []

	var err = ResourceSaver.save(group, file_path)
	if err == OK:
		YggdrasilLoader.get_registry().groups.append(ResourceLoader.load(file_path))
		ResourceSaver.save(YggdrasilLoader.get_registry(), Yggdrasil.get_registry_path())
		EditorInterface.get_resource_filesystem().scan()
		group_item.set_metadata(0, {"uid": ResourceLoader.get_resource_uid(file_path)})
		_on_group_added()
	else:
		print("Error saving tree group: %s" % error_string(err))

func _create_tree_data(group: YggdrasilGroup, tree_item: TreeItem, scan_filesystem: bool = true, copy_from: YggdrasilTree = null):
	var path: String = group.resource_path.get_base_dir()

	var tree_name = tree_item.get_text(0)
	var tree_data = YggdrasilTree.new()
	tree_data.id = tree_name.to_snake_case()
	tree_data.name = tree_name
	if copy_from:
		_copy_tree_data(copy_from, tree_data)

	var file_path = "%s/%s.tres" % [path, tree_data.id]
	if FileAccess.file_exists(file_path):
		print("Tree with name \"%s\" already exists in group \"%s\"." % [tree_name, group.name])
		return

	var err = ResourceSaver.save(tree_data, file_path)
	if err == OK:
		var saved_tree = ResourceLoader.load(file_path, "YggdrasilTree", ResourceLoader.CACHE_MODE_IGNORE)
		group.trees.append(saved_tree)
		ResourceSaver.save(group, group.resource_path)
		YggdrasilLoader.add_tree_to_registry(group, saved_tree)
		if scan_filesystem:
			EditorInterface.get_resource_filesystem().scan()
		tree_item.set_metadata(0, {"uid": ResourceLoader.get_resource_uid(file_path)})
		_on_tree_added()
	else:
		print("Error saving tree data: %s" % error_string(err))

func _create_group_duplicate(group_item: TreeItem) -> bool:
	var group_name = group_item.get_text(0)
	var path: String = "%s/%s" % [Yggdrasil.get_root_path(), group_name]

	if DirAccess.dir_exists_absolute(path):
		print("Group with name \"%s\" already exists." % group_name)
		return false
	
	DirAccess.make_dir_recursive_absolute(path)

	var group_file_path = "%s/%s.tres" % [path, group_name.to_snake_case()]
	if FileAccess.file_exists(group_file_path):
		print("Group with name \"%s\" already exists." % group_name)
		return false

	var original_group_path = ResourceUID.get_id_path(group_item.get_metadata(0)["duplicate_of"])
	var original_group: YggdrasilGroup = ResourceLoader.load(original_group_path)

	var group = YggdrasilGroup.new()
	group.name = group_name
	group.trees = []
	
	var err = ResourceSaver.save(group, group_file_path)
	if err != OK:
		print("Error saving duplicated group: %s" % error_string(err))
		return false
	
	group = ResourceLoader.load(group_file_path)
	YggdrasilLoader.get_registry().groups.append(group)
	ResourceSaver.save(YggdrasilLoader.get_registry(), Yggdrasil.get_registry_path())

	group_item.set_metadata(0, {"uid": ResourceLoader.get_resource_uid(group_file_path)})

	for tree_data in original_group.trees:
		var tree_item = group_item.create_child()
		tree_item.set_text(0, tree_data.name)
		tree_item.set_icon(0, get_theme_icon(Yggdrasil.TREE_ICON, Yggdrasil.ICON_THEME))
		tree_item.set_icon_modulate(0, group_item.get_icon_modulate(0))
		_create_tree_data(group, tree_item, false, ResourceLoader.load(tree_data.resource_path, "YggdrasilTree", ResourceLoader.CACHE_MODE_IGNORE))

	EditorInterface.get_resource_filesystem().scan()

	_on_group_added()

	return true

func _create_tree_duplicate(tree_item: TreeItem) -> bool:
	var tree_name = tree_item.get_text(0)
	var tree_id = tree_name.to_snake_case()
	var metadata = tree_item.get_metadata(0)
	
	var group_item = tree_item.get_parent()
	var group_metadata = group_item.get_metadata(0)
	var group = ResourceLoader.load(ResourceUID.get_id_path(group_metadata["uid"]))

	var original_tree: YggdrasilTree = ResourceLoader.load(ResourceUID.get_id_path(metadata["duplicate_of"]), "YggdrasilTree", ResourceLoader.CACHE_MODE_IGNORE)

	var file_path = "%s/%s.tres" % [group.resource_path.get_base_dir(), tree_id]
	if FileAccess.file_exists(file_path):
		print("Tree with name \"%s\" already exists in group \"%s\"." % [tree_name, group.name])
		return false
	
	var tree_data = YggdrasilTree.new()
	tree_data.name = tree_name
	tree_data.id = tree_id
	_copy_tree_data(original_tree, tree_data)

	var err = ResourceSaver.save(tree_data, file_path)
	if err != OK:
		print("Error saving duplicated tree: %s" % error_string(err))
		return false
	
	var saved_tree = ResourceLoader.load(file_path, "YggdrasilTree", ResourceLoader.CACHE_MODE_IGNORE)
	group.trees.append(saved_tree)
	ResourceSaver.save(group, group.resource_path)
	tree_item.set_metadata(0, {"uid": ResourceLoader.get_resource_uid(file_path)})
	YggdrasilLoader.add_tree_to_registry(group, saved_tree)
	EditorInterface.get_resource_filesystem().scan()

	_on_tree_added()
	
	return true

func _copy_tree_data(original: YggdrasilTree, duplicate: YggdrasilTree):
	duplicate.id_counter = original.id_counter
	duplicate.revealed = original.revealed
	duplicate.allocation = original.allocation
	duplicate.size = original.size
	duplicate.bg_color = original.bg_color
	duplicate.bg_texture = original.bg_texture
	duplicate.line_texture_normal = original.line_texture_normal
	duplicate.line_texture_intermediate = original.line_texture_intermediate
	duplicate.line_texture_active = original.line_texture_active
	duplicate.icon_sizes = original.icon_sizes.duplicate(true)
	duplicate.icons = original.icons.duplicate(true)
	duplicate.node_size = original.node_size.duplicate(true)
	duplicate.nodes = original.nodes.duplicate(true)
	duplicate.decorations = original.decorations.duplicate(true)
	duplicate.prefabs = original.prefabs.duplicate(true)
	duplicate.attributes = original.attributes.duplicate(true)

func _on_tree_moved(uid: int, from_group: int, to_group: int):
	var tree_resource = ResourceLoader.load(ResourceUID.get_id_path(uid))
	var old_group_resource = ResourceLoader.load(ResourceUID.get_id_path(from_group))
	var new_group_resource = ResourceLoader.load(ResourceUID.get_id_path(to_group))

	old_group_resource.trees.erase(tree_resource)
	new_group_resource.trees.append(tree_resource)

	ResourceSaver.save(old_group_resource, old_group_resource.resource_path)
	ResourceSaver.save(new_group_resource, new_group_resource.resource_path)

	var new_group_path = new_group_resource.resource_path.get_base_dir()
	var new_tree_path = "%s/%s.tres" % [new_group_path, tree_resource.id]

	DirAccess.rename_absolute(tree_resource.resource_path, new_tree_path)
	EditorInterface.get_resource_filesystem().scan()

func _duplicate_selected_item():
	if not is_visible_in_tree():
		return

	var selected = tree_ui.get_selected()
	if not selected:
		return
	
	if selected.get_parent() == tree_ui.get_root():
		_duplicate_group(selected)
	else:
		_duplicate_tree(selected)

func _duplicate_group(group_item: TreeItem):
	var metadata = group_item.get_metadata(0)

	var dupe_group_item = tree_ui.get_root().create_child()
	dupe_group_item.set_text(0, "%s Copy" % group_item.get_text(0))
	dupe_group_item.set_icon(0, get_theme_icon(Yggdrasil.GROUP_ICON, Yggdrasil.ICON_THEME))
	dupe_group_item.set_icon_modulate(0, Yggdrasil.COLOR_CODES[tree_ui.get_root().get_child_count() % Yggdrasil.COLOR_CODES.size()])
	dupe_group_item.set_metadata(0, {"new_group": true, "duplicate_of": metadata["uid"]})
	await get_tree().create_timer(0.01).timeout
	dupe_group_item.select(0)
	tree_ui.edit_selected(true)

func _duplicate_tree(tree_item: TreeItem):
	var metadata = tree_item.get_metadata(0)

	var dupe_tree_item = tree_item.get_parent().create_child()
	dupe_tree_item.set_text(0, "%s Copy" % tree_item.get_text(0))
	dupe_tree_item.set_icon(0, get_theme_icon(Yggdrasil.TREE_ICON, Yggdrasil.ICON_THEME))
	dupe_tree_item.set_icon_modulate(0, tree_item.get_icon_modulate(0))
	dupe_tree_item.set_metadata(0, {"new_tree": true, "duplicate_of": metadata["uid"]})
	await get_tree().create_timer(0.01).timeout
	dupe_tree_item.select(0)
	tree_ui.edit_selected(true)

func _delete_group():
	var selected = tree_ui.get_selected()
	var is_group = selected.get_parent() == tree_ui.get_root()

	if not is_group:
		_delete_item(selected.get_parent())
		return
	
	_delete_item(selected)

func _delete_tree():
	var selected = tree_ui.get_selected()
	_delete_item(selected)

func _delete_selected_item():
	var selected = tree_ui.get_selected()
	if not selected:
		return
	
	_delete_item(selected)

func _delete_item(item: TreeItem):
	var parent = item.get_parent()

	delete_confirmation.get_node("VBoxContainer/DeleteFileCheck").button_pressed = true
	delete_confirmation.get_node("VBoxContainer/DeleteTreesCheck").button_pressed = true

	if parent == tree_ui.get_root():
		delete_confirmation.dialog_text = "Do you want to remove \"%s\" group?" % item.get_text(0)
		delete_confirmation.get_node("VBoxContainer/DeleteFileCheck").visible = true
		delete_confirmation.get_node("VBoxContainer/DeleteTreesCheck").visible = true
	else:
		delete_confirmation.dialog_text = "Do you want to remove \"%s\" tree?" % item.get_text(0)
		delete_confirmation.get_node("VBoxContainer/DeleteFileCheck").visible = true
		delete_confirmation.get_node("VBoxContainer/DeleteTreesCheck").visible = false
	
	delete_confirmation.popup_centered()

func _confirm_delete():
	var selected = tree_ui.get_selected()
	if not selected:
		return
	
	var metadata = selected.get_metadata(0)
	if not metadata:
		return
	
	var parent = selected.get_parent()
	if metadata.has("new_group") or metadata.has("new_tree"):
		selected.free()
		return

	var delete_file = delete_confirmation.get_node("VBoxContainer/DeleteFileCheck").button_pressed
	var delete_trees = delete_confirmation.get_node("VBoxContainer/DeleteTreesCheck").button_pressed
	
	if parent == tree_ui.get_root():
		var group_path = ResourceUID.get_id_path(metadata["uid"])
		var group_resource: YggdrasilGroup = ResourceLoader.load(group_path)
		YggdrasilLoader.get_registry().groups.erase(group_resource)
		ResourceSaver.save(YggdrasilLoader.get_registry(), Yggdrasil.get_registry_path())
		
		if delete_file:
			DirAccess.remove_absolute(group_path)
		
		if delete_trees:
			for tree_data in group_resource.trees:
				DirAccess.remove_absolute(tree_data.resource_path)
		
		if DirAccess.get_files_at(group_path.get_base_dir()).is_empty():
			DirAccess.remove_absolute(group_path.get_base_dir())
		
		if delete_file or delete_trees:
			EditorInterface.get_resource_filesystem().scan()
	else:
		var group_metadata = parent.get_metadata(0)
		var group_path = ResourceUID.get_id_path(group_metadata["uid"])
		var group_resource: YggdrasilGroup = ResourceLoader.load(group_path)
		var tree_path = ResourceUID.get_id_path(metadata["uid"])
		
		group_resource.trees.erase(ResourceLoader.load(tree_path))
		ResourceSaver.save(group_resource, group_path)

		if delete_file:
			DirAccess.remove_absolute(tree_path)

			if DirAccess.get_files_at(tree_path.get_base_dir()).is_empty():
				DirAccess.remove_absolute(tree_path.get_base_dir())

			EditorInterface.get_resource_filesystem().scan()

	selected.free()

	_on_group_added()
	_on_tree_added()

	group_menu.get_popup().set_item_disabled(MenuOption.DELETE_ITEM, true)
	group_menu.get_popup().set_item_disabled(MenuOption.DUPLICATE_ITEM, true)

	tree_menu.get_popup().set_item_disabled(MenuOption.CREATE_ITEM, true)
	tree_menu.get_popup().set_item_disabled(MenuOption.DUPLICATE_ITEM, true)
	tree_menu.get_popup().set_item_disabled(MenuOption.DELETE_ITEM, true)
