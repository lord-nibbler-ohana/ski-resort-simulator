extends Node
class_name ResortData

# Elevation data for Sirdal Fjellpark (meters above sea level)
# Sources: skiresort.info, j2ski.com, snow-forecast.com
# Base area (Hulderheimen/parking): ~560m
# Tjørhomfjellet summit (chairlift top): ~928m
# Nyestøl area top: ~700m
# Ålsheia summit: ~810m
# Mid-station/crossover: ~776m
# GPS: 58.913268 N, 6.836670 E

static var lifts: Array[LiftDefinition] = []
static var trails: Array[TrailDefinition] = []
static var parking: Array[ParkingDefinition] = []

static var _lifts_by_id: Dictionary = {}
static var _trails_by_id: Dictionary = {}
static var _parking_by_id: Dictionary = {}


static func initialize() -> void:
	_create_lifts()
	_create_trails()
	_create_parking()
	_build_indices()


static func _build_indices() -> void:
	_lifts_by_id.clear()
	_trails_by_id.clear()
	_parking_by_id.clear()
	for l in lifts:
		_lifts_by_id[l.id] = l
	for t in trails:
		_trails_by_id[t.id] = t
	for p in parking:
		_parking_by_id[p.id] = p


static func get_lift(id: String) -> LiftDefinition:
	return _lifts_by_id.get(id)


static func get_trail(id: String) -> TrailDefinition:
	return _trails_by_id.get(id)


static func get_parking(id: String) -> ParkingDefinition:
	return _parking_by_id.get(id)


static func get_random_trail_from_lift(lift_id: String) -> TrailDefinition:
	var lift := get_lift(lift_id)
	if lift == null or lift.connected_trail_ids.is_empty():
		return null
	var trail_id := lift.connected_trail_ids[randi() % lift.connected_trail_ids.size()]
	return get_trail(trail_id)


static func get_random_lift_from_trail(trail_id: String) -> LiftDefinition:
	var trail := get_trail(trail_id)
	if trail == null or trail.connected_lift_ids.is_empty():
		return null
	var lift_id := trail.connected_lift_ids[randi() % trail.connected_lift_ids.size()]
	return get_lift(lift_id)


static func get_random_parking() -> ParkingDefinition:
	if parking.is_empty():
		return null
	return parking[randi() % parking.size()]


static func _create_lifts() -> void:
	lifts.clear()

	# Tjørhomfjellet area - main chairlift (LEITNER 4-seat detachable, 1404m long)
	lifts.append(_make_lift("tjørhom_chair", "Tjørhomfjellet Stolheis",
		LiftDefinition.LiftType.CHAIRLIFT, 15.0, "LiftTjorhomChair",
		60, 560.0, 928.0,
		["trail_tjørhom_green_1", "trail_tjørhom_blue_1", "trail_tjørhom_red_1"]))

	# Tjørhomfjellet T-bar
	lifts.append(_make_lift("tjørhom_tbar", "Tjørhomfjellet Skitrekk",
		LiftDefinition.LiftType.TBAR, 8.0, "LiftTjorhomTbar",
		30, 560.0, 776.0,
		["trail_tjørhom_green_1", "trail_tjørhom_blue_1"]))

	# Hulderheimen button lift (beginner/children's area)
	lifts.append(_make_lift("hulderheimen_button", "Hulderheimen Knappheis",
		LiftDefinition.LiftType.BUTTON, 8.0, "LiftHulderButton",
		20, 560.0, 620.0,
		["trail_hulder_green_1", "trail_hulder_green_2"]))

	# Nyestøl T-bar 1 (Dåfjellheisen)
	lifts.append(_make_lift("nyestol_tbar_1", "Dåfjellheisen",
		LiftDefinition.LiftType.TBAR, 8.0, "LiftNyestolTbar1",
		30, 560.0, 700.0,
		["trail_nyestol_blue_1", "trail_nyestol_green_1"]))

	# Nyestøl T-bar 2 (Slettekvævheisen)
	lifts.append(_make_lift("nyestol_tbar_2", "Slettekvævheisen",
		LiftDefinition.LiftType.TBAR, 8.0, "LiftNyestolTbar2",
		25, 580.0, 700.0,
		["trail_nyestol_blue_2", "trail_nyestol_red_1"]))

	# Ålsheia T-bar 1
	lifts.append(_make_lift("alsheia_tbar_1", "Ålsheia Skitrekk 1",
		LiftDefinition.LiftType.TBAR, 8.0, "LiftAlsheiaTbar1",
		30, 560.0, 810.0,
		["trail_alsheia_blue_1", "trail_alsheia_red_1", "trail_alsheia_green_1"]))

	# Ålsheia T-bar 2
	lifts.append(_make_lift("alsheia_tbar_2", "Ålsheia Skitrekk 2",
		LiftDefinition.LiftType.TBAR, 8.0, "LiftAlsheiaTbar2",
		25, 560.0, 740.0,
		["trail_alsheia_blue_2", "trail_alsheia_green_1"]))

	# Ålsheia button lift (lower)
	lifts.append(_make_lift("alsheia_button", "Ålsheia Knappheis",
		LiftDefinition.LiftType.BUTTON, 8.0, "LiftAlsheiaButton",
		20, 560.0, 650.0,
		["trail_alsheia_green_2"]))


