extends Node

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")
const OLD_SAVE_PATH = "user://yggdrasil"
const SAVE_PATH = "user://yggdrasil_v2"

func save_tree_state(tree: YggdrasilTree) -> void:
	if Engine.is_editor_hint():
		return
	
	DirAccess.make_dir_recursive_absolute(SAVE_PATH)
	var uid = ResourceLoader.get_resource_uid(tree.resource_path)
	
	var old_save_path = "%s/%s.tree" % [OLD_SAVE_PATH, uid]
	if DirAccess.dir_exists_absolute(old_save_path):
		DirAccess.remove_absolute(old_save_path)

	var save_path = "%s/%s.tree" % [SAVE_PATH, uid]
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		return
	
	file.store_32(Yggdrasil.get_version_number())
	file.store_32(tree.tree_state.version)
	file.store_var(tree.tree_state.allocated_nodes)
	file.store_var(tree.tree_state.allocation_level)
	file.close()

func load_tree_state(tree: YggdrasilTree) -> void:
	if Engine.is_editor_hint():
		return
	
	DirAccess.make_dir_recursive_absolute(SAVE_PATH)
	var uid = ResourceLoader.get_resource_uid(tree.resource_path)
	
	var old_save_path = "%s/%s.tree" % [OLD_SAVE_PATH, uid]
	if DirAccess.dir_exists_absolute(old_save_path):
		_migrate_old_save(tree, old_save_path)
		return

	var save_path = "%s/%s.tree" % [SAVE_PATH, uid]
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return

	var saved_version = file.get_32()
	tree.tree_state.version = file.get_32()
	tree.tree_state.allocated_nodes = file.get_var()
	
	if saved_version <= Yggdrasil.get_version_number("2.0.0"):
		tree.tree_state.allocation_level = file.get_var()
	
	file.close()

func _migrate_old_save(tree: YggdrasilTree, old_save_path: String) -> void:
	var file = FileAccess.open(old_save_path, FileAccess.READ)
	if not file:
		return
	
	tree.tree_state.version = file.get_32()
	tree.tree_state.allocated_nodes = file.get_var()
	tree.tree_state.allocation_level = {}

	file.close()
	DirAccess.remove_absolute(old_save_path)
	save_tree_state(tree)
