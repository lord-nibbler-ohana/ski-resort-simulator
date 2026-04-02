extends GutTest


func before_all() -> void:
	ResortData.initialize()


func test_lifts_not_empty() -> void:
	assert_gt(ResortData.lifts.size(), 0, "Should have lifts defined")


func test_trails_not_empty() -> void:
	assert_gt(ResortData.trails.size(), 0, "Should have trails defined")


func test_parking_not_empty() -> void:
	assert_gt(ResortData.parking.size(), 0, "Should have parking defined")


func test_lift_ids_unique() -> void:
	var ids: Dictionary = {}
	for lift in ResortData.lifts:
		assert_false(ids.has(lift.id), "Duplicate lift ID: %s" % lift.id)
		ids[lift.id] = true


func test_trail_ids_unique() -> void:
	var ids: Dictionary = {}
	for trail in ResortData.trails:
		assert_false(ids.has(trail.id), "Duplicate trail ID: %s" % trail.id)
		ids[trail.id] = true


func test_parking_ids_unique() -> void:
	var ids: Dictionary = {}
	for p in ResortData.parking:
		assert_false(ids.has(p.id), "Duplicate parking ID: %s" % p.id)
		ids[p.id] = true


func test_lift_connected_trails_exist() -> void:
	for lift in ResortData.lifts:
		for trail_id in lift.connected_trail_ids:
			var trail := ResortData.get_trail(trail_id)
			assert_not_null(trail, "Lift %s references missing trail: %s" % [lift.id, trail_id])


func test_trail_connected_lifts_exist() -> void:
	for trail in ResortData.trails:
		for lift_id in trail.connected_lift_ids:
			var lift := ResortData.get_lift(lift_id)
			assert_not_null(lift, "Trail %s references missing lift: %s" % [trail.id, lift_id])


func test_parking_nearest_lifts_exist() -> void:
	for p in ResortData.parking:
		assert_gt(p.nearest_lift_ids.size(), 0, "Parking %s has no lifts" % p.id)
		for lift_id in p.nearest_lift_ids:
			var lift := ResortData.get_lift(lift_id)
			assert_not_null(lift, "Parking %s references missing lift: %s" % [p.id, lift_id])


func test_every_lift_has_at_least_one_trail() -> void:
	for lift in ResortData.lifts:
		assert_gt(lift.connected_trail_ids.size(), 0,
			"Lift %s has no connected trails" % lift.id)


func test_every_trail_has_at_least_one_lift() -> void:
	for trail in ResortData.trails:
		assert_gt(trail.connected_lift_ids.size(), 0,
			"Trail %s has no connected lifts" % trail.id)


func test_chairlift_speed_is_15() -> void:
	for lift in ResortData.lifts:
		if lift.lift_type == LiftDefinition.LiftType.CHAIRLIFT:
			assert_eq(lift.speed_kmh, 15.0,
				"Chairlift %s should be 15 km/h" % lift.id)


func test_other_lift_speed_is_8() -> void:
	for lift in ResortData.lifts:
		if lift.lift_type != LiftDefinition.LiftType.CHAIRLIFT:
			assert_eq(lift.speed_kmh, 8.0,
				"Non-chairlift %s should be 8 km/h" % lift.id)


func test_elevation_consistency() -> void:
	for lift in ResortData.lifts:
		assert_gt(lift.summit_elevation, lift.base_elevation,
			"Lift %s summit should be higher than base" % lift.id)
	for trail in ResortData.trails:
		assert_gt(trail.start_elevation, trail.end_elevation,
			"Trail %s start should be higher than end" % trail.id)


func test_get_random_trail_from_lift() -> void:
	for lift in ResortData.lifts:
		var trail := ResortData.get_random_trail_from_lift(lift.id)
		assert_not_null(trail, "Should get a trail from lift %s" % lift.id)


func test_get_random_lift_from_trail() -> void:
	for trail in ResortData.trails:
		var lift := ResortData.get_random_lift_from_trail(trail.id)
		assert_not_null(lift, "Should get a lift from trail %s" % trail.id)


func test_expected_lift_count() -> void:
	assert_eq(ResortData.lifts.size(), 8, "Should have 8 lifts")


func test_has_one_chairlift() -> void:
	var count := 0
	for lift in ResortData.lifts:
		if lift.lift_type == LiftDefinition.LiftType.CHAIRLIFT:
			count += 1
	assert_eq(count, 1, "Should have exactly 1 chairlift")