static func _create_trails() -> void:
	trails.clear()

	# Tjørhomfjellet trails (summit 928m, base 560m, vertical 368m)
	trails.append(_make_trail("trail_tjørhom_green_1", "Tjørhom Grønn",
		TrailDefinition.Difficulty.GREEN, "TrailTjorhomGreen1",
		"tjørhomfjellet", 928.0, 560.0,
		["tjørhom_chair", "tjørhom_tbar"]))
	trails.append(_make_trail("trail_tjørhom_blue_1", "Tjørhom Blå",
		TrailDefinition.Difficulty.BLUE, "TrailTjorhomBlue1",
		"tjørhomfjellet", 928.0, 560.0,
		["tjørhom_chair", "tjørhom_tbar"]))
	trails.append(_make_trail("trail_tjørhom_red_1", "Tjørhom Rød",
		TrailDefinition.Difficulty.RED, "TrailTjorhomRed1",
		"tjørhomfjellet", 928.0, 560.0,
		["tjørhom_chair", "tjørhom_tbar"]))

	# Hulderheimen trails (beginner/children's area, 620m top, 560m base)
	trails.append(_make_trail("trail_hulder_green_1", "Hulderheimen Grønn 1",
		TrailDefinition.Difficulty.GREEN, "TrailHulderGreen1",
		"hulderheimen", 620.0, 560.0,
		["hulderheimen_button", "tjørhom_tbar"]))
	trails.append(_make_trail("trail_hulder_green_2", "Hulderheimen Grønn 2",
		TrailDefinition.Difficulty.GREEN, "TrailHulderGreen2",
		"hulderheimen", 620.0, 560.0,
		["hulderheimen_button"]))

	# Nyestøl trails (top 700m, base 560m)
	trails.append(_make_trail("trail_nyestol_green_1", "Nyestøl Grønn",
		TrailDefinition.Difficulty.GREEN, "TrailNyestolGreen1",
		"nyestøl", 700.0, 560.0,
		["nyestol_tbar_1", "nyestol_tbar_2"]))
	trails.append(_make_trail("trail_nyestol_blue_1", "Nyestøl Blå 1",
		TrailDefinition.Difficulty.BLUE, "TrailNyestolBlue1",
		"nyestøl", 700.0, 560.0,
		["nyestol_tbar_1", "nyestol_tbar_2"]))
	trails.append(_make_trail("trail_nyestol_blue_2", "Nyestøl Blå 2",
		TrailDefinition.Difficulty.BLUE, "TrailNyestolBlue2",
		"nyestøl", 700.0, 580.0,
		["nyestol_tbar_1", "nyestol_tbar_2"]))
	trails.append(_make_trail("trail_nyestol_red_1", "Nyestøl Rød",
		TrailDefinition.Difficulty.RED, "TrailNyestolRed1",
		"nyestøl", 700.0, 580.0,
		["nyestol_tbar_1", "nyestol_tbar_2"]))

	# Ålsheia trails (summit 810m, base 560m)
	trails.append(_make_trail("trail_alsheia_green_1", "Ålsheia Grønn 1",
		TrailDefinition.Difficulty.GREEN, "TrailAlsheiaGreen1",
		"ålsheia", 740.0, 560.0,
		["alsheia_tbar_1", "alsheia_tbar_2"]))
	trails.append(_make_trail("trail_alsheia_green_2", "Ålsheia Grønn 2",
		TrailDefinition.Difficulty.GREEN, "TrailAlsheiaGreen2",
		"ålsheia", 650.0, 560.0,
		["alsheia_button"]))
	trails.append(_make_trail("trail_alsheia_blue_1", "Ålsheia Blå 1",
		TrailDefinition.Difficulty.BLUE, "TrailAlsheiaBlue1",
		"ålsheia", 810.0, 560.0,
		["alsheia_tbar_1", "alsheia_tbar_2"]))
	trails.append(_make_trail("trail_alsheia_blue_2", "Ålsheia Blå 2",
		TrailDefinition.Difficulty.BLUE, "TrailAlsheiaBlue2",
		"ålsheia", 740.0, 560.0,
		["alsheia_tbar_1", "alsheia_tbar_2"]))
	trails.append(_make_trail("trail_alsheia_red_1", "Ålsheia Rød",
		TrailDefinition.Difficulty.RED, "TrailAlsheiaRed1",
		"ålsheia", 810.0, 560.0,
		["alsheia_tbar_1", "alsheia_tbar_2"]))

	# Cross-mountain connection trails
	trails.append(_make_trail("trail_connect_tjørhom_nyestol", "Forbindelse Tjørhom-Nyestøl",
		TrailDefinition.Difficulty.BLUE, "TrailConnectTjorhomNyestol",
		"tjørhomfjellet", 776.0, 560.0,
		["nyestol_tbar_1"]))
	trails.append(_make_trail("trail_connect_nyestol_alsheia", "Forbindelse Nyestøl-Ålsheia",
		TrailDefinition.Difficulty.GREEN, "TrailConnectNyestolAlsheia",
		"nyestøl", 700.0, 560.0,
		["alsheia_tbar_1"]))


