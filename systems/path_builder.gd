extends Node
class_name PathBuilder

## Builds all Path2D curves from pixel coordinate data.
## Coordinates are approximate, traced from the Sirdal Fjellpark trail map (5551x2776px).
## Call build_all_paths() after the scene tree is ready.

# Map dimensions for reference
const MAP_WIDTH := 5551
const MAP_HEIGHT := 2776


static func build_all_paths(paths_container: Node2D) -> void:
	_build_lift_paths(paths_container.get_node("Lifts"))
	_build_trail_paths(paths_container.get_node("Trails"))
	_build_walk_paths(paths_container.get_node("WalkPaths"))


static func _build_lift_paths(lifts_node: Node2D) -> void:
	# Lifts go from base (bottom) to summit (top)
	# On the map: y decreases = higher elevation

	# Tjørhomfjellet Chairlift - long lift on the left, going up to the peak
	_set_curve(lifts_node, "LiftTjorhomChair", [
		Vector2(1050, 1850),  # Base
		Vector2(950, 1400),
		Vector2(850, 900),
		Vector2(900, 500),    # Summit ~928m
	])

	# Tjørhomfjellet T-bar - shorter, parallel to chairlift
	_set_curve(lifts_node, "LiftTjorhomTbar", [
		Vector2(1150, 1850),  # Base
		Vector2(1100, 1400),
		Vector2(1050, 1000),  # Top ~820m
	])

	# Hulderheimen Button lift - short beginner lift on far left
	_set_curve(lifts_node, "LiftHulderButton", [
		Vector2(550, 2000),   # Base
		Vector2(500, 1700),
		Vector2(480, 1500),   # Top ~720m
	])

	# Nyestøl T-bar 1 - center area
	_set_curve(lifts_node, "LiftNyestolTbar1", [
		Vector2(2500, 1800),  # Base
		Vector2(2400, 1300),
		Vector2(2350, 850),   # Top ~780m
	])

	# Nyestøl T-bar 2 - center-right
	_set_curve(lifts_node, "LiftNyestolTbar2", [
		Vector2(2900, 1750),  # Base
		Vector2(2850, 1300),
		Vector2(2800, 800),   # Top ~800m
	])

	# Ålsheia T-bar 1 - right area, main lift
	_set_curve(lifts_node, "LiftAlsheiaTbar1", [
		Vector2(4200, 1800),  # Base
		Vector2(4150, 1300),
		Vector2(4100, 700),   # Top ~860m
	])

	# Ålsheia T-bar 2 - right area, secondary
	_set_curve(lifts_node, "LiftAlsheiaTbar2", [
		Vector2(4500, 1750),  # Base
		Vector2(4450, 1300),
		Vector2(4400, 900),   # Top ~800m
	])

	# Ålsheia Button lift - short, lower right
	_set_curve(lifts_node, "LiftAlsheiaButton", [
		Vector2(4700, 1900),  # Base
		Vector2(4650, 1650),
		Vector2(4600, 1400),  # Top ~740m
	])


