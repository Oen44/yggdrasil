# Prefabs

---

Recreating the same node multiple times can get very annoying. This is why there is a Prefabs system.

## Save as Prefab

Select any node(s), right-click to open context menu as select **Save as Prefab**. Now if you look at the bottom bar, there are several tabs, depending on which type of node you just saved, prefabs will be stored there. So press on that tab and you will notice a file-like node there. That's the prefab, you can now drag and drop it into the view. This newly created node is the same that you just saved as a prefab, but there is more to it.

## What are prefabs?

When you save node as a prefab, reference is created, meaning that every node that shares that reference also shares properties. If you change the name of one of these nodes, every other node will change as well. Nodes duplicated in view will also duplicate prefab reference.

## Save as Copy

You might want to also reuse a node without keeping the reference, that's what copies are. Selecting **Save as Copy** from context menu, will add new entry to the bottom tabs. Prefabs and Copies have little icon in their corner so it's easier to tell which is which.

## Make Unique

Nodes created from prefabs can be turned into normal nodes by selecting **Make Unique** from the context menu. This breaks the prefab reference while keeping current node properties.
