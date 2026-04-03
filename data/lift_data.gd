class_name LiftDefinition
extends Resource

enum LiftType { CHAIRLIFT, TBAR, BUTTON }

@export var id: String
@export var display_name: String
@export var lift_type: LiftType
@export var speed_kmh: float  # 15 for chairlift, 8 for others
@export var path_node_name: String
@export var capacity: int  # Max simultaneous riders
@export var base_elevation: float  # meters above sea level
@export var summit_elevation: float
@export var connected_trail_ids: PackedStringArray
@export var open_time: float = 34200.0       # seconds since midnight (default 09:30)
@export var close_time: float = 55800.0      # last ride time (default 15:30)
@export var capacity_per_hour: int = 600     # passengers per hour


func get_speed_display() -> String:
	return "%d km/h" % int(speed_kmh)
