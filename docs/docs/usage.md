# Using trees in-game

---

If you haven't, check [Getting Started](getting-started.md) first.

## Loading YggdrasilTree

To get `YggdrasilTree` resource, use `YggdrasilLoader.load_tree(path: String)`.

In [Getting Started](getting-started.md) we have created Group called Spells and Tree called Fire.

``` text
Spells
└─ Fire
```

To get `YggdrasilTree` for our Fire tree, use `YggdrasilLoader.load_tree("Spells/Fire")`.

``` gdscript linenums="1" hl_lines="2"
func _ready():
    var tree: YggdrasilTree = YggdrasilLoader.load_tree("Spells/Tree")
    # ...
```

## Building YggdrasilTree

Now that we have our tree resource loaded, we can build it and place in our UI.

For that we will use `YggdrasilBuilder`. For full API documentation check [YggdrasilBuilder](api/shared/yggdrasil-builder.md). For now we are interested only in `YggdrasilBuilder.new(tree: YggdrasilTree)`, `YggdrasilBuilder.set_parent(new_parent: Node)` and `YggdrasilBuilder.build()`.

First we will initialize our builder

``` gdscript linenums="1" hl_lines="3"
func _ready():
    var tree: YggdrasilTree = YggdrasilLoader.load_tree("Spells/Tree")
    var builder: YggdrasilBuilder = YggdrasilBuilder.new(tree)
    # ...
```

Then we have to provide a parent Node, this is where `YggdrasilTreeView` will be added. It's recommended to use `Node` of type `Control` (can be inherited) with `clip_contents` set to `true` (we don't need the tree view to be visible outside the parent).

``` gdscript linenums="1" hl_lines="1 6"
@export var tree_parent: Control

func _ready():
    var tree: YggdrasilTree = YggdrasilLoader.load_tree("Spells/Tree")
    var builder: YggdrasilBuilder = YggdrasilBuilder.new(tree)
    builder.set_parent(tree_parent)
    # ...
```

Now all that is left to do is build the tree and get created `YggdrasilTreeView`.

``` gdscript linenums="1" hl_lines="3 9"
@export var tree_parent: Control

var _tree_view: YggdrasilTreeView

func _ready():
    var tree: YggdrasilTree = YggdrasilLoader.load_tree("Spells/Tree")
    var builder: YggdrasilBuilder = YggdrasilBuilder.new(tree)
    builder.set_parent(tree_parent)
    _tree_view = builder.build()
```

Done! Our tree is now visible in-game and can be interacted with.