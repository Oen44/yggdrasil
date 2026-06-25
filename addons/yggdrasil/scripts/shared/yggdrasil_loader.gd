@tool
extends Node
## Yggdrasil Loader
## Singleton that loads YggrasilRegistry, provides API for getting trees

const Yggdrasil = preload("res://addons/yggdrasil/scripts/shared/yggdrasil.gd")

var _registry: YggdrasilRegistry
var _path_to_resource_path: Dictionary[String, String]
var _path_to_tree: Dictionary[String, YggdrasilTree]

func _init():
	_load_registry()

# Public

# Returns registry
func get_registry() -> YggdrasilRegistry:
	return _registry

# Returns tree by path (group_name/tree_name, e.g. "my group/my tree", case insensitive)
func load_tree(path: String) -> YggdrasilTree:
	path = path.to_lower()
	
	var tree: YggdrasilTree = null
	if Engine.is_editor_hint():
		if not _path_to_resource_path.has(path):
			push_error("Yggdrasil: Tree path '%s' not found in registry" % path)
			return null
		var tree_path = _path_to_resource_path[path]
		tree = ResourceLoader.load(tree_path, "YggdrasilTree", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		if not _path_to_tree.has(path):
			push_error("Yggdrasil: Tree path '%s' not found in registry" % path)
			return null
		tree = _path_to_tree[path]

	if tree == null:
		push_error("Yggdrasil: Failed to load tree at path '%s'" % path)
	
	return tree

func add_tree_to_registry(group: YggdrasilGroup, tree: YggdrasilTree) -> void:
	_path_to_resource_path["%s/%s" % [group.name.to_lower(), tree.name.to_lower()]] = tree.resource_path

# Private

func _load_registry():
	if not FileAccess.file_exists(Yggdrasil.get_registry_path()):
		_create_registry()
	
	_registry = ResourceLoader.load(Yggdrasil.get_registry_path(), "YggdrasilRegistry", ResourceLoader.CACHE_MODE_IGNORE)
	_cache_paths_to_trees()

func _create_registry():
	var path: String = Yggdrasil.get_root_path()
	DirAccess.make_dir_recursive_absolute(path)

	_registry = YggdrasilRegistry.new()
	ResourceSaver.save(_registry, Yggdrasil.get_registry_path())

func _cache_paths_to_trees():
	_path_to_resource_path = {}
	_path_to_tree = {}
	for group: YggdrasilGroup in _registry.groups:
		for tree: YggdrasilTree in group.trees:
			if Engine.is_editor_hint():
				_path_to_resource_path["%s/%s" % [group.name.to_lower(), tree.name.to_lower()]] = tree.resource_path
			else:
				_path_to_tree["%s/%s" % [group.name.to_lower(), tree.name.to_lower()]] = tree
