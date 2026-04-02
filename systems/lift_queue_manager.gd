extends Node

# Queue per lift: Dictionary[String, Array[Skier]]
var _queues: Dictionary = {}
# Rider count per lift: Dictionary[String, int]
var _rider_counts: Dictionary = {}
# Visual queue offset
const QUEUE_SPACING := 8.0  # pixels between queued skiers


func _ready() -> void:
	pass


func initialize_queues() -> void:
	_queues.clear()
	_rider_counts.clear()
	for lift in ResortData.lifts:
		_queues[lift.id] = []
		_rider_counts[lift.id] = 0


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


func _process(_delta: float) -> void:
	if SimulationManager.sim_speed <= 0.0:
		return

	for lift in ResortData.lifts:
		_process_lift_queue(lift)


func _process_lift_queue(lift: LiftDefinition) -> void:
	var queue: Array = _queues.get(lift.id, [])
	if queue.is_empty():
		return

	var riders: int = _rider_counts.get(lift.id, 0)
	if riders >= lift.capacity:
		return

	# Chairlift check: if wind too high, don't load
	if lift.lift_type == LiftDefinition.LiftType.CHAIRLIFT:
		if not WeatherSystem.chairlift_operational:
			return

	# Load next skier onto lift
	var skier: Skier = queue.pop_front()
	_rider_counts[lift.id] = riders + 1

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


func _on_skier_reached_trail_bottom(skier: Skier, trail: TrailDefinition) -> void:
	skier.arrive_at_base()

	# Group wait: if in a group, wait for others
	if skier.group_id >= 0:
		skier.waiting_for_group = true
		# Check after a short delay (handled by group system in SimulationManager)

	# Decide: ski again or leave?
	if skier.should_leave():
		SkierPool.release(skier)
		return

	# Pick next lift
	var next_lift := ResortData.get_random_lift_from_trail(trail.id)
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
