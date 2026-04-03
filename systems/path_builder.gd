extends Node
class_name PathBuilder

## Builds all Path2D curves from pixel coordinate data.
## Coordinates extracted from the Sirdal Fjellpark trail map (5551x2776px)
## using OpenCV color thresholding + guided BFS pathfinding (tools/guided_extract.py).
## Blue trails and lifts use approximate coordinates pending manual refinement.

const MAP_WIDTH := 5551
const MAP_HEIGHT := 2776


static func build_all_paths(paths_container: Node2D) -> void:
	_build_lift_paths(paths_container.get_node("Lifts"))
	_build_trail_paths(paths_container.get_node("Trails"))
	_build_walk_paths(paths_container.get_node("WalkPaths"))


static func _build_lift_paths(lifts_node: Node2D) -> void:
	# All lifts traced from the trail map. Direction: base → summit.
	# Numbers match official Sirdal Fjellpark lift numbering.

	# Lift 1: Hølen — single lift, Ålsheia
	_set_curve(lifts_node, "LiftAlsheiaHolen", [
		Vector2(4918, 2099),  # Base
		Vector2(5006, 2001),
		Vector2(5120, 1887),
		Vector2(5221, 1793),  # Top
	])

	# Lift 2: T-bar, Ålsheia
	_set_curve(lifts_node, "LiftAlsheiaTbar", [
		Vector2(5265, 1665),  # Base
		Vector2(5137, 1587),
		Vector2(4996, 1493),
		Vector2(4865, 1409),
		Vector2(4723, 1318),
		Vector2(4585, 1238),
		Vector2(4434, 1177),
		Vector2(4292, 1117),  # Top
	])

	# Lift 3: Single lift, Ålsheia
	_set_curve(lifts_node, "LiftAlsheiaSingle", [
		Vector2(5272, 1658),  # Base
		Vector2(5144, 1577),
		Vector2(5009, 1483),
		Vector2(4875, 1396),
		Vector2(4737, 1308),
		Vector2(4592, 1228),
		Vector2(4441, 1164),
		Vector2(4292, 1117),  # Top (shared with Lift 2)
	])

	# Lift 4: Barnetrekk — children's conveyor belt, Ålsheia (trail runs beside lift)
	_set_curve(lifts_node, "LiftAlsheiaBarnetrekk", [
		Vector2(5278, 1631),  # Base
		Vector2(5174, 1564),  # Top
	])

	# Lift 5: Slettekvævheisen — T-bar, Nyestøl (reversed from trace: summit→base)
	_set_curve(lifts_node, "LiftNyestolSlettekvaev", [
		Vector2(2933, 1503),  # Base
		Vector2(2973, 1453),
		Vector2(3057, 1362),
		Vector2(3098, 1305),
		Vector2(3162, 1234),
		Vector2(3212, 1170),
		Vector2(3273, 1110),
		Vector2(3306, 1066),  # Top
	])

	# Lift 6: Dåfjellheisen — Nyestøl
	_set_curve(lifts_node, "LiftNyestolDaafjell", [
		Vector2(3310, 1019),  # Base
		Vector2(3205, 969),
		Vector2(3135, 935),
		Vector2(3054, 901),
		Vector2(2906, 837),
		Vector2(2829, 810),
		Vector2(2758, 780),   # Top
	])

	# Lift 7: Koblingsheisen — connects Tjørhomfjellet with Nyestøl and back to chairlift
	_set_curve(lifts_node, "LiftKoblings", [
		Vector2(2156, 1130),  # Base
		Vector2(2196, 1180),
		Vector2(2223, 1217),
		Vector2(2243, 1241),  # Top
	])

	# Lift 8: Tjørhomfjellet Stolheis — 4-seat chairlift
	_set_curve(lifts_node, "LiftTjorhomChair", [
		Vector2(1913, 1806),  # Base
		Vector2(1873, 1759),
		Vector2(1765, 1638),
		Vector2(1728, 1591),
		Vector2(1637, 1537),
		Vector2(1496, 1453),
		Vector2(1355, 1369),
		Vector2(1217, 1281),
		Vector2(1075, 1191),
		Vector2(924, 1100),
		Vector2(796, 1029),
		Vector2(624, 925),
		Vector2(517, 858),
		Vector2(433, 807),    # Summit ~928m
	])

	# Lift 9: Hulderheimen
	_set_curve(lifts_node, "LiftHulderheimen", [
		Vector2(1503, 2169),  # Base
		Vector2(1496, 2068),
		Vector2(1489, 1961),
		Vector2(1479, 1904),
		Vector2(1479, 1833),  # Top
	])

	# Lift 10: Hulderheimen rope lift — children's area (trail runs beside lift)
	_set_curve(lifts_node, "LiftHulderRope", [
		Vector2(1476, 2166),  # Base
		Vector2(1442, 2068),  # Top
	])


