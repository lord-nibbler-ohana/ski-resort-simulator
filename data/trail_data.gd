class_name TrailDefinition
extends Resource

enum Difficulty { GREEN, BLUE, RED }

@export var id: String
@export var display_name: String
@export var difficulty: Difficulty
@export var path_node_name: String
@export var mountain_area: String  # "tjørhomfjellet", "nyestøl", "ålsheia"
@export var start_elevation: float  # meters, top of trail
@export var end_elevation: float  # meters, bottom of trail
@export var connected_lift_ids: PackedStringArray


func elevation_drop() -> float:
	return start_elevation - end_elevation
