extends GutTest


func before_all() -> void:
	ResortData.initialize()


func test_initialize_creates_queues_for_all_lifts() -> void:
	LiftQueueManager.initialize_queues()
	for lift in ResortData.lifts:
		assert_eq(LiftQueueManager.get_queue_length(lift.id), 0,
			"Queue for %s should start empty" % lift.id)


func test_enqueue_increases_length() -> void:
	LiftQueueManager.initialize_queues()
	var skier := Skier.new()
	add_child_autofree(skier)
	var lift_id := ResortData.lifts[0].id
	LiftQueueManager.enqueue(lift_id, skier)
	assert_eq(LiftQueueManager.get_queue_length(lift_id), 1)


func test_enqueue_sets_skier_state_to_queuing() -> void:
	LiftQueueManager.initialize_queues()
	var skier := Skier.new()
	add_child_autofree(skier)
	var lift_id := ResortData.lifts[0].id
	LiftQueueManager.enqueue(lift_id, skier)
	assert_eq(skier.state, Skier.State.QUEUING)


func test_queue_is_fifo() -> void:
	LiftQueueManager.initialize_queues()
	var lift_id := ResortData.lifts[0].id

	var skier1 := Skier.new()
	skier1.name = "First"
	add_child_autofree(skier1)

	var skier2 := Skier.new()
	skier2.name = "Second"
	add_child_autofree(skier2)

	LiftQueueManager.enqueue(lift_id, skier1)
	LiftQueueManager.enqueue(lift_id, skier2)

	assert_eq(LiftQueueManager.get_queue_length(lift_id), 2)
	# First skier should be at front (index 0)
	var queue: Array = LiftQueueManager._queues[lift_id]
	assert_eq(queue[0].name, "First")
	assert_eq(queue[1].name, "Second")


func test_rider_count_starts_at_zero() -> void:
	LiftQueueManager.initialize_queues()
	for lift in ResortData.lifts:
		assert_eq(LiftQueueManager.get_rider_count(lift.id), 0)
