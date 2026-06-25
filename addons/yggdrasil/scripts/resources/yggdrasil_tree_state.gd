@tool
class_name YggdrasilTreeState
extends RefCounted

var version: int
var allocated_nodes: Array[int]
var allocation_level: Dictionary[int, int]

func _init():
	version = 1
	allocated_nodes = []
	allocation_level = {}
