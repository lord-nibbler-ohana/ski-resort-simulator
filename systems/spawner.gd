extends Node

# Car occupant weights: [1, 2, 3, 4, 5] people
# Mode = 2 people
const OCCUPANT_WEIGHTS := [15.0, 35.0, 25.0, 15.0, 10.0]

# Group probability: cars with 2+ people have chance of being a group
const GROUP_CHANCE := 0.6

# Normal distribution arrival parameters
const PEAK_ARRIVAL_TIME := 39600.0    # 11:00 in seconds since midnight
const ARRIVAL_STD_DEV := 3600.0       # 1 hour standard deviation
const TOTAL_CARS_TARGET := 250.0      # total cars expected over the day
const ARRIVAL_CUTOFF := 50400.0       # 14:00 — very few arrivals after this

var _spawn_timer: float = 0.0
var _next_spawn_time: float = 5.0
var _spawning_active: bool = true


func _ready() -> void:
	_next_spawn_time = randf_range(2.0, 5.0)
	SimulationManager.day_end_reached.connect(func(): _spawning_active = false)


func _process(delta: float) -> void:
	if SimulationManager.sim_speed <= 0.0:
		return
	if not _spawning_active:
		return

	var current_time := SimulationManager.game_time
	if current_time < SimulationManager.DAY_START or current_time > ARRIVAL_CUTOFF:
		return

	_spawn_timer += delta * SimulationManager.sim_speed
	if _spawn_timer >= _next_spawn_time:
		_spawn_timer = 0.0
		_spawn_car()
		# Compute next interval based on current arrival rate
		var rate := _arrival_rate(SimulationManager.game_time)
		if rate > 0.001:
			# Exponential random interval with mean = 1/rate
			_next_spawn_time = -log(maxf(randf(), 0.001)) / rate
			_next_spawn_time = clampf(_next_spawn_time, 1.0, 30.0)
		else:
			_next_spawn_time = 30.0


func _arrival_rate(time: float) -> float:
	# Normal PDF scaled by total cars target
	var z := (time - PEAK_ARRIVAL_TIME) / ARRIVAL_STD_DEV
	var pdf := exp(-0.5 * z * z) / (ARRIVAL_STD_DEV * sqrt(2.0 * PI))
	return pdf * TOTAL_CARS_TARGET


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
		skier.set_arrival_time(SimulationManager.game_time)
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