static func _build_trail_paths(trails_node: Node2D) -> void:
	# Trails go from summit (top) to base (bottom)
	# Higher difficulty = steeper/more direct path

	# === Tjørhomfjellet trails ===

	# Green trail - gentle, winding path from summit
	_set_curve(trails_node, "TrailTjorhomGreen1", [
		Vector2(900, 500),    # Summit
		Vector2(1000, 700),
		Vector2(1200, 900),
		Vector2(1100, 1100),
		Vector2(950, 1300),
		Vector2(1050, 1500),
		Vector2(1100, 1700),
		Vector2(1050, 1850),  # Base
	])

	# Blue trail - moderate, less winding
	_set_curve(trails_node, "TrailTjorhomBlue1", [
		Vector2(900, 500),    # Summit
		Vector2(800, 750),
		Vector2(750, 1000),
		Vector2(850, 1300),
		Vector2(950, 1600),
		Vector2(1050, 1850),  # Base
	])

	# Red trail - steep and direct
	_set_curve(trails_node, "TrailTjorhomRed1", [
		Vector2(900, 500),    # Summit
		Vector2(850, 800),
		Vector2(900, 1100),
		Vector2(950, 1500),
		Vector2(1050, 1850),  # Base
	])

	# === Hulderheimen trails (beginner area) ===

	# Green 1 - gentle slope
	_set_curve(trails_node, "TrailHulderGreen1", [
		Vector2(480, 1500),   # Top of button lift
		Vector2(520, 1600),
		Vector2(600, 1700),
		Vector2(580, 1800),
		Vector2(550, 2000),   # Base
	])

	# Green 2 - alternate gentle route
	_set_curve(trails_node, "TrailHulderGreen2", [
		Vector2(480, 1500),   # Top
		Vector2(400, 1600),
		Vector2(350, 1750),
		Vector2(450, 1900),
		Vector2(550, 2000),   # Base
	])

	# === Nyestøl trails ===

	# Green - long gentle traverse
	_set_curve(trails_node, "TrailNyestolGreen1", [
		Vector2(2350, 850),   # Top
		Vector2(2400, 1000),
		Vector2(2500, 1150),
		Vector2(2550, 1350),
		Vector2(2500, 1550),
		Vector2(2500, 1800),  # Base
	])

	# Blue 1 - moderate
	_set_curve(trails_node, "TrailNyestolBlue1", [
		Vector2(2350, 850),   # Top
		Vector2(2300, 1050),
		Vector2(2400, 1300),
		Vector2(2450, 1550),
		Vector2(2500, 1800),  # Base
	])

	# Blue 2 - from higher T-bar
	_set_curve(trails_node, "TrailNyestolBlue2", [
		Vector2(2800, 800),   # Top of T-bar 2
		Vector2(2750, 1000),
		Vector2(2700, 1250),
		Vector2(2800, 1500),
		Vector2(2900, 1750),  # Base
	])

	# Red - steep
	_set_curve(trails_node, "TrailNyestolRed1", [
		Vector2(2800, 800),   # Top
		Vector2(2850, 1100),
		Vector2(2900, 1400),
		Vector2(2900, 1750),  # Base
	])

	# === Ålsheia trails ===

	# Green 1 - gentle
	_set_curve(trails_node, "TrailAlsheiaGreen1", [
		Vector2(4100, 700),   # Top of T-bar 1
		Vector2(4200, 900),
		Vector2(4350, 1100),
		Vector2(4400, 1300),
		Vector2(4350, 1500),
		Vector2(4250, 1700),
		Vector2(4200, 1800),  # Base
	])

	# Green 2 - lower button lift area
	_set_curve(trails_node, "TrailAlsheiaGreen2", [
		Vector2(4600, 1400),  # Top of button lift
		Vector2(4650, 1550),
		Vector2(4700, 1700),
		Vector2(4700, 1900),  # Base
	])

	# Blue 1 - moderate from top
	_set_curve(trails_node, "TrailAlsheiaBlue1", [
		Vector2(4100, 700),   # Top
		Vector2(4050, 950),
		Vector2(4150, 1200),
		Vector2(4200, 1500),
		Vector2(4200, 1800),  # Base
	])

	# Blue 2 - from T-bar 2
	_set_curve(trails_node, "TrailAlsheiaBlue2", [
		Vector2(4400, 900),   # Top of T-bar 2
		Vector2(4450, 1100),
		Vector2(4500, 1350),
		Vector2(4500, 1750),  # Base
	])

	# Red - steep direct
	_set_curve(trails_node, "TrailAlsheiaRed1", [
		Vector2(4100, 700),   # Top
		Vector2(4150, 1000),
		Vector2(4200, 1400),
		Vector2(4200, 1800),  # Base
	])

	# === Connection trails ===

	# Tjørhomfjellet to Nyestøl traverse
	_set_curve(trails_node, "TrailConnectTjorhomNyestol", [
		Vector2(1050, 1000),  # From Tjørhom mid-mountain
		Vector2(1400, 1050),
		Vector2(1800, 1100),
		Vector2(2200, 1200),
		Vector2(2500, 1800),  # Nyestøl base
	])

	# Nyestøl to Ålsheia traverse
	_set_curve(trails_node, "TrailConnectNyestolAlsheia", [
		Vector2(2800, 900),   # From Nyestøl mid-area
		Vector2(3200, 950),
		Vector2(3600, 1000),
		Vector2(4000, 1100),
		Vector2(4200, 1800),  # Ålsheia base
	])


static func _build_walk_paths(walks_node: Node2D) -> void:
	# Short paths from parking to nearest lift base

	_set_curve(walks_node, "WalkHulderheimen", [
		Vector2(650, 2100),   # Parking
		Vector2(580, 2050),
		Vector2(550, 2000),   # Lift base
	])

	_set_curve(walks_node, "WalkTjorhom", [
		Vector2(1200, 2000),  # Parking
		Vector2(1150, 1950),
		Vector2(1050, 1850),  # Lift base
	])

	_set_curve(walks_node, "WalkNyestol", [
		Vector2(2800, 2100),  # Parking
		Vector2(2700, 2000),
		Vector2(2500, 1800),  # Lift base
	])

	_set_curve(walks_node, "WalkAlsheia", [
		Vector2(4400, 1900),  # Parking
		Vector2(4300, 1850),
		Vector2(4200, 1800),  # Lift base
	])


static func _set_curve(parent: Node2D, node_name: String, points: Array[Vector2]) -> void:
	var path := parent.get_node_or_null(node_name) as Path2D
	if path == null:
		path = Path2D.new()
		path.name = node_name
		parent.add_child(path)

	var curve := Curve2D.new()
	for i in range(points.size()):
		var point := points[i]
		# Calculate smooth tangents
		var in_handle := Vector2.ZERO
		var out_handle := Vector2.ZERO
		if i > 0 and i < points.size() - 1:
			var direction := (points[i + 1] - points[i - 1]).normalized()
			var length := minf(
				points[i].distance_to(points[i - 1]),
				points[i].distance_to(points[i + 1])
			) * 0.3
			in_handle = -direction * length
			out_handle = direction * length
		curve.add_point(point, in_handle, out_handle)

	path.curve = curve
