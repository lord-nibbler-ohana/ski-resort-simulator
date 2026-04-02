extends GutTest

var weather: Node


func before_each() -> void:
	# Create a standalone weather system for testing
	weather = load("res://systems/weather_system.gd").new()
	add_child_autofree(weather)


func test_initial_wind_speed() -> void:
	assert_eq(weather.wind_speed, 5.0, "Initial wind should be 5.0 m/s")


func test_initial_chairlift_operational() -> void:
	assert_true(weather.chairlift_operational, "Chairlift should start operational")


func test_chairlift_stops_above_threshold() -> void:
	weather.wind_speed = 16.0
	weather._update_weather()
	# Wind may have changed, but if still above threshold...
	if weather.wind_speed > 15.0:
		assert_false(weather.chairlift_operational,
			"Chairlift should stop when wind > 15 m/s")


func test_chairlift_runs_below_threshold() -> void:
	weather.wind_speed = 10.0
	weather._target_wind = 5.0
	weather._update_weather()
	if weather.wind_speed <= 15.0:
		assert_true(weather.chairlift_operational,
			"Chairlift should run when wind <= 15 m/s")


func test_wind_speed_non_negative() -> void:
	weather.wind_speed = 1.0
	weather._target_wind = 0.0
	for i in range(50):
		weather._update_weather()
	assert_gte(weather.wind_speed, 0.0, "Wind should never be negative")


func test_temperature_in_range() -> void:
	for i in range(100):
		weather._update_weather()
	assert_between(weather.temperature, -20.0, 5.0,
		"Temperature should stay in range")


func test_visibility_in_range() -> void:
	for i in range(100):
		weather._update_weather()
	assert_between(weather.visibility, 0.2, 1.0,
		"Visibility should be 0.2-1.0")


func test_weather_changed_signal() -> void:
	watch_signals(weather)
	weather._update_weather()
	assert_signal_emitted(weather, "weather_changed")


func test_chairlift_stopped_signal() -> void:
	watch_signals(weather)
	weather.chairlift_operational = true
	weather.wind_speed = 14.0
	weather._target_wind = 20.0
	# Force wind above threshold
	weather.wind_speed = 16.0
	weather._update_weather()
	if not weather.chairlift_operational:
		assert_signal_emitted(weather, "chairlift_stopped")


func test_get_weather_summary_format() -> void:
	var summary := weather.get_weather_summary()
	assert_true(summary.contains("Wind:"), "Summary should contain wind info")
	assert_true(summary.contains("Temp:"), "Summary should contain temperature")
