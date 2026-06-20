# `@tool` YggdrasilNodeButton API

Button control that displays and manages an interactive [YggdrasilNode](../resources/yggdrasil-node.md).

---

## Signals

| Name                                                                                                                                                                  |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [node_hovered](#signal-node_hovered)(<span class="param">node:</span> [YggdrasilNodeButton](./yggdrasil-node-button.md), <span class="param">is_hovered:</span> bool) |

## Properties

| Type                                                                    | Name                                                 | Default  |
| ----------------------------------------------------------------------- | ---------------------------------------------------- | -------- |
| [YggdrasilTree](../resources/yggdrasil-tree.md) {.type}                 | [tree](#property-tree)                               | `null`   |
| [YggdrasilTreeView](./yggdrasil-tree-view.md) {.type}                   | [tree_view](#property-tree_view)                     | `null`   |
| [YggdrasilNode](../resources/yggdrasil-node.md) {.type}                 | [node_data](#property-node_data)                     | `null`   |
| [YggdrasilPrefab](../resources/yggdrasil-prefab.md) {.type}             | [prefab](#property-prefab)                           | `null`   |
| bool {.type}                                                            | [is_mouse_over](#property-is_mouse_over)             | `false`  |
| bool {.type}                                                            | [preallocated](#property-preallocated)               | `false`  |
| bool {.type}                                                            | [refund](#property-refund)                           | `false`  |
| bool {.type}                                                            | [allocated](#property-allocated)                     | `false`  |
| [AllocationState](../shared/yggdrasil.md#enum-allocation-state) {.type} | [state](#property-state)                             | `NORMAL` |
| bool {.type}                                                            | [is_root](#property-is_root)                         | `false`  |
| int {.type}                                                             | [id](#property-id)                                   | 0        |
| String {.type}                                                          | [reference_id](#property-reference_id)               | `""`     |
| String {.type}                                                          | [node_name](#property-node_name)                     | `""`     |
| String {.type}                                                          | [description](#property-description)                 | `""`     |
| [NodeType](../resources/yggdrasil-node.md#enum-node-type) {.type}       | [type](#property-type)                               | `SMALL`  |
| Texture2D {.type}                                                       | [icon](#property-icon)                               | `null`   |
| Texture2D {.type}                                                       | [border_normal](#property-border_normal)             | `null`   |
| Texture2D {.type}                                                       | [border_intermediate](#property-border_intermediate) | `null`   |
| Texture2D {.type}                                                       | [border_active](#property-border_active)             | `null`   |
| Array {.type}                                                           | [out_nodes](#property-out_nodes)                     | `[]`     |
| Array {.type}                                                           | [in_nodes](#property-in_nodes)                       | `[]`     |
| Dictionary {.type}                                                      | [line_data](#property-line_data)                     | `{}`     |
| Dictionary {.type}                                                      | [attributes](#property-attributes)                   | `{}`     |
| bool {.type}                                                            | [locked](#property-locked)                           | false    |

## Methods

| Type           | Name                                                                                                                           |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| String {.type} | [format_tooltip](#format_tooltip)()                                                                                            |
| void {.type}   | [set_state](#set_state)(<span class="param">new_state:</span> [AllocationState](../shared/yggdrasil.md#enum-allocation-state)) |

## Signal Descriptions

### node_hovered(<span class="param">node:</span> [YggdrasilNodeButton](./yggdrasil-node-button.md), <span class="param">is_hovered:</span> bool) { #signal-node_hovered }
> Emitted when the mouse enters or exits the node button.

## Property Descriptions

### [YggdrasilTree](../resources/yggdrasil-tree.md) tree <span class="param">=</span> `null` { #property-tree }
> Tree resource this node belongs to.

### [YggdrasilTreeView](./yggdrasil-tree-view.md) tree_view <span class="param">=</span> `null` { #property-tree_view }
> Tree view that owns this node button.

### [YggdrasilNode](../resources/yggdrasil-node.md) node_data <span class="param">=</span> `null` { #property-node_data }
> Backing node resource for this button.

### [YggdrasilPrefab](../resources/yggdrasil-prefab.md) prefab <span class="param">=</span> `null` { #property-prefab }
> Prefab associated with this node button.

### <span class="type">bool</span> is_mouse_over <span class="param">=</span> `false` { #property-is_mouse_over }
> Tracks whether the mouse is currently over the node.

### <span class="type">bool</span> preallocated <span class="param">=</span> `false` { #property-preallocated }
> Whether the node is currently preallocated.

### <span class="type">bool</span> refund <span class="param">=</span> `false` { #property-refund }
> Whether the node is currently staged for refund.

### <span class="type">bool</span> allocated <span class="param">=</span> `false` { #property-allocated }
> Whether the node is currently allocated.

### [AllocationState](../shared/yggdrasil.md#enum-allocation-state) state <span class="param">=</span> `NORMAL` { #property-state }
> Current allocation display state of the node.

### <span class="type">bool</span> is_root { #property-is_root }
> Proxy property for `node_data.is_root`.

### <span class="type">int</span> id { #property-id }
> Proxy property for `node_data.id`.

### <span class="type">String</span> reference_id { #property-reference_id }
> Proxy property for `node_data.reference_id`.

### <span class="type">String</span> node_name { #property-node_name }
> Proxy property for `node_data.name`.

### <span class="type">String</span> description { #property-description }
> Proxy property for `node_data.description`.

### <span class="type">NodeType</span> type { #property-type }
> Proxy property for `node_data.type`.

### <span class="type">Texture2D</span> icon { #property-icon }
> Proxy property for `node_data.icon`.

### <span class="type">Texture2D</span> border_normal { #property-border_normal }
> Proxy property for `node_data.border_normal`.

### <span class="type">Texture2D</span> border_intermediate { #property-border_intermediate }
> Proxy property for `node_data.border_intermediate`.

### <span class="type">Texture2D</span> border_active { #property-border_active }
> Proxy property for `node_data.border_active`.

### <span class="type">Array</span> out_nodes { #property-out_nodes }
> Proxy property for `node_data.out_nodes`.

### <span class="type">Array</span> in_nodes { #property-in_nodes }
> Proxy property for `node_data.in_nodes`.

### <span class="type">Dictionary</span> line_data { #property-line_data }
> Proxy property for `node_data.line_data`.

### <span class="type">Dictionary</span> attributes { #property-attributes }
> Proxy property for `node_data.attributes`.

### <span class="type">bool</span> locked { #property-locked }
> Proxy property for `node_data.locked`.

## Method Descriptions

### <span class="type">String</span> format_tooltip() { #format_tooltip }
> Builds and returns formatted rich text tooltip content using the node name, attributes, and description.

### <span class="type">void</span> set_state(<span class="param">new_state:</span> [AllocationState](../shared/yggdrasil.md#enum-allocation-state)) { #set_state }
> Updates the node allocation state, border appearance, and visibility according to `new_state`.