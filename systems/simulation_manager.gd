extends Node

signal speed_changed(new_speed: float)
signal day_end_reached()

const DAY_START := 34200.0  # 09:30 in seconds since midnight
const DAY_END := 57600.0    # 16:00

var sim_speed: float = 1.0
var game_time: float = DAY_START
var day_ended: bool = false
var total_cars_arrived: int = 0
var total_skiers_spawned: int = 0

# Group tracking
var _next_group_id: int = 0
var _groups: Dictionary = {}  # group_id -> Array[Skier]

const GROUP_WAIT_TIMEOUT := 10.0  # seconds before group stops waiting


func _ready() -> void:
	ResortData.initialize()
	# Queue initialization happens after paths are registered (in main.gd)


func set_sim_speed(speed: float) -> void:
	sim_speed = speed
	speed_changed.emit(speed)


func pause() -> void:
	set_sim_speed(0.0)


func unpause() -> void:
	set_sim_speed(1.0)


func create_group(skiers: Array[Skier]) -> int:
	var gid := _next_group_id
	_next_group_id += 1
	_groups[gid] = skiers.duplicate()
	for skier in skiers:
		skier.group_id = gid
		if skier == skiers[0]:
			skier.is_group_leader = true
	return gid


func get_time_string() -> String:
	var hours := int(game_time) / 3600
	var minutes := (int(game_time) % 3600) / 60
	return "%02d:%02d" % [hours, minutes]


func _process(delta: float) -> void:
	if sim_speed <= 0.0:
		return

	# Advance game clock
	if not day_ended:
		game_time += delta * sim_speed
		if game_time >= DAY_END:
			game_time = DAY_END
			day_ended = true
			day_end_reached.emit()

	_check_group_waits()


func _check_group_waits() -> void:
	var completed_groups: Array[int] = []

	for gid in _groups:
		var members: Array = _groups[gid]
		# Remove released members
		members = members.filter(func(s: Skier): return s.state != Skier.State.INACTIVE)
		_groups[gid] = members

		if members.is_empty():
			completed_groups.append(gid)
			continue

		# Check if all waiting members are at base
		var all_at_base := true
		for skier: Skier in members:
			if skier.state != Skier.State.AT_BASE:
				all_at_base = false
				break

		if all_at_base:
			# Release the group wait
			for skier: Skier in members:
				skier.waiting_for_group = false

	for gid in completed_groups:
		_groups.erase(gid)


func get_stats() -> Dictionary:
	return {
		"active_skiers": SkierPool.active_count,
		"total_spawned": total_skiers_spawned,
		"total_cars": total_cars_arrived,
		"sim_speed": sim_speed,
		"time_display": get_time_string(),
		"day_ended": day_ended,
		"wind": WeatherSystem.wind_speed,
		"chairlift_ok": WeatherSystem.chairlift_operational,
	}
