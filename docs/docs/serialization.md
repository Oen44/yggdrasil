# Saving and Loading tree state

---

When `YggdrasilTree` is built using `YggdrasilBuilder`, it will also load `YggdrasilTreeState` from `user://yggdrasil/{uid}.tree`.

## Saving tree state

While loading is automated, saving on the other hand needs to be controlled by you. Not to worry, this can be done with a single line of code.

``` gdscript
func _on_save_button_pressed():
	YggdrasilSerializer.save_tree_state(_tree)
```