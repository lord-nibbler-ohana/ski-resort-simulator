extends CanvasLayer

@onready var time_label: Label = %TimeLabel
@onready var stats_label: Label = %StatsLabel
@onready var weather_label: Label = %WeatherLabel
@onready var queue_label: Label = %QueueLabel
@onready var speed_label: Label = %SpeedLabel

var _update_timer: float = 0.0
const UPDATE_INTERVAL := 0.5  # Update HUD every 0.5s


func _ready() -> void:
	_setup_speed_buttons()
	WeatherSystem.chairlift_stopped.connect(_on_chairlift_stopped)
	WeatherSystem.chairlift_resumed.connect(_on_chairlift_resumed)


func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= UPDATE_INTERVAL:
		_update_timer = 0.0
		_update_display()


func _update_display() -> void:
	var stats := SimulationManager.get_stats()

	if time_label:
		var time_text: String = stats["time_display"]
		if stats["day_ended"]:
			time_text += " (CLOSED)"
		time_label.text = time_text

	if stats_label:
		stats_label.text = "Skiers: %d | Cars: %d | Total spawned: %d" % [
			stats["active_skiers"], stats["total_cars"], stats["total_spawned"]]

	if weather_label:
		weather_label.text = WeatherSystem.get_weather_summary()
		if not stats["chairlift_ok"]:
			weather_label.add_theme_color_override("font_color", Color.RED)
		else:
			weather_label.add_theme_color_override("font_color", Color.WHITE)

	if queue_label:
		var queue_text := "Queues: "
		var parts: PackedStringArray = []
		for lift in ResortData.lifts:
			var qlen := LiftQueueManager.get_queue_length(lift.id)
			var riders := LiftQueueManager.get_rider_count(lift.id)
			if qlen > 0 or riders > 0:
				parts.append("%s: %d/%d" % [lift.display_name.get_slice(" ", 0), qlen, riders])
		queue_label.text = queue_text + ", ".join(parts) if not parts.is_empty() else "Queues: empty"

	if speed_label:
		var spd := SimulationManager.sim_speed
		speed_label.text = "Speed: %sx" % (str(int(spd)) if spd == float(int(spd)) else str(spd))


func _setup_speed_buttons() -> void:
	pass  # Buttons connected via scene signals


func _on_pause_pressed() -> void:
	SimulationManager.set_sim_speed(0.0)


func _on_speed_1x_pressed() -> void:
	SimulationManager.set_sim_speed(1.0)


func _on_speed_4x_pressed() -> void:
	SimulationManager.set_sim_speed(4.0)


func _on_speed_10x_pressed() -> void:
	SimulationManager.set_sim_speed(10.0)


func _on_speed_25x_pressed() -> void:
	SimulationManager.set_sim_speed(25.0)


func _on_chairlift_stopped() -> void:
	print("WARNING: Chairlift stopped due to high wind (%.1f m/s)" % WeatherSystem.wind_speed)


func _on_chairlift_resumed() -> void:
	print("Chairlift resumed operation (wind: %.1f m/s)" % WeatherSystem.wind_speed)
