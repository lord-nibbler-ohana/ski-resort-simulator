extends Node

const MIN_SPAWN_INTERVAL := 3.0
const MAX_SPAWN_INTERVAL := 8.0

# Car occupant weights: [1, 2, 3, 4, 5] people
# Mode = 2 people
const OCCUPANT_WEIGHTS := [15.0, 35.0, 25.0, 15.0, 10.0]

# Group probability: cars with 2+ people have chance of being a group
const GROUP_CHANCE := 0.6

var _spawn_timer: float = 0.0
var _next_spawn_time: float = 5.0  # first car after 5 seconds


func _ready() -> void:
	_next_spawn_time = randf_range(2.0, 5.0)


func _process(delta: float) -> void:
	if SimulationManager.sim_speed <= 0.0:
		return

	_spawn_timer += delta * SimulationManager.sim_speed
	if _spawn_timer >= _next_spawn_time:
		_spawn_timer = 0.0
		_next_spawn_time = randf_range(MIN_SPAWN_INTERVAL, MAX_SPAWN_INTERVAL)
		_spawn_car()


func _spawn_car() -> void:
	var parking := ResortData.get_random_parking()
	if parking == null:
		return

	var occupant_count := _weighted_random_occupants()
	SimulationManager.total_cars_arrived += 1

	var skiers: Array[Skier] = []

	for i in range(occupant_count):
		var skier := SkierPool.acquire()
		if skier == null:
			break

		SimulationManager.total_skiers_spawned += 1
		skiers.append(skier)

		# Place skier at parking and start walking to lift
		var walk_path := PathRegistry.get_walk_path(parking.walk_path_node_name)
		if walk_path:
			PathRegistry.reparent_to_path(skier, walk_path)
			skier.start_walking(5.0)  # 5 km/h walking speed

			# Pick a lift to head to
			if not parking.nearest_lift_ids.is_empty():
				skier.current_lift_id = parking.nearest_lift_ids[randi() % parking.nearest_lift_ids.size()]

			skier.reached_path_end.connect(
				_on_skier_reached_lift_area.bind(skier), CONNECT_ONE_SHOT)
		else:
			# No walk path: directly queue at nearest lift
			_queue_skier_at_parking(skier, parking)

	# Create group if 2+ people and random chance
	if skiers.size() >= 2 and randf() < GROUP_CHANCE:
		SimulationManager.create_group(skiers)


func _on_skier_reached_lift_area(skier: Skier) -> void:
	if skier.current_lift_id != "":
		LiftQueueManager.enqueue(skier.current_lift_id, skier)
	else:
		SkierPool.release(skier)


func _queue_skier_at_parking(skier: Skier, parking: ParkingDefinition) -> void:
	if parking.nearest_lift_ids.is_empty():
		SkierPool.release(skier)
		return
	var lift_id := parking.nearest_lift_ids[randi() % parking.nearest_lift_ids.size()]
	LiftQueueManager.enqueue(lift_id, skier)


func _weighted_random_occupants() -> int:
	var total_weight := 0.0
	for w in OCCUPANT_WEIGHTS:
		total_weight += w
	var roll := randf() * total_weight
	var cumulative := 0.0
	for i in range(OCCUPANT_WEIGHTS.size()):
		cumulative += OCCUPANT_WEIGHTS[i]
		if roll <= cumulative:
			return i + 1
	return 2
