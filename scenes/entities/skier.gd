extends PathFollow2D
class_name Skier

enum State { INACTIVE, WALKING, QUEUING, RIDING_LIFT, AT_SUMMIT, SKIING_DOWN, AT_BASE, LUNCH }
enum EntityType { SKIER, SNOWBOARDER }
enum SkillLevel { BEGINNER, INTERMEDIATE, ADVANCED, EXPERT }

signal state_changed(new_state: State)
signal reached_path_end()

# Identity
var entity_type: EntityType = EntityType.SKIER
var skill_level: SkillLevel = SkillLevel.INTERMEDIATE

# State
var state: State = State.INACTIVE
var current_lift_id: String = ""
var current_trail_id: String = ""
var runs_completed: int = 0
var speed_px_per_sec: float = 0.0

# Group system
var group_id: int = -1  # -1 = solo
var is_group_leader: bool = false
var waiting_for_group: bool = false

# Stay duration
var arrival_time: float = 0.0
var planned_departure_time: float = 57600.0  # default end of day

# Lunch
var has_eaten_lunch: bool = false
var lunch_timer: float = 0.0
const LUNCH_DURATION := 2700.0  # 45 minutes in seconds

# Skill-based speed multiplier
var speed_multiplier: float = 1.0

# Stop points during skiing (skiers pause 3-5 times per run)
var _stop_points: Array[float] = []
var _stop_timer: float = 0.0
var _is_stopped: bool = false
var _stored_speed: float = 0.0

# Visual
var sprite: Sprite2D
var circle_texture: ImageTexture

# Colors per state
const STATE_COLORS := {
	State.INACTIVE: Color(0.5, 0.5, 0.5, 0.0),
	State.WALKING: Color(1.0, 0.9, 0.2),       # Yellow
	State.QUEUING: Color(1.0, 0.6, 0.1),        # Orange
	State.RIDING_LIFT: Color(0.2, 0.5, 1.0),    # Blue
	State.AT_SUMMIT: Color(0.7, 0.2, 1.0),      # Purple
	State.SKIING_DOWN: Color(0.1, 0.9, 0.3),    # Green
	State.AT_BASE: Color(0.8, 0.8, 0.8),        # Gray
	State.LUNCH: Color(0.9, 0.5, 0.1),          # Dark orange
}

# Snowboarder is slightly different shade
const SNOWBOARDER_TINT := Color(1.0, 0.85, 0.85)

# Ski speed by difficulty (km/h base, modified by skill)
const TRAIL_SPEED_KMH := {
	TrailDefinition.Difficulty.GREEN: 12.0,
	TrailDefinition.Difficulty.BLUE: 22.0,
	TrailDefinition.Difficulty.RED: 32.0,
}

# Speed conversion: map is ~5551px wide, representing ~2km
const MAP_PIXELS_PER_KM := 2775.0
const GAME_SPEED_MULTIPLIER := 1.0


func _ready() -> void:
	_create_circle_sprite()
	loop = false
	rotates = false


func _create_circle_sprite() -> void:
	sprite = Sprite2D.new()
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	var center := Vector2(6, 6)
	for x in range(12):
		for y in range(12):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= 5.0:
				img.set_pixel(x, y, Color.WHITE)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	circle_texture = ImageTexture.create_from_image(img)
	sprite.texture = circle_texture
	add_child(sprite)
	_update_color()


func initialize_random() -> void:
	# 80% skiers, 20% snowboarders (Norwegian stats)
	entity_type = EntityType.SNOWBOARDER if randf() < 0.2 else EntityType.SKIER

	# Skill distribution
	var roll := randf()
	if roll < 0.25:
		skill_level = SkillLevel.BEGINNER
	elif roll < 0.60:
		skill_level = SkillLevel.INTERMEDIATE
	elif roll < 0.85:
		skill_level = SkillLevel.ADVANCED
	else:
		skill_level = SkillLevel.EXPERT

	# Speed multiplier based on skill
	match skill_level:
		SkillLevel.BEGINNER:
			speed_multiplier = 0.6 + randf() * 0.2  # 0.6-0.8
		SkillLevel.INTERMEDIATE:
			speed_multiplier = 0.8 + randf() * 0.3  # 0.8-1.1
		SkillLevel.ADVANCED:
			speed_multiplier = 1.0 + randf() * 0.3  # 1.0-1.3
		SkillLevel.EXPERT:
			speed_multiplier = 1.2 + randf() * 0.4  # 1.2-1.6

	# Snowboarders slightly slower on average
	if entity_type == EntityType.SNOWBOARDER:
		speed_multiplier *= 0.9


func set_state(new_state: State) -> void:
	state = new_state
	_update_color()
	state_changed.emit(new_state)

	if new_state == State.INACTIVE:
		visible = false
	else:
		visible = true


func _update_color() -> void:
	if sprite == null:
		return
	var color: Color = STATE_COLORS.get(state, Color.WHITE)
	if entity_type == EntityType.SNOWBOARDER:
		color *= SNOWBOARDER_TINT
	sprite.modulate = color


