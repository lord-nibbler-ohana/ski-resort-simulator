extends Node

var lift_paths: Dictionary = {}  # String -> Path2D
var trail_paths: Dictionary = {}  # String -> Path2D
var walk_paths: Dictionary = {}  # String -> Path2D

var _paths_container: Node2D


func register_paths_container(container: Node2D) -> void:
	_paths_container = container
	_scan_paths()


func _scan_paths() -> void:
	lift_paths.clear()
	trail_paths.clear()
	walk_paths.clear()

	if _paths_container == null:
		return

	var lifts_node := _paths_container.get_node_or_null("Lifts")
	if lifts_node:
		for child in lifts_node.get_children():
			if child is Path2D:
				lift_paths[child.name] = child

	var trails_node := _paths_container.get_node_or_null("Trails")
	if trails_node:
		for child in trails_node.get_children():
			if child is Path2D:
				trail_paths[child.name] = child

	var walks_node := _paths_container.get_node_or_null("WalkPaths")
	if walks_node:
		for child in walks_node.get_children():
			if child is Path2D:
				walk_paths[child.name] = child

	print("PathRegistry: %d lifts, %d trails, %d walks" % [
		lift_paths.size(), trail_paths.size(), walk_paths.size()])


func get_lift_path(path_name: String) -> Path2D:
	return lift_paths.get(path_name)


func get_trail_path(path_name: String) -> Path2D:
	return trail_paths.get(path_name)


func get_walk_path(path_name: String) -> Path2D:
	return walk_paths.get(path_name)


func reparent_to_path(skier: Skier, path: Path2D) -> void:
	if skier.get_parent():
		skier.get_parent().remove_child(skier)
	path.add_child(skier)
	skier.progress_ratio = 0.0
