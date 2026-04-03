extends Node2D

## Auto-screenshots of different map zones with extracted mask overlay + PathBuilder paths.

var _trail_map_sprite: Sprite2D
var _paths_container: Node2D
var _extracted_overlay: Node2D
var _trail_colors: Dictionary = {}
var _camera: Camera2D
var _frame := 0

var _zones := [
	["full", 2775, 1388, 0.25],
	["tjorhom", 1150, 1000, 0.55],
	["nyestol", 2550, 1000, 0.55],
	["alsheia", 4300, 1200, 0.45],
	["hulderheimen", 500, 1500, 0.7],
]
var _zone_idx := 0


func _ready() -> void:
	_trail_map_sprite = Sprite2D.new()
	_trail_map_sprite.texture = load("res://assets/images/trail_map.png")
	_trail_map_sprite.centered = false
	add_child(_trail_map_sprite)

	# Extracted mask overlays (z_index 5 — between map and PathBuilder lines)
	_extracted_overlay = Node2D.new()
	_extracted_overlay.z_index = 5
	add_child(_extracted_overlay)
	_load_extracted_masks()

	# PathBuilder paths (z_index 10)
	_paths_container = Node2D.new()
	_paths_container.name = "PathsContainer"
	for cat in ["Lifts", "Trails", "WalkPaths"]:
		var n := Node2D.new()
		n.name = cat
		_paths_container.add_child(n)
	add_child(_paths_container)

	PathBuilder.build_all_paths(_paths_container)
	_build_trail_color_lookup()

	var lifts_node := _paths_container.get_node("Lifts")
	var trails_node := _paths_container.get_node("Trails")
	var walks_node := _paths_container.get_node("WalkPaths")

	for child in lifts_node.get_children():
		if child is Path2D:
			_create_line_from_path(child, Color.DARK_GRAY, 5.0)
	for child in trails_node.get_children():
		if child is Path2D:
			var color: Color
			if child.name in _trail_colors:
				color = _trail_colors[child.name]
			elif child.name.begins_with("TrailConnect"):
				color = Color.ORANGE
			else:
				color = Color.WHITE
			_create_line_from_path(child, color, 6.0)
	for child in walks_node.get_children():
		if child is Path2D:
			_create_line_from_path(child, Color.SADDLE_BROWN, 3.0)

	_camera = Camera2D.new()
	add_child(_camera)
	_camera.make_current()


func _load_extracted_masks() -> void:
	var shader := Shader.new()
	shader.code = "
shader_type canvas_item;
uniform vec3 tint_color : source_color = vec3(1.0, 0.0, 0.0);
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.8;
void fragment() {
	float brightness = texture(TEXTURE, UV).r;
	COLOR = vec4(tint_color, brightness * alpha_strength);
}
"
	var masks: Array[Dictionary] = [
		{"file": "res://debug_mask_red.png", "color": Color(1, 0.15, 0.15)},
		{"file": "res://debug_mask_green.png", "color": Color(0.15, 1, 0.15)},
		{"file": "res://debug_mask_blue.png", "color": Color(0.3, 0.6, 1.0)},
	]
	for info in masks:
		var path: String = info["file"]
		if not FileAccess.file_exists(path):
			continue
		var tex := ImageTexture.create_from_image(Image.load_from_file(path))
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.centered = false
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("tint_color", info["color"])
		mat.set_shader_parameter("alpha_strength", 0.85)
		sprite.material = mat
		_extracted_overlay.add_child(sprite)


func _build_trail_color_lookup() -> void:
	for trail in ResortData.trails:
		match trail.difficulty:
			TrailDefinition.Difficulty.GREEN:
				_trail_colors[trail.path_node_name] = Color.GREEN
			TrailDefinition.Difficulty.BLUE:
				_trail_colors[trail.path_node_name] = Color.DODGER_BLUE
			TrailDefinition.Difficulty.RED:
				_trail_colors[trail.path_node_name] = Color.RED


func _create_line_from_path(path: Path2D, color: Color, width: float) -> void:
	var curve := path.curve
	if curve == null or curve.point_count < 2:
		return
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.z_index = 10
	line.antialiased = true
	var baked_length := curve.get_baked_length()
	for i in range(101):
		line.add_point(curve.sample_baked((float(i) / 100.0) * baked_length))
	path.get_parent().add_child(line)
	_add_label(path.name, curve.get_point_position(0) + Vector2(0, -15), color)
	_add_label(path.name, curve.get_point_position(curve.point_count - 1) + Vector2(0, 15), color)


func _add_label(text: String, pos: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos - Vector2(50, 10)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 11
	add_child(label)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame % 3 != 0:
		return
	if _zone_idx >= _zones.size():
		print("All zone screenshots saved!")
		get_tree().quit()
		return

	var zone: Array = _zones[_zone_idx]
	var zone_name: String = zone[0]
	_camera.position = Vector2(zone[1], zone[2])
	_camera.zoom = Vector2(zone[3], zone[3])

	if _frame > 3:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://debug_%s.png" % zone_name)
		print("Saved: debug_%s.png" % zone_name)
		_zone_idx += 1