func start_walking(walk_speed_kmh: float) -> void:
	set_state(State.WALKING)
	progress_ratio = 0.0
	speed_px_per_sec = _kmh_to_px_per_sec(walk_speed_kmh)


func start_queuing() -> void:
	set_state(State.QUEUING)
	speed_px_per_sec = 0.0


func start_riding_lift(lift_speed_kmh: float) -> void:
	set_state(State.RIDING_LIFT)
	progress_ratio = 0.0
	speed_px_per_sec = _kmh_to_px_per_sec(lift_speed_kmh)


func start_skiing(difficulty: TrailDefinition.Difficulty) -> void:
	set_state(State.SKIING_DOWN)
	progress_ratio = 0.0
	var base_speed: float = TRAIL_SPEED_KMH.get(difficulty, 20.0)
	speed_px_per_sec = _kmh_to_px_per_sec(base_speed * speed_multiplier)

	# Generate random stop points along the run
	_is_stopped = false
	_stop_timer = 0.0
	_stored_speed = 0.0
	var num_stops: int
	match skill_level:
		SkillLevel.BEGINNER:
			num_stops = randi_range(4, 6)
		SkillLevel.INTERMEDIATE:
			num_stops = randi_range(3, 5)
		SkillLevel.ADVANCED:
			num_stops = randi_range(3, 4)
		SkillLevel.EXPERT:
			num_stops = randi_range(2, 3)
		_:
			num_stops = randi_range(3, 5)
	_stop_points.clear()
	for i in range(num_stops):
		_stop_points.append(randf_range(0.1, 0.9))
	_stop_points.sort()


func set_arrival_time(time: float) -> void:
	arrival_time = time
	var stay_hours := _normal_random(4.0, 1.0)
	stay_hours = clampf(stay_hours, 1.5, 6.5)
	planned_departure_time = arrival_time + stay_hours * 3600.0


func start_lunch() -> void:
	set_state(State.LUNCH)
	speed_px_per_sec = 0.0
	lunch_timer = LUNCH_DURATION
	has_eaten_lunch = true


func arrive_at_base() -> void:
	set_state(State.AT_BASE)
	runs_completed += 1
	speed_px_per_sec = 0.0


func deactivate() -> void:
	set_state(State.INACTIVE)
	current_lift_id = ""
	current_trail_id = ""
	runs_completed = 0
	group_id = -1
	is_group_leader = false
	waiting_for_group = false
	speed_px_per_sec = 0.0
	_stop_points.clear()
	_is_stopped = false
	_stop_timer = 0.0
	_stored_speed = 0.0
	arrival_time = 0.0
	planned_departure_time = 57600.0
	has_eaten_lunch = false
	lunch_timer = 0.0


func should_leave() -> bool:
	# Time-based departure: leave if past planned departure time
	if SimulationManager.game_time >= planned_departure_time:
		return true
	# Day ended: everyone leaves
	if SimulationManager.day_ended:
		return true
	# Higher chance of leaving after more runs, beginners leave sooner
	var base_chance := 0.05 * runs_completed
	if skill_level == SkillLevel.BEGINNER:
		base_chance *= 2.0
	elif skill_level == SkillLevel.EXPERT:
		base_chance *= 0.5
	return randf() < base_chance


func _process(delta: float) -> void:
	if state == State.LUNCH:
		lunch_timer -= delta * SimulationManager.sim_speed
		if lunch_timer <= 0.0:
			arrive_at_base()
			reached_path_end.emit()
		return

	if state == State.WALKING or state == State.RIDING_LIFT or state == State.SKIING_DOWN:
		if waiting_for_group:
			return
		var sim_delta := delta * SimulationManager.sim_speed

		# Handle stop points during skiing
		if state == State.SKIING_DOWN and _is_stopped:
			_stop_timer -= sim_delta
			if _stop_timer <= 0.0:
				_is_stopped = false
				speed_px_per_sec = _stored_speed
			return

		progress += speed_px_per_sec * sim_delta

		# Check if we passed a stop point
		if state == State.SKIING_DOWN and not _stop_points.is_empty():
			if progress_ratio >= _stop_points[0]:
				_stop_points.remove_at(0)
				_stored_speed = speed_px_per_sec
				speed_px_per_sec = 0.0
				_is_stopped = true
				_stop_timer = randf_range(5.0, 15.0)

		if progress_ratio >= 1.0:
			progress_ratio = 1.0
			reached_path_end.emit()


func _kmh_to_px_per_sec(kmh: float) -> float:
	return kmh * MAP_PIXELS_PER_KM / 3600.0 * GAME_SPEED_MULTIPLIER


static func _normal_random(mean: float, std_dev: float) -> float:
	var u1 := maxf(randf(), 0.0001)
	var u2 := randf()
	var z := sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
	return mean + std_dev * z
