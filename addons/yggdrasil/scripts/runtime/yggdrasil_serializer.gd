extends Node

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")
const SAVE_PATH = "user://yggdrasil_v2"

func save_tree_state(tree: YggdrasilTree) -> void:
	if Engine.is_editor_hint():
		return
	
	DirAccess.make_dir_recursive_absolute(SAVE_PATH)
	var uid = ResourceLoader.get_resource_uid(tree.resource_path)
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
