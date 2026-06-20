# Yggdrasil API

Namespace script holding reusable constants, resource paths, and preloaded assets.

---

## Properties

| Type         | Name                                                             | Default                                                            |
| ------------ | ---------------------------------------------------------------- | ------------------------------------------------------------------ |
| String       | [VERSION](#property-version)                                     | `"1.0.0"`                                                          |
| String       | [ROOT_PATH_SETTING](#property-root_path_setting)                 | `"addons/yggdrasil/root_path"`                                     |
| String       | [DEFAULT_ROOT_PATH](#property-default_root_path)                 | `"res://yggdrasil_data"`                                           |
| String       | [REGISTRY_FILENAME_SETTING](#property-registry_filename_setting) | `"addons/yggdrasil/registry_filename"`                             |
| String       | [DEFAULT_REGISTRY_FILENAME](#property-default_registry_filename) | `"registry.tres"`                                                  |
| String       | [GROUP_ICON](#property-group_icon)                               | `"Folder"`                                                         |
| String       | [TREE_ICON](#property-tree_icon)                                 | `"KeyValue"`                                                       |
| StringName   | [ICON_THEME](#property-icon_theme)                               | `&"EditorIcons"`                                                   |
| Array[Color] | [COLOR_CODES](#property-color_codes)                             | `[]`                                                               |
| String       | [Loader](#property-loader)                                       | `"res://addons/yggdrasil/scripts/shared/yggdrasil_loader.gd"`      |
| String       | [Serializer](#property-serializer)                               | `"res://addons/yggdrasil/scripts/runtime/yggdrasil_serializer.gd"` |
| PackedScene  | [MainScreen](#property-mainscreen)                               | `preloaded`                                                        |
| Script       | [FuzzySearch](#property-fuzzysearch)                             | `preloaded`                                                        |
| Script       | [UUIDGenerator](#property-uuidgenerator)                         | `preloaded`                                                        |
| Texture2D    | [BlankIcon](#property-blankicon)                                 | `preloaded`                                                        |
| PackedScene  | [DefaultDecorationScene](#property-defaultdecorationscene)       | `preloaded`                                                        |
| PackedScene  | [DefaultNodeScene](#property-defaultnodescene)                   | `preloaded`                                                        |
| PackedScene  | [DefaultLineScene](#property-defaultlinescene)                   | `preloaded`                                                        |
| PackedScene  | [DefaultTooltipScene](#property-defaulttooltipscene)             | `preloaded`                                                        |

## Methods

| Type   | Name                                              |
| ------ | ------------------------------------------------- |
| String | [get_registry_path](#get_registry_path)()         |
| String | [get_root_path](#get_root_path)()                 |
| String | [get_registry_filename](#get_registry_filename)() |

## Enumerations

### `enum` AllocationState: { #enum-allocation-state }

- `AllocationState` **NORMAL** = 0
    - Default state.
- `AllocationState` **INTERMEDIATE** = 1
    - Node can be allocated.
- `AllocationState` **ACTIVE** = 2
    - Node is allocated.
- `AllocationState` **PREALLOCATED_INTERMEDIATE** = 3
    - Node can be preallocated.
- `AllocationState` **PREALLOCATED_ACTIVE** = 4
    - Node is preallocated.
- `AllocationState` **REFUND** = 5
    - Node is selected for deallocation.

## Property Descriptions

### <span class="type">String</span> VERSION <span class="param">=</span> `"1.0.0"` { #property-version }
> Plugin version.

### <span class="type">String</span> ROOT_PATH_SETTING <span class="param">=</span> `"addons/yggdrasil/root_path"` { #property-root_path_setting }
> Project setting key for generated resources path.

### <span class="type">String</span> DEFAULT_ROOT_PATH <span class="param">=</span> `"res://yggdrasil_data"` { #property-default_root_path }
> Default value for the root path setting.

### <span class="type">String</span> REGISTRY_FILENAME_SETTING <span class="param">=</span> `"addons/yggdrasil/registry_filename"` { #property-registry_filename_setting }
> Project setting key for registry filename.

### <span class="type">String</span> DEFAULT_REGISTRY_FILENAME <span class="param">=</span> `"registry.tres"` { #property-default_registry_filename }
> Default value for the registry filename setting.

### <span class="type">String</span> GROUP_ICON <span class="param">=</span> `"Folder"` { #property-group_icon }
> Default icon from `ICON_THEME` used for group entries in the browser.

### <span class="type">String</span> TREE_ICON <span class="param">=</span> `"KeyValue"` { #property-tree_icon }
> Default icon from `ICON_THEME` used for tree entries in the browser.

### <span class="type">StringName</span> ICON_THEME <span class="param">=</span> `&"EditorIcons"` { #property-icon_theme }
> Editor icon theme name.

### <span class="type">Array[Color]</span> COLOR_CODES <span class="param">=</span> `[]` { #property-color_codes }
> Colors used for browser icons.

### <span class="type">String</span> Loader <span class="param">=</span> `"res://addons/yggdrasil/scripts/shared/yggdrasil_loader.gd"` { #property-loader }
> Resource path to [YggdrasilLoader](./yggdrasil-loader.md).

### <span class="type">String</span> Serializer <span class="param">=</span> `"res://addons/yggdrasil/scripts/runtime/yggdrasil_serializer.gd"` { #property-serializer }
> Resource path to [YggdrasilSerializer](../runtime/yggdrasil-serializer.md).

### <span class="type">PackedScene</span> MainScreen { #property-mainscreen }
> Main editor screen scene.

### <span class="type">Script</span> FuzzySearch { #property-fuzzysearch }
> Preloaded fuzzy search script used by editor tools.

### <span class="type">Script</span> UUIDGenerator { #property-uuidgenerator }
> Preloaded UUID generator script used by editor tools.

### <span class="type">Texture2D</span> BlankIcon { #property-blankicon }
> Default icon for nodes.

### <span class="type">PackedScene</span> DefaultDecorationScene { #property-defaultdecorationscene }
> Default scene for created decorations.

### <span class="type">PackedScene</span> DefaultNodeScene { #property-defaultnodescene }
> Default scene for created nodes.

### <span class="type">PackedScene</span> DefaultLineScene { #property-defaultlinescene }
> Default scene for created lines.

### <span class="type">PackedScene</span> DefaultTooltipScene { #property-defaulttooltipscene }
> Default scene for node tooltips.

## Method Descriptions

### <span class="type">String</span> get_registry_path() { #get_registry_path }
> Returns the full registry resource path.

### <span class="type">String</span> get_root_path() { #get_root_path }
> Returns the configured generated resources root path.

### <span class="type">String</span> get_registry_filename() { #get_registry_filename }
> Returns the configured registry filename.