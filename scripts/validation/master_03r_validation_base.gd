class_name Master03RValidationBase
extends Node3D

const PROP_SCENE := preload("res://scenes/visual_2d5d/sprite_prop_3d.tscn")
const STRUCTURE_SCENE := preload("res://scenes/visual_2d5d/structure_visual_3d.tscn")
const GRASS_TEXTURE := preload("res://assets/art/green_coast_2d5d_v01/surface_samples/grass.png")
const SOIL_TEXTURE := preload("res://assets/art/green_coast_2d5d_v01/surface_samples/soil_path.png")
const ROCK_TEXTURE := preload("res://assets/art/green_coast_2d5d_v01/surface_samples/rock_cliff.png")
const SAND_TEXTURE := preload("res://assets/art/green_coast_2d5d_v01/surface_samples/sand.png")
const WATER_TEXTURE := preload("res://assets/art/green_coast_2d5d_v01/surface_samples/shallow_water.png")

var validation_camera: Camera3D


func build_validation_world(show_hud: bool) -> void:
	_build_environment()
	_build_foundation()
	_build_visual_layer()
	_build_camera()
	if show_hud:
		_build_hud()


func _build_environment() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "BrightCoastEnvironment"
	var resource := Environment.new()
	resource.background_mode = Environment.BG_COLOR
	resource.background_color = Color("#78bddd")
	resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	resource.ambient_light_color = Color("#e9eef0")
	resource.ambient_light_energy = 0.34
	resource.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = resource
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.name = "WarmSun"
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_color = Color("#fff6df")
	sun.light_energy = 0.62
	sun.shadow_enabled = true
	add_child(sun)


func _build_foundation() -> void:
	var ground_size := Vector3(18, 0.6, 20)
	var left_cliff_size := Vector3(5.1, 1.05, 5.6)
	var left_top_size := Vector3(5.15, 0.08, 5.65)
	var right_cliff_size := Vector3(5.3, 1.20, 4.8)
	var right_top_size := Vector3(5.35, 0.08, 4.85)
	var lower_path_size := Vector3(2.6, 0.07, 6.2)
	var middle_path_size := Vector3(2.8, 0.07, 5.2)
	var upper_path_size := Vector3(2.8, 0.07, 5.2)
	var foundation_size := Vector3(18, 2.25, 2.2)
	var beach_size := Vector3(18, 0.25, 3.0)
	_add_box("Ground", Vector3(0, -0.3, 0), ground_size, Color("#86a95f"), true, GRASS_TEXTURE, _tile_uv_top(ground_size, 2.0))
	_add_box("LeftTerraceCliff", Vector3(-5.8, 0.22, 3.0), left_cliff_size, Color("#c7c0b8"), true, ROCK_TEXTURE, _tile_uv_side(left_cliff_size, 1.5))
	_add_box("LeftTerraceTop", Vector3(-5.8, 0.77, 3.0), left_top_size, Color("#88aa5f"), false, GRASS_TEXTURE, _tile_uv_top(left_top_size, 2.0))
	_add_box("RightTerraceCliff", Vector3(4.9, 0.30, -4.6), right_cliff_size, Color("#c7c0b8"), true, ROCK_TEXTURE, _tile_uv_side(right_cliff_size, 1.5))
	_add_box("RightTerraceTop", Vector3(4.9, 0.94, -4.6), right_top_size, Color("#88aa5f"), false, GRASS_TEXTURE, _tile_uv_top(right_top_size, 2.0))
	_add_box("PathLower", Vector3(0.8, 0.015, -6.8), lower_path_size, Color("#dcc3a2"), false, SOIL_TEXTURE, _tile_uv_top(lower_path_size, 1.4), -7.0)
	_add_box("PathMiddle", Vector3(-0.2, 0.02, -1.8), middle_path_size, Color("#dcc3a2"), false, SOIL_TEXTURE, _tile_uv_top(middle_path_size, 1.4), 13.0)
	_add_box("PathUpper", Vector3(-1.1, 0.025, 3.0), upper_path_size, Color("#dcc3a2"), false, SOIL_TEXTURE, _tile_uv_top(upper_path_size, 1.4), -9.0)
	_add_box("CliffFoundation", Vector3(0, -1.15, -10.6), foundation_size, Color("#c7c0b8"), true, ROCK_TEXTURE, _tile_uv_side(foundation_size, 1.5))
	_add_box("Beach", Vector3(0, -1.42, -13.0), beach_size, Color("#ead6ae"), false, SAND_TEXTURE, _tile_uv_top(beach_size, 1.5))
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(38, 28)
	water_mesh.material = _make_water_material()
	var water := MeshInstance3D.new()
	water.name = "Simple3DWater"
	water.mesh = water_mesh
	water.position = Vector3(0, -1.37, -20)
	add_child(water)
	_build_coastal_steps()


func _build_coastal_steps() -> void:
	for index in range(5):
		var step_position := Vector3(0.9, -0.12 - float(index) * 0.25, -10.0 - float(index) * 0.52)
		var step_size := Vector3(2.55, 0.28, 0.68)
		_add_box("CoastalStep%02d" % index, step_position, step_size, Color("#d2cbc2"), true, ROCK_TEXTURE, _tile_uv_top(step_size, 1.2))