static func _build_trail_paths(trails_node: Node2D) -> void:
	# === Tjørhomfjellet trails — extracted from green/red masks ===

	# Green trail — 19pts, extracted via guided BFS through green mask
	_set_curve(trails_node, "TrailTjorhomGreen1", [
		Vector2(598, 944),
		Vector2(680, 982),
		Vector2(858, 995),
		Vector2(891, 1032),
		Vector2(928, 1010),
		Vector2(1170, 1042),
		Vector2(1254, 1078),
		Vector2(1390, 1249),
		Vector2(1419, 1513),
		Vector2(1353, 1582),
		Vector2(1393, 1633),
		Vector2(1396, 1681),
		Vector2(1344, 1759),
		Vector2(1403, 1807),
		Vector2(1523, 1825),
		Vector2(1530, 1913),
		Vector2(1608, 2065),
		Vector2(1604, 2176),
		Vector2(1557, 2213),
	])

	# Blue trail — approximate, pending manual refinement via tracing tool
	_set_curve(trails_node, "TrailTjorhomBlue1", [
		Vector2(1100, 890),
		Vector2(1050, 1000),
		Vector2(1000, 1100),
		Vector2(1050, 1200),
		Vector2(1150, 1300),
		Vector2(1200, 1500),
		Vector2(1250, 1700),
		Vector2(1246, 1946),
	])

	# Red trail — 7pts, extracted
	_set_curve(trails_node, "TrailTjorhomRed1", [
		Vector2(623, 967),
		Vector2(816, 1170),
		Vector2(1408, 1520),
		Vector2(1424, 1660),
		Vector2(1451, 1692),
		Vector2(1440, 1723),
		Vector2(1481, 1800),
	])

	# === Hulderheimen trails — extracted from green mask ===

	_set_curve(trails_node, "TrailHulderGreen1", [
		Vector2(573, 889),
		Vector2(634, 970),
		Vector2(730, 987),
	])

	# Second green route (small beginner area)
	_set_curve(trails_node, "TrailHulderGreen2", [
		Vector2(573, 889),
		Vector2(500, 950),
		Vector2(480, 1020),
		Vector2(520, 1100),
		Vector2(606, 2020),
	])

	# === Nyestøl trails ===

	# Green — 12pts, extracted
	_set_curve(trails_node, "TrailNyestolGreen1", [
		Vector2(2785, 789),
		Vector2(2756, 811),
		Vector2(2797, 908),
		Vector2(2905, 962),
		Vector2(2955, 951),
		Vector2(3076, 1062),
		Vector2(2659, 1215),
		Vector2(2487, 1358),
		Vector2(2440, 1453),
		Vector2(2335, 1550),
		Vector2(2162, 1612),
		Vector2(1864, 1859),
	])

	# Blue 1 — 3pts, extracted
	_set_curve(trails_node, "TrailNyestolBlue1", [
		Vector2(2287, 978),
		Vector2(2156, 1120),
		Vector2(2088, 1129),
	])

	# Blue 2 — approximate, pending refinement
	_set_curve(trails_node, "TrailNyestolBlue2", [
		Vector2(2591, 627),
		Vector2(2650, 800),
		Vector2(2700, 1000),
		Vector2(2750, 1200),
		Vector2(2800, 1400),
		Vector2(3006, 1494),
	])

	# Red — 3pts, extracted
	_set_curve(trails_node, "TrailNyestolRed1", [
		Vector2(3299, 1427),
		Vector2(3221, 1494),
		Vector2(3139, 1504),
	])

	# === Ålsheia trails ===

	# Green 1 — 3pts, extracted
	_set_curve(trails_node, "TrailAlsheiaGreen1", [
		Vector2(3355, 996),
		Vector2(3291, 1035),
		Vector2(3171, 1058),
	])

	# Green 2 — button lift area, approximate
	_set_curve(trails_node, "TrailAlsheiaGreen2", [
		Vector2(4675, 1222),
		Vector2(4660, 1400),
		Vector2(4640, 1600),
		Vector2(4619, 1828),
	])

	# Blue 1 — approximate, pending refinement
	_set_curve(trails_node, "TrailAlsheiaBlue1", [
		Vector2(4068, 624),
		Vector2(4100, 800),
		Vector2(4150, 1000),
		Vector2(4120, 1200),
		Vector2(4050, 1400),
		Vector2(3980, 1600),
		Vector2(3937, 1816),
	])

	# Blue 2 — approximate, pending refinement
	_set_curve(trails_node, "TrailAlsheiaBlue2", [
		Vector2(4323, 484),
		Vector2(4350, 700),
		Vector2(4380, 1000),
		Vector2(4350, 1300),
		Vector2(4300, 1550),
		Vector2(4277, 1734),
	])

	# Red — 7pts, extracted
	_set_curve(trails_node, "TrailAlsheiaRed1", [
		Vector2(3386, 1404),
		Vector2(3494, 1445),
		Vector2(3753, 1720),
		Vector2(4188, 1945),
		Vector2(4344, 2062),
		Vector2(4371, 2051),
		Vector2(4670, 2136),
	])

	# === Children's area trails (beside lifts) ===

	# Barnetrekk trail — beside Lift 4 (Ålsheia conveyor belt)
	_set_curve(trails_node, "TrailAlsheiaBarnetrekk", [
		Vector2(5204, 1564),  # Top (offset from lift top)
		Vector2(5308, 1631),  # Base (offset from lift base)
	])

	# Rope lift trail — beside Lift 10 (Hulderheimen)
	_set_curve(trails_node, "TrailHulderRope", [
		Vector2(1412, 2068),  # Top (offset from lift top)
		Vector2(1446, 2166),  # Base (offset from lift base)
	])

	# === Connection trails ===

	# Tjørhom to Nyestøl — approximate (blue mask disconnected)
	_set_curve(trails_node, "TrailConnectTjorhomNyestol", [
		Vector2(1300, 380),
		Vector2(1500, 600),
		Vector2(1800, 800),
		Vector2(2100, 1000),
		Vector2(2400, 1750),
	])

	# Nyestøl to Ålsheia — 16pts, extracted
	_set_curve(trails_node, "TrailConnectNyestolAlsheia", [
		Vector2(2785, 789),
		Vector2(2768, 861),
		Vector2(2793, 905),
		Vector2(2911, 963),
		Vector2(2955, 951),
		Vector2(3005, 1010),
		Vector2(3083, 1051),
		Vector2(2805, 1148),
		Vector2(2771, 1185),
		Vector2(2722, 1179),
		Vector2(2532, 1316),
		Vector2(2738, 1346),
		Vector2(2779, 1391),
		Vector2(2809, 1384),
		Vector2(2908, 1456),
		Vector2(3024, 1498),
	])

	# Ålsheia to Nyestøl — approximate
	_set_curve(trails_node, "TrailConnectAlsheiaNyestol", [
		Vector2(4068, 624),
		Vector2(3600, 700),
		Vector2(3200, 800),
		Vector2(2800, 1000),
		Vector2(2400, 1750),
	])


static func _build_walk_paths(walks_node: Node2D) -> void:
	_set_curve(walks_node, "WalkHulderheimen", [
		Vector2(500, 2050),
		Vector2(460, 1950),
		Vector2(420, 1850),
	])

	_set_curve(walks_node, "WalkTjorhom", [
		Vector2(1100, 1950),
		Vector2(1050, 1880),
		Vector2(1000, 1800),
	])

	_set_curve(walks_node, "WalkAlsheia", [
		Vector2(4100, 1880),
		Vector2(4050, 1820),
		Vector2(4000, 1750),
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
