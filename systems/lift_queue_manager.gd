extends Node

# Queue per lift: Dictionary[String, Array[Skier]]
var _queues: Dictionary = {}
# Rider count per lift: Dictionary[String, int]
var _rider_counts: Dictionary = {}
# Loading accumulator per lift — fractional skiers to load
var _load_accumulators: Dictionary = {}
# Trail usage tracking: trail_id -> count of completed runs
var trail_usage: Dictionary = {}
# Visual queue offset
const QUEUE_SPACING := 8.0  # pixels between queued skiers


func _ready() -> void:
	pass


func initialize_queues() -> void:
	_queues.clear()
	_rider_counts.clear()
	_load_accumulators.clear()
	for lift in ResortData.lifts:
		_queues[lift.id] = []
		_rider_counts[lift.id] = 0
		_load_accumulators[lift.id] = 0.0


func enqueue(lift_id: String, skier: Skier) -> void:
	if not _queues.has(lift_id):
		_queues[lift_id] = []
	_queues[lift_id].append(skier)
	skier.current_lift_id = lift_id
	skier.start_queuing()
	_update_queue_positions(lift_id)


func get_queue_length(lift_id: String) -> int:
	if not _queues.has(lift_id):
		return 0
	return _queues[lift_id].size()


func get_rider_count(lift_id: String) -> int:
	return _rider_counts.get(lift_id, 0)


func _process(delta: float) -> void:
	if SimulationManager.sim_speed <= 0.0:
		return

	var sim_delta := delta * SimulationManager.sim_speed
	for lift in ResortData.lifts:
		_process_lift_queue(lift, sim_delta)


func _process_lift_queue(lift: LiftDefinition, sim_delta: float) -> void:
	var queue: Array = _queues.get(lift.id, [])
	var current_time := SimulationManager.game_time

	# Lift not open yet — hold the queue
	if current_time < lift.open_time:
		return

	# Past last ride — release all remaining queued skiers
	if current_time > lift.close_time:
		if not queue.is_empty():
			for skier: Skier in queue:
				SkierPool.release(skier)
			queue.clear()
		return

	if queue.is_empty():
		return

	# Chairlift check: if wind too high, don't load
	if lift.lift_type == LiftDefinition.LiftType.CHAIRLIFT:
		if not WeatherSystem.chairlift_operational:
			return

	# Time-based loading: accumulate fractional skiers based on capacity_per_hour
	var load_rate := lift.capacity_per_hour / 3600.0  # skiers per second
	_load_accumulators[lift.id] += load_rate * sim_delta

	var skiers_to_load := int(_load_accumulators[lift.id])
	if skiers_to_load <= 0:
		return
	_load_accumulators[lift.id] -= skiers_to_load

	var loaded := 0
	while loaded < skiers_to_load and not queue.is_empty():
		var riders: int = _rider_counts.get(lift.id, 0)
		if riders >= lift.capacity:
			break

		var skier: Skier = queue.pop_front()
		_rider_counts[lift.id] = riders + 1
		loaded += 1

		# Check group: if skier is in a group, try to load group members together
		if skier.group_id >= 0:
			_try_load_group_members(lift, queue, skier.group_id)

		# Reparent skier to lift path
		var lift_path := PathRegistry.get_lift_path(lift.path_node_name)
		if lift_path:
			PathRegistry.reparent_to_path(skier, lift_path)
			skier.start_riding_lift(lift.speed_kmh)
			skier.reached_path_end.connect(_on_skier_reached_lift_top.bind(skier, lift), CONNECT_ONE_SHOT)

	_update_queue_positions(lift.id)


func _try_load_group_members(lift: LiftDefinition, queue: Array, group_id: int) -> void:
	# Load up to 3 more group members (chairlift seats)
	var loaded := 0
	var max_extra := 3 if lift.lift_type == LiftDefinition.LiftType.CHAIRLIFT else 1
	var i := 0
	while i < queue.size() and loaded < max_extra:
		var other: Skier = queue[i]
		if other.group_id == group_id:
			queue.remove_at(i)
			_rider_counts[lift.id] += 1
			var lift_path := PathRegistry.get_lift_path(lift.path_node_name)
			if lift_path:
				PathRegistry.reparent_to_path(other, lift_path)
				other.start_riding_lift(lift.speed_kmh)
				other.reached_path_end.connect(_on_skier_reached_lift_top.bind(other, lift), CONNECT_ONE_SHOT)
			loaded += 1
		else:
			i += 1


