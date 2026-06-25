# `@tool` YggdrasilTree API

Resource that stores tree data, visual configuration, node collections, prefab mappings, attributes, and runtime [YggdrasilTreeState](../resources/yggdrasil-tree-state.md).

---

## Properties

| Type                                                 | Name                                                             | Default                |
| ---------------------------------------------------- | ---------------------------------------------------------------- | ---------------------- |
| int {.type}                                          | [version](#property-version)                                     | `1`                    |
| String {.type}                                       | [id](#property-id)                                               | `""`                   |
| String {.type}                                       | [name](#property-name)                                           | `""`                   |
| bool {.type}                                         | [revealed](#property-revealed)                                   | `true`                 |
| bool {.type}                                         | [allocation](#property-allocation)                               | `true`                 |
| bool {.type}                                         | [preallocation](#property-preallocation)                         | `true`                 |
| bool {.type}                                         | [multiallocation](#property-multiallocation)                     | `true`                 |
| Vector2 {.type}                                      | [size](#property-size)                                           | `Vector2(5000, 5000)`  |
| Color {.type}                                        | [bg_color](#property-bg_color)                                   | `Color(0.1, 0.1, 0.1)` |
| Texture2D {.type}                                    | [bg_texture](#property-bg_texture)                               | `null`                 |
| Texture2D {.type}                                    | [line_texture_normal](#property-line_texture_normal)             | `null`                 |
| Texture2D {.type}                                    | [line_texture_intermediate](#property-line_texture_intermediate) | `null`                 |
| Texture2D {.type}                                    | [line_texture_active](#property-line_texture_active)             | `null`                 |
| int {.type}                                          | [id_counter](#property-id_counter)                               | `0`                    |
| float {.type}                                        | [border_scale](#property-border_scale)                           | `1.5`                  |
| Dictionary[NodeType, Vector2] {.type}                | [icon_sizes](#property-icon_sizes)                               | `{}`                   |
| Dictionary[NodeType, Texture2D] {.type}              | [icons](#property-icons)                                         | `{}`                   |
| Dictionary[NodeType, Vector2] {.type}                | [node_size](#property-node_size)                                 | `{}`                   |
| Array[YggdrasilNode] {.type}                         | [nodes](#property-nodes)                                         | `[]`                   |
| Array[YggdrasilNode] {.type}                         | [decorations](#property-decorations)                             | `[]`                   |
| Dictionary[NodeType, Array[YggdrasilPrefab]] {.type} | [prefabs](#property-prefabs)                                     | `{}`                   |
| Dictionary[String, YggdrasilAttribute] {.type}       | [attributes](#property-attributes)                               | `{}`                   |

## Methods

| Type            | Name                                                                            |
| --------------- | ------------------------------------------------------------------------------- |
| Vector2 {.type} | [get_node_size](#get_node_size)(<span class="param">node_type:</span> NodeType) |
| int {.type}     | [get_next_id](#get_next_id)()                                                   |

## Property Descriptions

### <span class="type">int</span> version <span class="param">=</span> `1` { #property-version }
> TODO

### <span class="type">String</span> id <span class="param">=</span> `""`  { #property-id }
> TODO

### <span class="type">String</span> name <span class="param">=</span> `""` { #property-name }
> TODO

### <span class="type">bool</span> revealed <span class="param">=</span> `true` { #property-revealed }
> TODO

### <span class="type">bool</span> allocation <span class="param">=</span> `true` { #property-allocation }
> TODO

### <span class="type">bool</span> preallocation <span class="param">=</span> `true` { #property-preallocation }
> TODO

### <span class="type">bool</span> multiallocation <span class="param">=</span> `true` { #property-multiallocation }
> TODO

### <span class="type">Vector2</span> size <span class="param">=</span> `Vector2(5000, 5000)` { #property-size }
> TODO

### <span class="type">Color</span> bg_color <span class="param">=</span> `Color(0.1, 0.1, 0.1)` { #property-bg_color }
> TODO

### <span class="type">Texture2D</span> bg_texture <span class="param">=</span> `null` { #property-bg_texture }
> TODO

### <span class="type">Texture2D</span> line_texture_normal <span class="param">=</span> `null` { #property-line_texture_normal }
> TODO

### <span class="type">Texture2D</span> line_texture_intermediate <span class="param">=</span> `null` { #property-line_texture_intermediate }
> TODO

### <span class="type">Texture2D</span> line_texture_active <span class="param">=</span> `null` { #property-line_texture_active }
> TODO

### <span class="type">int</span> id_counter <span class="param">=</span> `0` { #property-id_counter }
> TODO

### <span class="type">float</span> border_scale <span class="param">=</span> `1.5` { #property-border_scale }
> TODO

### <span class="type">Dictionary[NodeType, Vector2]</span> icon_sizes <span class="param">=</span> `{}` { #property-icon_sizes }
> TODO

### <span class="type">Dictionary[NodeType, Texture2D]</span> icons <span class="param">=</span> `{}` { #property-icons }
> TODO

### <span class="type">Dictionary[NodeType, Vector2]</span> node_size <span class="param">=</span> `{}` { #property-node_size }
> TODO

### <span class="type">Array[YggdrasilNode]</span> nodes <span class="param">=</span> `[]` { #property-nodes }
> TODO

### <span class="type">Array[YggdrasilNode]</span> decorations <span class="param">=</span> `[]` { #property-decorations }
> TODO

### <span class="type">Dictionary[NodeType, Array[YggdrasilPrefab]]</span> prefabs <span class="param">=</span> `{}` { #property-prefabs }
> TODO

### <span class="type">Dictionary[String, YggdrasilAttribute]</span> attributes <span class="param">=</span> `{}` { #property-attributes }
> TODO

## Method Descriptions

### <span class="type">Vector2</span> get_node_size(<span class="param">node_type:</span> NodeType) { #get_node_size }
> Returns the configured size for the given `NodeType`. Returns `Vector2.ZERO` if no size is defined.

### <span class="type">int</span> get_next_id() { #get_next_id }
> Increments the internal `id_counter` and returns the next available node identifier.