# Yggdrasil

---

Namespace script holding reusable constants and preloaded resources

# Properties

| Type                | Name                        | Description                                                      |
| ------------------- | --------------------------- | ---------------------------------------------------------------- |
| String              | `VERSION`                   | Plugin version                                                   |
| String              | `ROOT_PATH_SETTING`         | Project setting for generated resources path                     |
| String              | `DEFAULT_ROOT_PATH`         | Default value for Root Path setting                              |
| String              | `REGISTRY_FILENAME_SETTING` | Project setting for registry filename                            |
| String              | `DEFAULT_REGISTRY_FILENAME` | Default value for registry filename setting                      |
| String              | `GROUP_ICON`                | Default icon from `ICON_THEME` to use as a Group icon in Browser |
| String              | `TREE_ICON`                 | Default icon from `ICON_THEME` to use as a Tree icon in Browser  |
| StringName          | `ICON_THEME`                | Default icon theme from Editor icons                             |
| Array[Color]        | `COLOR_CODES`               | Colors used in Browser for icons                                 |
| YggdrasilLoader     | `Loader`                    | Reference to YggdrasilLoader script                              |
| YggdrasilSerializer | `Serializer`                | Reference to YggdrasilSerializer script                          |
| PackedScene         | `MainScreen`                | Scene for main screen editor                                     |
| FuzzySearch         | `FuzzySearch`               | Reference to FuzzySearch script                                  |
| UUIDGenerator       | `UUIDGenerator`             | Reference to UUIDGenerator script                                |
| Texture2D           | `BlankIcon`                 | Default icon for nodes                                           |
| PackedScene         | `DefaultDecorationScene`    | Default scene for created decorations                            |
| PackedScene         | `DefaultNodeScene`          | Default scene for created nodes                                  |
| PackedScene         | `DefaultLineScene`          | Default scene for created lines                                  |
| PackedScene         | `DefaultTooltipScene`       | Default scene for node tooltip                                   |

# Methods

| Type   | Name                    | Description                             |
| ------ | ----------------------- | --------------------------------------- |
| String | `get_registry_path`     | Path to registry resource file          |
| String | `get_root_path`         | Path to folder with generated resources |
| String | `get_registry_filename` | Name of registry resource               |

# Enumerations

`enum` AllocationState:

- `AllocationState` **NORMAL** = 0
    - Default state.
- `AllocationState` **INTERMEDIATE** = 1
    - Can be allocated.
- `AllocationState` **ACTIVE** = 2
    - Is allocated.
- `AllocationState` **PREALLOCATED_INTERMEDIATE** = 3
    - Can be preallocated.
- `AllocationState` **PREALLOCATED_ACTIVE** = 4
    - Is preallocated.
- `AllocationState` **REFUND** = 5
    - Is selected for deallocation.
