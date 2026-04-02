extends Node

signal weather_changed()
signal chairlift_stopped()
signal chairlift_resumed()

const WIND_STOP_THRESHOLD := 15.0  # m/s - chairlift stops above this
const WEATHER_UPDATE_INTERVAL := 30.0  # seconds between weather changes
const WIND_CHANGE_RATE := 2.0  # max m/s change per update

var wind_speed: float = 5.0  # m/s
var wind_direction: float = 0.0  # degrees, 0=north
var temperature: float = -5.0  # Celsius
var is_snowing: bool = false
var visibility: float = 1.0  # 0.0 to 1.0

var chairlift_operational: bool = true

var _weather_timer: float = 0.0
var _target_wind: float = 5.0


func _ready() -> void:
	_randomize_target_weather()


func _process(delta: float) -> void:
	_weather_timer += delta * SimulationManager.sim_speed
	if _weather_timer >= WEATHER_UPDATE_INTERVAL:
		_weather_timer = 0.0
		_update_weather()


func _update_weather() -> void:
	# Gradually approach target wind
	var wind_delta := clampf(_target_wind - wind_speed, -WIND_CHANGE_RATE, WIND_CHANGE_RATE)
	wind_speed = maxf(0.0, wind_speed + wind_delta)

	# Small random temperature fluctuation
	temperature += randf_range(-0.5, 0.5)
	temperature = clampf(temperature, -20.0, 5.0)

	# Wind direction drifts
	wind_direction = fmod(wind_direction + randf_range(-15.0, 15.0), 360.0)

	# Snow probability based on temperature
	is_snowing = temperature < -2.0 and randf() < 0.3

	# Visibility affected by snow and wind
	visibility = 1.0
	if is_snowing:
		visibility -= 0.3
	if wind_speed > 10.0:
		visibility -= (wind_speed - 10.0) * 0.05
	visibility = clampf(visibility, 0.2, 1.0)

	# Occasionally pick a new target wind
	if randf() < 0.3:
		_randomize_target_weather()

	# Check chairlift threshold
	var was_operational := chairlift_operational
	chairlift_operational = wind_speed <= WIND_STOP_THRESHOLD

	if was_operational and not chairlift_operational:
		chairlift_stopped.emit()
	elif not was_operational and chairlift_operational:
		chairlift_resumed.emit()

	weather_changed.emit()


func _randomize_target_weather() -> void:
	# Target wind: mostly calm, occasionally gusty
	if randf() < 0.15:
		_target_wind = randf_range(12.0, 22.0)  # Storm
	elif randf() < 0.3:
		_target_wind = randf_range(8.0, 14.0)  # Windy
	else:
		_target_wind = randf_range(1.0, 8.0)  # Normal


func get_wind_display() -> String:
	return "%.1f m/s" % wind_speed


func get_weather_summary() -> String:
	var parts := []
	parts.append("Wind: %s" % get_wind_display())
	parts.append("Temp: %d°C" % int(temperature))
	if is_snowing:
		parts.append("Snowing")
	if not chairlift_operational:
		parts.append("CHAIRLIFT STOPPED")
	return " | ".join(parts)