func _build_visual_layer() -> void:
	var cottage := _instance_visual(STRUCTURE_SCENE, "CottageVisual", "res://assets/art/green_coast_2d5d_v01/configs/cottage.tres", Vector3(-5.0, 0.83, 1.5))
	cottage.rotation_degrees.y = 148.0
	_instance_visual(PROP_SCENE, "BroadleafTreeA", "res://assets/art/green_coast_2d5d_v01/configs/broadleaf_tree.tres", Vector3(3.8, 0.02, 1.2))
	var tree_b := _instance_visual(PROP_SCENE, "BroadleafTreeB", "res://assets/art/green_coast_2d5d_v01/configs/broadleaf_tree.tres", Vector3(-6.4, 0.83, 4.9))
	tree_b.scale = Vector3.ONE * 0.72
	var ruin := _instance_visual(STRUCTURE_SCENE, "RuinVisual", "res://assets/art/green_coast_2d5d_v01/configs/ruin_arch.tres", Vector3(4.6, 1.0, -5.0))
	ruin.rotation_degrees.y = 148.0
	_add_proxy(ruin, "RuinLeftProxy", Vector3(-2.15, 1.2, 0), Vector3(1.25, 2.4, 1.0))
	_add_proxy(ruin, "RuinRightProxy", Vector3(2.15, 1.2, 0), Vector3(1.25, 2.4, 1.0))
	for data in [
		[Vector3(-1.9, 0.03, 4.4), 0.72], [Vector3(2.3, 0.03, 3.7), 0.62],
		[Vector3(-2.5, 0.03, -2.0), 0.55], [Vector3(5.6, 0.03, -3.5), 0.50],
		[Vector3(-6.0, 0.03, -7.3), 0.44], [Vector3(6.3, 0.03, 6.1), 0.48],
		[Vector3(-5.8, -1.27, -12.1), 0.58], [Vector3(-2.5, -1.27, -12.7), 0.42],
		[Vector3(4.3, -1.27, -12.4), 0.52], [Vector3(7.0, -1.27, -11.9), 0.38],
	]:
		var dressing := _instance_visual(PROP_SCENE, "RockFlowerCluster", "res://assets/art/green_coast_2d5d_v01/configs/rock_flower_cluster.tres", data[0])
		dressing.scale = Vector3.ONE * data[1]


func _build_camera() -> void:
	validation_camera = Camera3D.new()
	validation_camera.name = "ValidationCamera"
	validation_camera.position = Vector3(10.0, 10.0, -23.0)
	validation_camera.fov = 44.0
	validation_camera.current = true
	add_child(validation_camera)
	validation_camera.look_at(Vector3(0, -0.1, -5.0), Vector3.UP)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ValidationUI"
	add_child(layer)
	var panel := PanelContainer.new()
	panel.name = "InfoPanel"
	panel.position = Vector2(24, 24)
	panel.custom_minimum_size = Vector2(510, 72)
	layer.add_child(panel)
	var label := Label.new()
	label.name = "KoreanTextValidation"
	label.text = "2.5D 검증 구간  ·  우클릭 이동\n시각 스프라이트 / 3D 충돌 프록시 분리"
	label.add_theme_font_size_override("font_size", 18)
	panel.add_child(label)


func _make_water_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded;
uniform sampler2D water_texture : source_color, repeat_enable, filter_linear_mipmap;
void vertex() {
	VERTEX.y += sin((VERTEX.x + VERTEX.z) * 0.32 + TIME * 0.8) * 0.025;
}
void fragment() {
	vec2 flow_uv = UV * vec2(7.0, 5.0) + vec2(TIME * 0.012, TIME * -0.007);
	vec3 sampled = texture(water_texture, flow_uv).rgb;
	ALBEDO = sampled * vec3(0.82, 0.96, 1.0);
	ROUGHNESS = 0.24;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("water_texture", WATER_TEXTURE)
	return material


func _instance_visual(scene: PackedScene, node_name: String, config_path: String, position: Vector3) -> Node3D:
	var instance := scene.instantiate() as Node3D
	instance.name = node_name
	instance.position = position
	instance.set("asset_config", load(config_path))
	add_child(instance)
	instance.call("apply_config")
	return instance


func _add_proxy(parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> void:
	var proxy := CollisionProxy3D.new()
	proxy.name = node_name
	proxy.position = position
	proxy.collision_type = AssetConfig2D5D.CollisionType.BOX
	proxy.collision_size = size
	parent.add_child(proxy)
	proxy.rebuild()


func _tile_uv_top(size: Vector3, tile_world_size: float) -> Vector3:
	return Vector3(maxf(size.x / tile_world_size, 1.0), maxf(size.z / tile_world_size, 1.0), 1.0)


func _tile_uv_side(size: Vector3, tile_world_size: float) -> Vector3:
	return Vector3(maxf(size.x / tile_world_size, 1.0), maxf(size.y / tile_world_size, 1.0), 1.0)


func _add_box(node_name: String, position: Vector3, size: Vector3, color: Color, collision: bool, texture: Texture2D = null, uv_scale := Vector3.ONE, yaw_degrees := 0.0) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name + "Visual"
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.96
	if texture != null:
		material.albedo_texture = texture
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		material.texture_repeat = true
		material.uv1_scale = uv_scale
	mesh.material = material
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.rotation_degrees.y = yaw_degrees
	add_child(mesh_instance)
	if collision:
		var body := StaticBody3D.new()
		body.name = node_name + "Collision"
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.position = position
		body.rotation_degrees.y = yaw_degrees
		body.add_child(shape)
		add_child(body)
