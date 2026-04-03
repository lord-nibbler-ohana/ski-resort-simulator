extends Node2D

var _debug_overlay: Node2D
var _debug_visible := false
var _debug_lines: Dictionary = {}  # trail_id -> Line2D


func _ready() -> void:
	# Build all Path2D curves from coordinate data
	var paths_container := $PathsContainer
	if paths_container:
		PathBuilder.build_all_paths(paths_container)
		PathRegistry.register_paths_container(paths_container)

	# Initialize lift queues after paths are registered
	LiftQueueManager.initialize_queues()

	# Debug overlay container (hidden by default)
	_debug_overlay = Node2D.new()
	_debug_overlay.z_index = 5
	_debug_overlay.visible = false
	add_child(_debug_overlay)

	print("Ski Resort Simulator started!")
	print("Resort: %d lifts, %d trails, %d parking areas" % [
		ResortData.lifts.size(), ResortData.trails.size(), ResortData.parking.size()])
	print("Controls: WASD/mouse drag to pan, scroll to zoom, D=debug trails")
	print("Speed: 1/2/3/4 keys for simulation speed, Space to pause")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				if SimulationManager.sim_speed > 0.0:
					SimulationManager.pause()
				else:
					SimulationManager.unpause()
			KEY_1:
				SimulationManager.set_sim_speed(1.0)
			KEY_2:
				SimulationManager.set_sim_speed(2.0)
			KEY_3:
				SimulationManager.set_sim_speed(4.0)
			KEY_4:
				SimulationManager.set_sim_speed(8.0)
			KEY_D:
				_debug_visible = not _debug_visible
				_debug_overlay.visible = _debug_visible
				if _debug_visible:
					_update_debug_overlay()


func _process(_delta: float) -> void:
	if _debug_visible:
		_update_debug_overlay()


func _update_debug_overlay() -> void:
	for trail in ResortData.trails:
		var count: int = LiftQueueManager.trail_usage.get(trail.id, 0)
		if count <= 0:
			continue

		if trail.id in _debug_lines:
			continue  # Already drawn

		var path: Path2D = PathRegistry.get_trail_path(trail.path_node_name)
		if path == null or path.curve == null or path.curve.point_count < 2:
			continue

		var line := Line2D.new()
		line.width = 6.0
		line.default_color = Color(0.6, 0.1, 0.9, 0.7)  # Purple
		line.antialiased = true

		var curve := path.curve
		var baked_length := curve.get_baked_length()
		var num_samples := 80
		for i in range(num_samples + 1):
			var offset := (float(i) / num_samples) * baked_length
			line.add_point(curve.sample_baked(offset))

		_debug_overlay.add_child(line)
		_debug_lines[trail.id] = line
