const VERSION = "1.0.3"

const ROOT_PATH_SETTING = "addons/yggdrasil/root_path"
const DEFAULT_ROOT_PATH = "res://yggdrasil_data"
const REGISTRY_FILENAME_SETTING = "addons/yggdrasil/registry_filename"
const DEFAULT_REGISTRY_FILENAME = "registry.tres"

const GROUP_ICON = "Folder"
const TREE_ICON = "KeyValue"
const ICON_THEME = &"EditorIcons"

const COLOR_CODES = [
	Color.DEEP_SKY_BLUE,
	Color.CHARTREUSE,
	Color.DEEP_PINK,
	Color.DARK_ORANGE,
	Color.FIREBRICK,
	Color.PALE_GOLDENROD,
	Color.SEA_GREEN,
	Color.WHITE_SMOKE
]

const Loader = "res://addons/yggdrasil/scripts/shared/yggdrasil_loader.gd"
const Serializer = "res://addons/yggdrasil/scripts/runtime/yggdrasil_serializer.gd"

const MainScreen = preload("res://addons/yggdrasil/scenes/editor/main_screen.tscn")
const FuzzySearch = preload("res://addons/yggdrasil/scripts/editor/fuzzy_search.gd")
const UUIDGenerator = preload("res://addons/yggdrasil/scripts/editor/uuid_generator.gd")

const BlankIcon = preload("res://addons/yggdrasil/blank_icon.png")

const DefaultDecorationScene = preload("res://addons/yggdrasil/scenes/shared/yggdrasil_default_node.tscn")
const DefaultNodeScene = preload("res://addons/yggdrasil/scenes/shared/yggdrasil_default_node.tscn")
const DefaultLineScene = preload("res://addons/yggdrasil/scenes/shared/yggdrasil_default_connection.tscn")
const DefaultTooltipScene = preload("res://addons/yggdrasil/scenes/shared/yggdrasil_node_tooltip.tscn")

enum AllocationState {
	NORMAL,
	INTERMEDIATE,
	ACTIVE,
	PREALLOCATED_INTERMEDIATE,
	PREALLOCATED_ACTIVE,
	REFUND
}

static func get_registry_path() -> String:
	return "%s/%s" % [get_root_path(), get_registry_filename()]

static func get_root_path() -> String:
	return ProjectSettings.get_setting(ROOT_PATH_SETTING, DEFAULT_ROOT_PATH)

static func get_registry_filename() -> String:
	return ProjectSettings.get_setting(REGISTRY_FILENAME_SETTING, DEFAULT_REGISTRY_FILENAME)
