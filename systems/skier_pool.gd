extends Node

const INITIAL_POOL_SIZE := 200

var _pool: Array[Skier] = []
var _holding_node: Node
var _skier_scene: PackedScene

var total_created: int = 0
var active_count: int = 0


func _ready() -> void:
	_holding_node = Node.new()
	_holding_node.name = "SkierPoolHolding"
	add_child(_holding_node)
	_preload_pool()


func _preload_pool() -> void:
	for i in range(INITIAL_POOL_SIZE):
		var skier := _create_skier()
		_pool.append(skier)


func _create_skier() -> Skier:
	var skier := Skier.new()
	skier.name = "Skier_%d" % total_created
	total_created += 1
	_holding_node.add_child(skier)
	skier.deactivate()
	return skier


func acquire() -> Skier:
	var skier: Skier
	if _pool.is_empty():
		skier = _create_skier()
	else:
		skier = _pool.pop_back()

	skier.initialize_random()
	active_count += 1
	return skier


func release(skier: Skier) -> void:
	skier.deactivate()
	if skier.get_parent():
		skier.get_parent().remove_child(skier)
	_holding_node.add_child(skier)
	_pool.append(skier)
	active_count -= 1
