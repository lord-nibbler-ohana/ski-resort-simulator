extends GutTest

var skier: Skier
var test_path: Path2D


func before_each() -> void:
	# PathFollow2D needs a Path2D parent to set progress_ratio
	test_path = Path2D.new()
	var curve := Curve2D.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(100, 100))
	test_path.curve = curve
	add_child_autofree(test_path)

	skier = Skier.new()
	test_path.add_child(skier)


func test_initial_state_is_inactive() -> void:
	assert_eq(skier.state, Skier.State.INACTIVE)


func test_initialize_random_sets_entity_type() -> void:
	skier.initialize_random()
	assert_true(
		skier.entity_type == Skier.EntityType.SKIER or
		skier.entity_type == Skier.EntityType.SNOWBOARDER
	)


func test_initialize_random_sets_skill_level() -> void:
	skier.initialize_random()
	assert_true(
		skier.skill_level >= Skier.SkillLevel.BEGINNER and
		skier.skill_level <= Skier.SkillLevel.EXPERT
	)


func test_speed_multiplier_positive() -> void:
	skier.initialize_random()
	assert_gt(skier.speed_multiplier, 0.0, "Speed multiplier should be positive")


func test_set_state_walking() -> void:
	skier.set_state(Skier.State.WALKING)
	assert_eq(skier.state, Skier.State.WALKING)
	assert_true(skier.visible)


func test_set_state_inactive_hides() -> void:
	skier.set_state(Skier.State.WALKING)
	skier.set_state(Skier.State.INACTIVE)
	assert_false(skier.visible)


func test_start_queuing() -> void:
	skier.start_queuing()
	assert_eq(skier.state, Skier.State.QUEUING)
	assert_eq(skier.speed_px_per_sec, 0.0)


func test_start_riding_lift() -> void:
	skier.start_riding_lift(15.0)
	assert_eq(skier.state, Skier.State.RIDING_LIFT)
	assert_gt(skier.speed_px_per_sec, 0.0)


func test_start_skiing_green() -> void:
	skier.initialize_random()
	skier.start_skiing(TrailDefinition.Difficulty.GREEN)
	assert_eq(skier.state, Skier.State.SKIING_DOWN)
	assert_gt(skier.speed_px_per_sec, 0.0)


func test_skiing_speed_increases_with_difficulty() -> void:
	skier.initialize_random()
	skier.speed_multiplier = 1.0  # Normalize for comparison

	skier.start_skiing(TrailDefinition.Difficulty.GREEN)
	var green_speed := skier.speed_px_per_sec

	skier.start_skiing(TrailDefinition.Difficulty.BLUE)
	var blue_speed := skier.speed_px_per_sec

	skier.start_skiing(TrailDefinition.Difficulty.RED)
	var red_speed := skier.speed_px_per_sec

	assert_gt(blue_speed, green_speed, "Blue should be faster than green")
	assert_gt(red_speed, blue_speed, "Red should be faster than blue")


func test_arrive_at_base_increments_runs() -> void:
	skier.arrive_at_base()
	assert_eq(skier.runs_completed, 1)
	skier.arrive_at_base()
	assert_eq(skier.runs_completed, 2)


func test_deactivate_resets_all() -> void:
	skier.initialize_random()
	skier.set_state(Skier.State.SKIING_DOWN)
	skier.runs_completed = 5
	skier.group_id = 3
	skier.current_lift_id = "test"

	skier.deactivate()

	assert_eq(skier.state, Skier.State.INACTIVE)
	assert_eq(skier.runs_completed, 0)
	assert_eq(skier.group_id, -1)
	assert_eq(skier.current_lift_id, "")


func test_state_changed_signal() -> void:
	watch_signals(skier)
	skier.set_state(Skier.State.WALKING)
	assert_signal_emitted(skier, "state_changed")


func test_snowboarder_distribution() -> void:
	# Statistical test: over many runs, ~20% should be snowboarders
	var snowboard_count := 0
	var total := 1000
	for i in range(total):
		var s := Skier.new()
		add_child_autofree(s)
		s.initialize_random()
		if s.entity_type == Skier.EntityType.SNOWBOARDER:
			snowboard_count += 1
	var ratio := float(snowboard_count) / total
	assert_between(ratio, 0.12, 0.28, "Snowboarder ratio should be ~20%%")


func test_group_id_default_solo() -> void:
	assert_eq(skier.group_id, -1, "Default should be solo (-1)")
	assert_false(skier.is_group_leader)
	assert_false(skier.waiting_for_group)