static func _create_parking() -> void:
	parking.clear()

	# Main parking at Hulderheimen (lower left of map)
	parking.append(_make_parking("parking_hulderheimen", "Hulderheimen P",
		Vector2(650, 2100), ["hulderheimen_button", "tjørhom_tbar"], "WalkHulderheimen"))

	# Parking near Tjørhomfjellet
	parking.append(_make_parking("parking_tjørhom", "Tjørhomfjellet P",
		Vector2(1200, 2000), ["tjørhom_chair", "tjørhom_tbar"], "WalkTjorhom"))

	# Parking near Nyestøl
	parking.append(_make_parking("parking_nyestol", "Nyestøl P",
		Vector2(2800, 2100), ["nyestol_tbar_1"], "WalkNyestol"))

	# Parking near Ålsheia
	parking.append(_make_parking("parking_alsheia", "Ålsheia P",
		Vector2(4400, 1900), ["alsheia_tbar_1", "alsheia_button"], "WalkAlsheia"))


static func _make_lift(id: String, name: String, type: LiftDefinition.LiftType,
		speed: float, path_name: String, cap: int,
		base_elev: float, summit_elev: float,
		trail_ids: Array) -> LiftDefinition:
	var l := LiftDefinition.new()
	l.id = id
	l.display_name = name
	l.lift_type = type
	l.speed_kmh = speed
	l.path_node_name = path_name
	l.capacity = cap
	l.base_elevation = base_elev
	l.summit_elevation = summit_elev
	l.connected_trail_ids = PackedStringArray(trail_ids)
	return l


static func _make_trail(id: String, name: String, diff: TrailDefinition.Difficulty,
		path_name: String, area: String,
		start_elev: float, end_elev: float,
		lift_ids: Array) -> TrailDefinition:
	var t := TrailDefinition.new()
	t.id = id
	t.display_name = name
	t.difficulty = diff
	t.path_node_name = path_name
	t.mountain_area = area
	t.start_elevation = start_elev
	t.end_elevation = end_elev
	t.connected_lift_ids = PackedStringArray(lift_ids)
	return t


static func _make_parking(id: String, name: String, pos: Vector2,
		lift_ids: Array, walk_path: String) -> ParkingDefinition:
	var p := ParkingDefinition.new()
	p.id = id
	p.display_name = name
	p.position = pos
	p.nearest_lift_ids = PackedStringArray(lift_ids)
	p.walk_path_node_name = walk_path
	return p
