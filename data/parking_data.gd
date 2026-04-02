class_name ParkingDefinition
extends Resource

@export var id: String
@export var display_name: String
@export var position: Vector2  # Pixel coords on map
@export var nearest_lift_ids: PackedStringArray
@export var walk_path_node_name: String