func _on_skier_reached_lift_top(skier: Skier, lift: LiftDefinition) -> void:
	_rider_counts[lift.id] = maxi(0, _rider_counts.get(lift.id, 1) - 1)
	skier.set_state(Skier.State.AT_SUMMIT)

	# Pick a random trail and start skiing
	var trail := ResortData.get_random_trail_from_lift(lift.id)
	if trail:
		var trail_path := PathRegistry.get_trail_path(trail.path_node_name)
		if trail_path:
			skier.current_trail_id = trail.id
			PathRegistry.reparent_to_path(skier, trail_path)
			skier.start_skiing(trail.difficulty)
			skier.reached_path_end.connect(_on_skier_reached_trail_bottom.bind(skier, trail), CONNECT_ONE_SHOT)
			return

	# Fallback: if no trail found, release skier
	SkierPool.release(skier)


const QUEUE_OVERFLOW_THRESHOLD := 20
const QUEUE_HIGH_THRESHOLD := 35

func _on_skier_reached_trail_bottom(skier: Skier, trail: TrailDefinition) -> void:
	skier.arrive_at_base()

	# Track trail usage
	trail_usage[trail.id] = trail_usage.get(trail.id, 0) + 1

	# Kiosk purchase chance (once per visit)
	if not skier.has_bought_kiosk and randf() < IncomeManager.KIOSK_CHANCE:
		skier.has_bought_kiosk = true
		IncomeManager.add_kiosk()

	# Group wait: if in a group, wait for others
	if skier.group_id >= 0:
		skier.waiting_for_group = true

	# Lunch check: between 11:30-13:30, if hasn't eaten yet
	if not skier.has_eaten_lunch:
		var time := SimulationManager.game_time
		if time >= 41400.0 and time <= 48600.0:  # 11:30 to 13:30
			if randf() < 0.3:  # 30% chance per run during lunch window
				skier.start_lunch()
				IncomeManager.add_restaurant()
				skier.reached_path_end.connect(
					_requeue_after_lunch.bind(skier, trail), CONNECT_ONE_SHOT)
				return

	# Decide: ski again or leave?
	if skier.should_leave():
		SkierPool.release(skier)
		return

	# Check if preferred lift queue is very long — take a break
	if skier.preferred_lift_id != "":
		var pref_queue := get_queue_length(skier.preferred_lift_id)
		if pref_queue > QUEUE_HIGH_THRESHOLD and randf() < 0.3:
			skier.start_break()
			skier.reached_path_end.connect(
				_requeue_after_break.bind(skier, trail), CONNECT_ONE_SHOT)
			return

	# Pick next lift with preferred-lift and queue-aware routing
	var next_lift := _pick_next_lift(skier, trail)
	if next_lift:
		enqueue(next_lift.id, skier)
	else:
		SkierPool.release(skier)


func _pick_next_lift(skier: Skier, trail: TrailDefinition) -> LiftDefinition:
	# Prefer the skier's starting lift
	var preferred_id := skier.preferred_lift_id
	if preferred_id != "":
		var pref_queue := get_queue_length(preferred_id)

		# Moderate overflow: redirect to Nyestøl
		if pref_queue > QUEUE_OVERFLOW_THRESHOLD and randf() < 0.4:
			var nyestol_lift := ResortData.get_lift("nyestol_daafjell")
			if nyestol_lift:
				return nyestol_lift

		# Normal: return to preferred lift
		var pref_lift := ResortData.get_lift(preferred_id)
		if pref_lift:
			return pref_lift

	# Fallback: random connected lift
	return ResortData.get_random_lift_from_trail(trail.id)


func _requeue_after_lunch(skier: Skier, trail: TrailDefinition) -> void:
	if skier.should_leave():
		SkierPool.release(skier)
		return
	var next_lift := _pick_next_lift(skier, trail)
	if next_lift:
		enqueue(next_lift.id, skier)
	else:
		SkierPool.release(skier)


func _requeue_after_break(skier: Skier, trail: TrailDefinition) -> void:
	if skier.should_leave():
		SkierPool.release(skier)
		return
	var next_lift := _pick_next_lift(skier, trail)
	if next_lift:
		enqueue(next_lift.id, skier)
	else:
		SkierPool.release(skier)


func _update_queue_positions(lift_id: String) -> void:
	var queue: Array = _queues.get(lift_id, [])
	var lift := ResortData.get_lift(lift_id)
	if lift == null:
		return

	# Get the base position of the lift path
	var lift_path := PathRegistry.get_lift_path(lift.path_node_name)
	if lift_path == null or lift_path.curve == null or lift_path.curve.point_count == 0:
		return

	# Queue extends downward from the lift base
	var _base_pos := lift_path.curve.get_point_position(0)
	for i in range(queue.size()):
		var skier: Skier = queue[i]
		# Position them in queue relative to the path start
		# They're parented to the path, so position along the start
		if skier.get_parent() != lift_path:
			if skier.get_parent():
				skier.get_parent().remove_child(skier)
			lift_path.add_child(skier)
		skier.progress_ratio = 0.0
		# Offset visually via the sprite
		if skier.sprite:
			skier.sprite.position = Vector2(0, i * QUEUE_SPACING)
