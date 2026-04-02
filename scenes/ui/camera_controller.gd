extends Camera2D

const PAN_SPEED := 800.0
const ZOOM_SPEED := 0.1
const MIN_ZOOM := 0.2
const MAX_ZOOM := 2.0

var _dragging := false
var _drag_start := Vector2.ZERO

@export var map_width := 5551
@export var map_height := 2776


func _ready() -> void:
	limit_left = 0
	limit_top = 0
	limit_right = map_width
	limit_bottom = map_height
	position = Vector2(map_width / 2.0, map_height / 2.0)
	zoom = Vector2(0.4, 0.4)


func _process(delta: float) -> void:
	var pan := Vector2.ZERO
	if Input.is_action_pressed("camera_pan_up"):
		pan.y -= 1
	if Input.is_action_pressed("camera_pan_down"):
		pan.y += 1
	if Input.is_action_pressed("camera_pan_left"):
		pan.x -= 1
	if Input.is_action_pressed("camera_pan_right"):
		pan.x += 1
	if pan != Vector2.ZERO:
		position += pan.normalized() * PAN_SPEED * delta / zoom.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom_at(event.position, ZOOM_SPEED)
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_at(event.position, -ZOOM_SPEED)
			MOUSE_BUTTON_MIDDLE:
				_dragging = event.pressed
				_drag_start = event.position
			MOUSE_BUTTON_LEFT:
				_dragging = event.pressed
				_drag_start = event.position
	elif event is InputEventMouseMotion and _dragging:
		position -= event.relative / zoom.x


func _zoom_at(mouse_pos: Vector2, factor: float) -> void:
	var old_zoom := zoom
	var new_zoom_val := clampf(zoom.x + factor, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(new_zoom_val, new_zoom_val)
	# Adjust position to zoom toward mouse
	var viewport_size := get_viewport_rect().size
	var mouse_offset := mouse_pos - viewport_size / 2.0
	position += mouse_offset * (1.0 / old_zoom.x - 1.0 / zoom.x)
