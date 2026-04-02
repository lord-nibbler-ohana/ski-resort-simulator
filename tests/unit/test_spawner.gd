extends GutTest


func test_weighted_random_occupants_range() -> void:
	# Test that all occupant counts are in valid range 1-5
	var spawner_script = load("res://systems/spawner.gd")
	var spawner_instance = spawner_script.new()
	add_child_autofree(spawner_instance)

	for i in range(100):
		var count: int = spawner_instance._weighted_random_occupants()
		assert_between(count, 1, 5, "Occupant count should be 1-5")


func test_weighted_random_occupants_distribution() -> void:
	# Mode should be 2 (35% weight)
	var spawner_script = load("res://systems/spawner.gd")
	var spawner_instance = spawner_script.new()
	add_child_autofree(spawner_instance)

	var counts := [0, 0, 0, 0, 0]
	var total := 5000

	for i in range(total):
		var n: int = spawner_instance._weighted_random_occupants()
		counts[n - 1] += 1

	var mode_count := counts[1]  # count of 2-person cars
	var mode_ratio := float(mode_count) / total
	assert_between(mode_ratio, 0.25, 0.45,
		"2-person cars should be most common (~35%%)")

	# Verify 1-person is less common than 2-person
	assert_gt(counts[1], counts[0],
		"2-person should be more common than 1-person")

	# Verify 5-person is least common
	assert_lt(counts[4], counts[0],
		"5-person should be less common than 1-person")
