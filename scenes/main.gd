extends Node2D


func _ready() -> void:
	# Build all Path2D curves from coordinate data
	var paths_container := $PathsContainer
	if paths_container:
		PathBuilder.build_all_paths(paths_container)
		PathRegistry.register_paths_container(paths_container)

	# Initialize lift queues after paths are registered
	LiftQueueManager.initialize_queues()

	print("Ski Resort Simulator started!")
	print("Resort: %d lifts, %d trails, %d parking areas" % [
		ResortData.lifts.size(), ResortData.trails.size(), ResortData.parking.size()])
	print("Controls: WASD/mouse drag to pan, scroll to zoom")
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
