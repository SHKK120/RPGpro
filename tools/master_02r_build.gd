extends SceneTree

const ASSET_ROOT := "res://assets/art/green_coast_prod_v01"
const SCENE_ROOT := "res://scenes/art/green_coast_prod_v01"
const REFERENCE_ROOT := "res://scenes/reference"

var _materials: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_build_materials()
	_build_terrain_assets()
	_build_nature_assets()
	_build_village_assets()
	_build_reference_scenes()
	print("MASTER02R_BUILD_OK materials=%d terrain=5 nature=6 village_ruin=7 reference_views=2" % _materials.size())
	quit(0)


func _build_materials() -> void:
	_make_material("grass", Color("#58763b"), 0.96)
	_make_material("grass_foliage_dark", Color("#294b38"), 0.98)
	_make_material("grass_foliage_light", Color("#55783f"), 0.97)
	_make_material("soil_path", Color("#90684e"), 0.98)
	_make_material("rock_cliff", Color("#777572"), 0.96)
	_make_material("rock_sunlit", Color("#958e80"), 0.96)
	_make_material("sand", Color("#ae9065"), 0.98)
	_make_water_material()
	_make_material("wood", Color("#8c542f"), 0.94)
	_make_material("wood_dark", Color("#563828"), 0.96)
	_make_material("stone", Color("#817b70"), 0.98)
	_make_material("fabric_blue", Color("#356ea5"), 0.92)
	_make_material("metal", Color("#68727b"), 0.48, 0.22)
	_make_material("accent_warm", Color("#b95f38"), 0.94)


func _make_material(file_name: String, color: Color, roughness: float, metallic := 0.0) -> void:
	var material := StandardMaterial3D.new()
	material.resource_name = "prod_" + file_name
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	var path := ASSET_ROOT.path_join("materials").path_join(file_name + ".tres")
	if ResourceSaver.save(material, path) != OK:
		_fail("Could not save MASTER-02R material: " + path)
	_materials[file_name] = load(path) as Material


func _make_water_material() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley;

void vertex() {
	VERTEX.y += sin((VERTEX.x + VERTEX.z) * 0.42 + TIME * 0.65) * 0.025;
}

void fragment() {
	ALBEDO = vec3(0.145, 0.425, 0.535);
	ROUGHNESS = 0.42;
}
"""
	var material := ShaderMaterial.new()
	material.resource_name = "prod_shallow_water"
	material.shader = shader
	var path := ASSET_ROOT.path_join("materials/shallow_water.tres")
	if ResourceSaver.save(material, path) != OK:
		_fail("Could not save MASTER-02R water material: " + path)
	_materials["shallow_water"] = load(path) as Material


func _build_terrain_assets() -> void:
	_save_scene("terrain/playable_ground", _make_playable_ground())
	_save_scene("terrain/soil_path", _make_soil_path())
	_save_scene("terrain/cliff_straight", _make_cliff_straight())
	_save_scene("terrain/cliff_corner", _make_cliff_corner())
	_save_scene("terrain/ramp_transition", _make_ramp_transition())


func _build_nature_assets() -> void:
	_save_scene("nature/tree_base_a", _make_tree_a())
	_save_scene("nature/tree_base_b", _make_tree_b())
	_save_scene("nature/bush", _make_bush())
	_save_scene("nature/grass_cluster", _make_grass_cluster())
	_save_scene("nature/rock_small", _make_rock_small())
	_save_scene("nature/rock_medium", _make_rock_medium())


func _build_village_assets() -> void:
	_save_scene("village_ruin/fence_straight", _make_fence_straight())
	_save_scene("village_ruin/fence_corner", _make_fence_corner())
	_save_scene("village_ruin/ruin_wall", _make_ruin_wall())
	_save_scene("village_ruin/ruin_arch", _make_ruin_arch())
	_save_scene("village_ruin/building_wall", _make_building_wall())
	_save_scene("village_ruin/door_wall", _make_door_wall())
	_save_scene("village_ruin/roof_piece", _make_roof_piece())


func _new_root(node_name: String) -> Node3D:
	var scene_root := Node3D.new()
	scene_root.name = node_name
	root.add_child(scene_root)
	return scene_root


func _save_scene(relative_path: String, scene_root: Node3D) -> void:
	var packed := PackedScene.new()
	if packed.pack(scene_root) != OK:
		_fail("Could not pack MASTER-02R scene: " + relative_path)
	var path := SCENE_ROOT.path_join(relative_path + ".tscn")
	if ResourceSaver.save(packed, path) != OK:
		_fail("Could not save MASTER-02R scene: " + path)
	root.remove_child(scene_root)
	scene_root.free()


func _add_box(scene_root: Node3D, node_name: String, position: Vector3, size: Vector3, material_name: String, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _materials[material_name]
	return _add_mesh(scene_root, node_name, mesh, position, rotation)


func _add_prism(scene_root: Node3D, node_name: String, position: Vector3, size: Vector3, material_name: String, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := PrismMesh.new()
	mesh.size = size
	mesh.material = _materials[material_name]
	return _add_mesh(scene_root, node_name, mesh, position, rotation)


func _add_taper(scene_root: Node3D, node_name: String, position: Vector3, top_radius: float, bottom_radius: float, height: float, material_name: String, rotation := Vector3.ZERO, segments := 7) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	mesh.material = _materials[material_name]
	return _add_mesh(scene_root, node_name, mesh, position, rotation)


func _add_mesh(scene_root: Node3D, node_name: String, mesh: Mesh, position := Vector3.ZERO, rotation := Vector3.ZERO, scale := Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.rotation_degrees = rotation
	instance.scale = scale
	scene_root.add_child(instance)
	instance.owner = scene_root
	return instance


func _surface_mesh(vertices: PackedVector3Array, triangles: PackedInt32Array, material_name: String) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in triangles:
		surface.set_smooth_group(-1)
		surface.add_vertex(vertices[index])
	surface.generate_normals()
	var mesh := surface.commit()
	mesh.surface_set_material(0, _materials[material_name])
	return mesh


func _extruded_polygon_mesh(points: PackedVector2Array, height: float, material_name: String) -> ArrayMesh:
	var vertices := PackedVector3Array()
	for point in points:
		vertices.append(Vector3(point.x, height, point.y))
	for point in points:
		vertices.append(Vector3(point.x, 0.0, point.y))
	var triangles := PackedInt32Array()
	for index in range(1, points.size() - 1):
		triangles.append_array([0, index, index + 1])
		triangles.append_array([points.size(), points.size() + index + 1, points.size() + index])
	for index in range(points.size()):
		var next := (index + 1) % points.size()
		triangles.append_array([index, points.size() + index, points.size() + next])
		triangles.append_array([index, points.size() + next, next])
	return _surface_mesh(vertices, triangles, material_name)


func _blob_mesh(size: Vector3, sides: int, phase: float, material_name: String) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var levels := [-0.5, -0.12, 0.28]
	var level_scale := [0.55, 1.0, 0.72]
	for level_index in range(levels.size()):
		for side in range(sides):
			var angle := TAU * float(side) / float(sides) + phase + 0.18 * float(level_index)
			var variation := 1.0 + 0.12 * sin(float(side) * 2.3 + phase * 7.0 + float(level_index))
			vertices.append(Vector3(cos(angle) * size.x * level_scale[level_index] * variation, levels[level_index] * size.y, sin(angle) * size.z * level_scale[level_index] * variation))
	var bottom_index := vertices.size()
	vertices.append(Vector3(0, -0.5 * size.y, 0))
	var top_index := vertices.size()
	vertices.append(Vector3(size.x * 0.08 * sin(phase * 3.0), 0.5 * size.y, size.z * 0.07 * cos(phase * 5.0)))
	var triangles := PackedInt32Array()
	for side in range(sides):
		var next := (side + 1) % sides
		triangles.append_array([bottom_index, next, side])
		for level_index in range(levels.size() - 1):
			var a := level_index * sides + side
			var b := level_index * sides + next
			var c := (level_index + 1) * sides + side
			var d := (level_index + 1) * sides + next
			triangles.append_array([a, b, d, a, d, c])
		triangles.append_array([(levels.size() - 1) * sides + side, (levels.size() - 1) * sides + next, top_index])
	return _surface_mesh(vertices, triangles, material_name)


func _boulder_mesh(size: Vector3, phase: float, material_name: String) -> ArrayMesh:
	var sides := 7
	var vertices := PackedVector3Array()
	for ring in range(2):
		for side in range(sides):
			var angle := TAU * float(side) / float(sides) + phase + float(ring) * 0.09
			var variation := 1.0 + 0.16 * sin(float(side) * 3.1 + phase * 11.0)
			var radius_scale := 1.0 if ring == 0 else 0.72
			var y := 0.0 if ring == 0 else size.y * (0.58 + 0.09 * sin(float(side) + phase))
			vertices.append(Vector3(cos(angle) * size.x * radius_scale * variation, y, sin(angle) * size.z * radius_scale * variation))
	var top_index := vertices.size()
	vertices.append(Vector3(size.x * 0.16 * cos(phase * 4.0), size.y, size.z * 0.12 * sin(phase * 3.0)))
	var bottom_index := vertices.size()
	vertices.append(Vector3.ZERO)
	var triangles := PackedInt32Array()
	for side in range(sides):
		var next := (side + 1) % sides
		triangles.append_array([bottom_index, next, side])
		triangles.append_array([side, next, sides + next, side, sides + next, sides + side])
		triangles.append_array([sides + side, sides + next, top_index])
	return _surface_mesh(vertices, triangles, material_name)


func _irregular_block_mesh(size: Vector3, skew: Vector3, material_name: String) -> ArrayMesh:
	var half := size * 0.5
	var vertices := PackedVector3Array([
		Vector3(-half.x, -half.y, -half.z), Vector3(half.x, -half.y, -half.z), Vector3(half.x, -half.y, half.z), Vector3(-half.x, -half.y, half.z),
		Vector3(-half.x + skew.x, half.y, -half.z + skew.z), Vector3(half.x + skew.x * 0.4, half.y + skew.y, -half.z),
		Vector3(half.x - skew.x * 0.3, half.y, half.z + skew.z * 0.4), Vector3(-half.x + skew.x * 0.2, half.y - skew.y * 0.5, half.z - skew.z * 0.3),
	])
	var triangles := PackedInt32Array([
		0,2,1, 0,3,2, 4,5,6, 4,6,7,
		0,1,5, 0,5,4, 1,2,6, 1,6,5,
		2,3,7, 2,7,6, 3,0,4, 3,4,7,
	])
	return _surface_mesh(vertices, triangles, material_name)


func _path_mesh(material_name: String) -> ArrayMesh:
	var centers := [-0.16, 0.12, -0.08, 0.18, -0.12, 0.08]
	var widths := [0.92, 1.03, 0.96, 1.08, 0.98, 0.9]
	var vertices := PackedVector3Array()
	for index in range(centers.size()):
		var z := -2.0 + 0.8 * float(index)
		vertices.append(Vector3(centers[index] - widths[index], 0.025, z))
		vertices.append(Vector3(centers[index] + widths[index], 0.025, z))
	var triangles := PackedInt32Array()
	for index in range(centers.size() - 1):
		var a := index * 2
		triangles.append_array([a, a + 1, a + 3, a, a + 3, a + 2])
	return _surface_mesh(vertices, triangles, material_name)


func _cliff_face_mesh(width: float, height: float, material_name: String, phase := 0.0) -> ArrayMesh:
	var columns := 6
	var vertices := PackedVector3Array()
	for row in range(3):
		for column in range(columns):
			var x := -width * 0.5 + width * float(column) / float(columns - 1)
			var y := -height * float(row) / 2.0
			var z := 0.12 * sin(float(column) * 2.1 + float(row) * 1.7 + phase)
			if row == 1:
				x += 0.14 * sin(float(column) * 1.6 + phase)
				z -= 0.22
			vertices.append(Vector3(x, y, z))
	var triangles := PackedInt32Array()
	for row in range(2):
		for column in range(columns - 1):
			var a := row * columns + column
			var b := a + 1
			var c := (row + 1) * columns + column
			var d := c + 1
			if (row + column) % 2 == 0:
				triangles.append_array([a, c, b, b, c, d])
			else:
				triangles.append_array([a, c, d, a, d, b])
	return _surface_mesh(vertices, triangles, material_name)


func _add_box_collision(scene_root: Node3D, node_name: String, position: Vector3, size: Vector3, rotation := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.rotation_degrees = rotation
	var shape_node := CollisionShape3D.new()
	shape_node.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)
	scene_root.add_child(body)
	body.owner = scene_root
	shape_node.owner = scene_root
	return body


func _make_playable_ground() -> Node3D:
	var scene_root := _new_root("PlayableGround4m")
	_add_box(scene_root, "EarthFoundation", Vector3(0, -0.25, 0), Vector3(4, 0.44, 4), "rock_sunlit")
	var cap_points := PackedVector2Array([Vector2(-2, -2), Vector2(2, -2), Vector2(2, 2), Vector2(-2, 2)])
	_add_mesh(scene_root, "WarmGrassCap", _extruded_polygon_mesh(cap_points, 0.18, "grass"), Vector3(0, -0.15, 0))
	_add_box_collision(scene_root, "WalkableCollision", Vector3(0, -0.16, 0), Vector3(4, 0.32, 4))
	return scene_root


func _make_soil_path() -> Node3D:
	var scene_root := _new_root("SoilPath4m")
	_add_mesh(scene_root, "IrregularSoilRibbon", _path_mesh("soil_path"))
	for data in [[Vector3(-0.62, 0.04, -1.15), Vector3(0.14, 0.08, 0.18)], [Vector3(0.55, 0.04, 0.4), Vector3(0.18, 0.07, 0.12)], [Vector3(-0.32, 0.04, 1.35), Vector3(0.12, 0.06, 0.16)]]:
		_add_mesh(scene_root, "EmbeddedStone", _boulder_mesh(data[1], 0.3 + data[0].z, "stone"), data[0])
	return scene_root


func _make_cliff_straight() -> Node3D:
	var scene_root := _new_root("CliffStraight4m")
	_add_box(scene_root, "GrassCap", Vector3(0, -0.09, 0.72), Vector3(4, 0.18, 2.56), "grass")
	_add_mesh(scene_root, "LargeRockPlanes", _cliff_face_mesh(4.0, 2.75, "rock_cliff", 0.4), Vector3(0, -0.02, -0.64))
	_add_mesh(scene_root, "SunlitFace", _cliff_face_mesh(1.55, 2.42, "rock_sunlit", 1.8), Vector3(-0.78, -0.12, -0.71), Vector3(0, -3, 0))
	_add_boulder(scene_root, "EdgeRockLeft", Vector3(-1.62, -0.08, -0.42), Vector3(0.5, 0.5, 0.42), 0.4, "rock_sunlit")
	_add_box_collision(scene_root, "WalkableCollision", Vector3(0, -0.18, 0.72), Vector3(4, 0.36, 2.56))
	_add_box_collision(scene_root, "EdgeSafetyCollision", Vector3(0, -0.55, -0.48), Vector3(4, 1.1, 0.38))
	return scene_root


func _make_cliff_corner() -> Node3D:
	var scene_root := _new_root("CliffOuterCorner4m")
	var cap_points := PackedVector2Array([Vector2(-1, -1), Vector2(2, -1), Vector2(2, 2), Vector2(-1, 2)])
	_add_mesh(scene_root, "GrassCap", _extruded_polygon_mesh(cap_points, 0.18, "grass"), Vector3(0, -0.18, 0))
	_add_mesh(scene_root, "SouthRockPlanes", _cliff_face_mesh(3.0, 2.75, "rock_cliff", 1.1), Vector3(0.5, 0, -1.0))
	_add_mesh(scene_root, "WestRockPlanes", _cliff_face_mesh(3.0, 2.75, "rock_sunlit", 2.2), Vector3(-1.0, 0, 0.5), Vector3(0, 90, 0))
	_add_boulder(scene_root, "CornerShoulder", Vector3(-0.72, -0.02, -0.72), Vector3(0.58, 0.6, 0.55), 0.7, "rock_sunlit")
	_add_box_collision(scene_root, "WalkableCollision", Vector3(0.5, -0.18, 0.5), Vector3(3, 0.36, 3))
	return scene_root


func _make_ramp_transition() -> Node3D:
	var scene_root := _new_root("RampTransition4m")
	_add_prism(scene_root, "RockRampMass", Vector3(0, -1.05, 0), Vector3(4, 2.1, 4), "rock_cliff", Vector3(0, 90, 0))
	_add_box(scene_root, "MutedSoilSurface", Vector3(0, -0.99, 0), Vector3(2.55, 0.13, 4.08), "soil_path", Vector3(-26.565, 0, 0))
	for side in [-1.55, 1.55]:
		_add_boulder(scene_root, "RampShoulder", Vector3(side, -0.7, -0.4), Vector3(0.55, 0.72, 0.5), 0.4 + side, "rock_sunlit")
	_add_box_collision(scene_root, "RampCollision", Vector3(0, -0.99, 0), Vector3(2.55, 0.2, 4.08), Vector3(-26.565, 0, 0))
	return scene_root


func _add_blob(scene_root: Node3D, node_name: String, position: Vector3, size: Vector3, material_name: String, phase: float) -> MeshInstance3D:
	return _add_mesh(scene_root, node_name, _blob_mesh(size, 7, phase, material_name), position)


func _add_boulder(scene_root: Node3D, node_name: String, position: Vector3, size: Vector3, phase: float, material_name: String) -> MeshInstance3D:
	return _add_mesh(scene_root, node_name, _boulder_mesh(size, phase, material_name), position)


func _make_tree_a() -> Node3D:
	var scene_root := _new_root("TreeBaseA")
	_add_taper(scene_root, "TaperedTrunk", Vector3(0, 1.5, 0), 0.3, 0.55, 3.0, "wood_dark", Vector3(0, 0, -6))
	_add_taper(scene_root, "BranchWest", Vector3(-0.52, 2.45, 0.02), 0.12, 0.25, 1.45, "wood_dark", Vector3(0, 0, 52))
	_add_taper(scene_root, "BranchEast", Vector3(0.58, 2.55, -0.12), 0.11, 0.23, 1.3, "wood_dark", Vector3(-5, 0, -55))
	_add_blob(scene_root, "CanopyCore", Vector3(-0.05, 3.62, 0), Vector3(1.25, 1.55, 1.08), "grass_foliage_dark", 0.2)
	_add_blob(scene_root, "CanopyWest", Vector3(-0.9, 3.55, 0.12), Vector3(0.92, 1.1, 0.84), "grass_foliage_light", 1.1)
	_add_blob(scene_root, "CanopyEast", Vector3(0.88, 3.48, -0.1), Vector3(1.0, 1.18, 0.9), "grass_foliage_light", 2.0)
	_add_blob(scene_root, "CanopyCrown", Vector3(0.1, 4.35, -0.06), Vector3(0.8, 0.95, 0.76), "grass_foliage_light", 2.8)
	_add_box_collision(scene_root, "TrunkCollision", Vector3(0, 1.35, 0), Vector3(0.9, 2.7, 0.9), Vector3(0, 0, -6))
	return scene_root


func _make_tree_b() -> Node3D:
	var scene_root := _new_root("TreeBaseB")
	_add_taper(scene_root, "BentLowerTrunk", Vector3(-0.18, 1.12, 0), 0.31, 0.52, 2.25, "wood", Vector3(0, 0, 15))
	_add_taper(scene_root, "RisingTrunk", Vector3(0.3, 2.2, 0), 0.2, 0.34, 1.55, "wood", Vector3(0, 0, -23))
	_add_taper(scene_root, "LongCoastalBranch", Vector3(0.95, 2.62, 0.02), 0.11, 0.23, 1.75, "wood", Vector3(0, 0, -67))
	_add_blob(scene_root, "CanopyAnchor", Vector3(0.34, 3.28, 0), Vector3(1.05, 1.18, 0.94), "grass_foliage_dark", 0.6)
	_add_blob(scene_root, "CanopyReach", Vector3(1.35, 3.1, 0.05), Vector3(1.24, 1.08, 0.9), "grass_foliage_light", 1.8)
	_add_blob(scene_root, "CanopyTip", Vector3(2.15, 3.28, -0.06), Vector3(0.75, 0.86, 0.7), "grass_foliage_light", 2.5)
	_add_box_collision(scene_root, "TrunkCollision", Vector3(0, 1.25, 0), Vector3(0.92, 2.5, 0.9), Vector3(0, 0, 12))
	return scene_root


func _make_bush() -> Node3D:
	var scene_root := _new_root("BushBase")
	_add_blob(scene_root, "LeafMassWest", Vector3(-0.42, 0.48, 0.04), Vector3(0.62, 0.8, 0.58), "grass_foliage_dark", 0.2)
	_add_blob(scene_root, "LeafMassCore", Vector3(0.1, 0.62, -0.1), Vector3(0.72, 0.94, 0.68), "grass_foliage_light", 1.1)
	_add_blob(scene_root, "LeafMassEast", Vector3(0.58, 0.42, 0.18), Vector3(0.5, 0.68, 0.52), "grass_foliage_dark", 2.0)
	_add_blob(scene_root, "LeafMassBack", Vector3(0.08, 0.42, 0.4), Vector3(0.48, 0.64, 0.5), "grass_foliage_light", 2.7)
	return scene_root


func _make_grass_cluster() -> Node3D:
	var scene_root := _new_root("GrassCluster")
	for blade in [[Vector3(-0.38, 0.3, 0), Vector3(0.18, 0.6, 0.28), -15.0], [Vector3(-0.1, 0.42, 0.06), Vector3(0.2, 0.84, 0.26), 6.0], [Vector3(0.22, 0.36, -0.05), Vector3(0.18, 0.72, 0.28), 16.0], [Vector3(0.46, 0.27, 0.08), Vector3(0.17, 0.54, 0.25), -9.0]]:
		_add_prism(scene_root, "BroadGrassBlade", blade[0], blade[1], "grass_foliage_light", Vector3(0, 0, blade[2]))
	return scene_root


func _make_rock_small() -> Node3D:
	var scene_root := _new_root("RockSmall")
	_add_boulder(scene_root, "DirectionalBoulder", Vector3.ZERO, Vector3(0.58, 0.66, 0.45), 0.35, "rock_cliff")
	_add_box_collision(scene_root, "RockCollision", Vector3(0, 0.26, 0), Vector3(0.9, 0.52, 0.7))
	return scene_root


func _make_rock_medium() -> Node3D:
	var scene_root := _new_root("RockMedium")
	_add_boulder(scene_root, "MainBoulder", Vector3(-0.14, 0, 0), Vector3(1.0, 1.35, 0.78), 0.8, "rock_cliff")
	_add_boulder(scene_root, "ShoulderBoulder", Vector3(0.72, 0, 0.18), Vector3(0.56, 0.72, 0.5), 1.9, "rock_sunlit")
	_add_box_collision(scene_root, "RockCollision", Vector3(0.08, 0.56, 0), Vector3(1.72, 1.12, 1.25))
	return scene_root


func _make_fence_straight() -> Node3D:
	var scene_root := _new_root("FenceStraight4m")
	for index in range(3):
		var x := -2.0 + 2.0 * float(index)
		_add_mesh(scene_root, "TaperedPost", _irregular_block_mesh(Vector3(0.36, 1.5, 0.4), Vector3(0.05 * (index - 1), 0.04, 0.03), "wood_dark"), Vector3(x, 0.75, 0), Vector3(0, 0, -2.0 + 2.0 * index))
		_add_boulder(scene_root, "StoneFoot", Vector3(x, 0, 0), Vector3(0.38, 0.28, 0.4), 0.7 + index, "stone")
	_add_mesh(scene_root, "RailLow", _irregular_block_mesh(Vector3(4.12, 0.24, 0.25), Vector3(0.08, 0.02, 0.02), "wood"), Vector3(0, 0.57, 0), Vector3(0, 0, 2))
	_add_mesh(scene_root, "RailHigh", _irregular_block_mesh(Vector3(4.12, 0.24, 0.25), Vector3(-0.07, 0.02, -0.02), "wood"), Vector3(0, 1.05, 0), Vector3(0, 0, -2))
	_add_box_collision(scene_root, "FenceCollision", Vector3(0, 0.74, 0), Vector3(4.3, 1.48, 0.44))
	return scene_root


func _make_fence_corner() -> Node3D:
	var scene_root := _new_root("FenceCorner4m")
	for point in [Vector3(0, 0.75, 0), Vector3(2, 0.75, 0), Vector3(0, 0.75, 2)]:
		_add_mesh(scene_root, "CornerPost", _irregular_block_mesh(Vector3(0.38, 1.5, 0.4), Vector3(0.04, 0.03, -0.03), "wood_dark"), point)
	for height in [0.57, 1.05]:
		_add_mesh(scene_root, "RailX", _irregular_block_mesh(Vector3(2.12, 0.24, 0.25), Vector3(0.04, 0.02, 0.02), "wood"), Vector3(1, height, 0))
		_add_mesh(scene_root, "RailZ", _irregular_block_mesh(Vector3(0.25, 0.24, 2.12), Vector3(0.02, 0.02, 0.04), "wood"), Vector3(0, height, 1))
	_add_box_collision(scene_root, "FenceCollisionX", Vector3(1, 0.74, 0), Vector3(2.3, 1.48, 0.44))
	_add_box_collision(scene_root, "FenceCollisionZ", Vector3(0, 0.74, 1), Vector3(0.44, 1.48, 2.3))
	return scene_root


func _add_stone_block(scene_root: Node3D, node_name: String, position: Vector3, size: Vector3, phase: float, rotation := Vector3.ZERO) -> MeshInstance3D:
	var skew := Vector3(0.07 * sin(phase), 0.05 * cos(phase * 1.7), 0.06 * sin(phase * 2.1))
	return _add_mesh(scene_root, node_name, _irregular_block_mesh(size, skew, "stone"), position, rotation)


func _make_ruin_wall() -> Node3D:
	var scene_root := _new_root("RuinWall4m")
	for data in [[-1.5, 0.42, 0.82], [-0.55, 0.4, 0.78], [0.45, 0.43, 0.84], [1.45, 0.38, 0.74], [-1.42, 1.18, 0.72], [-0.48, 1.15, 0.76], [0.5, 1.2, 0.82], [1.4, 1.12, 0.62], [-1.36, 1.88, 0.56], [-0.38, 1.84, 0.66], [0.58, 1.78, 0.48]]:
		_add_stone_block(scene_root, "LargeRuinBlock", Vector3(data[0], data[1], 0), Vector3(0.9, data[2], 0.72), data[0] + data[1])
	_add_box(scene_root, "RestrainedMoss", Vector3(-1.18, 2.2, -0.12), Vector3(0.78, 0.1, 0.52), "grass_foliage_dark", Vector3(0, 0, -5))
	_add_box_collision(scene_root, "WallCollision", Vector3(0, 1.0, 0), Vector3(4, 2.0, 0.78))
	return scene_root


func _make_ruin_arch() -> Node3D:
	var scene_root := _new_root("RuinArch4m")
	for side in [-1.0, 1.0]:
		for row in range(3):
			_add_stone_block(scene_root, "ArchPillarBlock", Vector3(side * 1.38, 0.38 + row * 0.72, 0), Vector3(0.82, 0.68, 0.82), float(row) + side)
	for index in range(7):
		var angle: float = lerp(205.0, 335.0, float(index) / 6.0)
		var radians := deg_to_rad(angle)
		var position := Vector3(cos(radians) * 1.42, 2.0 - sin(radians) * 1.0, 0)
		_add_stone_block(scene_root, "ArchVoussoir", position, Vector3(0.7, 0.72, 0.86), float(index) * 0.7, Vector3(0, 0, angle + 90.0))
	_add_stone_block(scene_root, "BrokenCrownLeft", Vector3(-1.68, 2.75, 0.02), Vector3(0.7, 0.78, 0.8), 2.4, Vector3(0, 0, -8))
	_add_box(scene_root, "ArchMoss", Vector3(-1.45, 3.12, -0.12), Vector3(0.72, 0.1, 0.58), "grass_foliage_dark", Vector3(0, 0, -9))
	_add_box_collision(scene_root, "PillarCollisionLeft", Vector3(-1.38, 1.05, 0), Vector3(0.9, 2.1, 0.9))
	_add_box_collision(scene_root, "PillarCollisionRight", Vector3(1.38, 1.05, 0), Vector3(0.9, 2.1, 0.9))
	return scene_root


func _make_building_wall() -> Node3D:
	var scene_root := _new_root("BuildingWall4m")
	_add_box(scene_root, "WarmPlaster", Vector3(0, 1.32, 0), Vector3(3.45, 2.42, 0.34), "rock_sunlit")
	for x in [-1.84, 1.84]:
		_add_mesh(scene_root, "HeavyTimberPost", _irregular_block_mesh(Vector3(0.34, 2.75, 0.46), Vector3(0.04 * x, 0.03, 0.02), "wood_dark"), Vector3(x, 1.38, -0.05))
		_add_stone_block(scene_root, "StoneFoot", Vector3(x, 0.22, 0), Vector3(0.56, 0.44, 0.58), x)
	_add_box(scene_root, "TopBeam", Vector3(0, 2.58, -0.05), Vector3(4.18, 0.34, 0.46), "wood")
	_add_box(scene_root, "StoneBase", Vector3(0, 0.2, 0), Vector3(3.58, 0.4, 0.54), "stone")
	_add_box(scene_root, "FrameBraceLeft", Vector3(-0.92, 1.5, -0.22), Vector3(0.18, 2.25, 0.16), "wood", Vector3(0, 0, -31))
	_add_box(scene_root, "FrameBraceRight", Vector3(0.92, 1.5, -0.22), Vector3(0.18, 2.25, 0.16), "wood", Vector3(0, 0, 31))
	_add_box_collision(scene_root, "WallCollision", Vector3(0, 1.35, 0), Vector3(4.1, 2.7, 0.54))
	return scene_root


func _make_door_wall() -> Node3D:
	var scene_root := _new_root("DoorWall4m")
	for x in [-1.58, 1.58]:
		_add_box(scene_root, "PlasterPier", Vector3(x, 1.32, 0), Vector3(0.82, 2.42, 0.34), "rock_sunlit")
		_add_mesh(scene_root, "DoorFramePost", _irregular_block_mesh(Vector3(0.28, 2.58, 0.46), Vector3(0.03 * x, 0.03, 0.02), "wood_dark"), Vector3(x + (0.48 if x < 0 else -0.48), 1.3, -0.05))
	_add_box(scene_root, "DoorSlab", Vector3(0, 1.05, 0.04), Vector3(1.34, 2.1, 0.25), "wood")
	for x in [-0.42, 0.0, 0.42]:
		_add_box(scene_root, "DoorPlankShadow", Vector3(x, 1.05, -0.1), Vector3(0.045, 1.78, 0.06), "wood_dark")
	_add_box(scene_root, "DoorLintel", Vector3(0, 2.25, -0.05), Vector3(1.92, 0.32, 0.48), "wood_dark")
	_add_box(scene_root, "TopBeam", Vector3(0, 2.58, -0.05), Vector3(4.18, 0.34, 0.46), "wood")
	_add_box(scene_root, "MetalHandle", Vector3(0.42, 1.05, -0.18), Vector3(0.11, 0.11, 0.1), "metal")
	_add_box_collision(scene_root, "WallCollision", Vector3(0, 1.35, 0), Vector3(4.1, 2.7, 0.54))
	return scene_root


func _make_roof_piece() -> Node3D:
	var scene_root := _new_root("RoofPiece4m")
	_add_box(scene_root, "TerracottaSlopeLeft", Vector3(-1.12, 0.64, 0), Vector3(2.72, 0.28, 4.65), "accent_warm", Vector3(0, 0, -31))
	_add_box(scene_root, "TerracottaSlopeRight", Vector3(1.12, 0.64, 0), Vector3(2.72, 0.28, 4.65), "accent_warm", Vector3(0, 0, 31))
	for x in [-0.58, -1.16, -1.74]:
		_add_box(scene_root, "LeftTileBand", Vector3(x, 1.23 - abs(x) * 0.51, 0), Vector3(0.09, 0.09, 4.7), "wood", Vector3(0, 0, -31))
	for x in [0.58, 1.16, 1.74]:
		_add_box(scene_root, "RightTileBand", Vector3(x, 1.23 - abs(x) * 0.51, 0), Vector3(0.09, 0.09, 4.7), "wood", Vector3(0, 0, 31))
	for z in [-2.12, 0.0, 2.12]:
		_add_taper(scene_root, "DarkRidgeCap", Vector3(0, 1.39, z), 0.17, 0.17, 0.62, "wood_dark", Vector3(90, 0, 0), 8)
	_add_box(scene_root, "LeftEave", Vector3(-2.17, 0.02, 0), Vector3(0.22, 0.24, 4.78), "wood_dark")
	_add_box(scene_root, "RightEave", Vector3(2.17, 0.02, 0), Vector3(0.22, 0.24, 4.78), "wood_dark")
	return scene_root


func _build_reference_scenes() -> void:
	var base := _make_reference_area()
	_save_reference("master_02r_green_coast_area", base)
	_build_reference_view("master_02r_production_overview", "ProductionOverviewCamera", Vector3(17.5, 15.0, 20.5), Vector3(-0.2, -0.2, -1.2), 43.0)
	_build_reference_view("master_02r_gameplay_validation", "GameplayValidationCamera", Vector3(10.2, 6.6, 12.3), Vector3(0.35, 0.82, -0.75), 39.0)


func _make_reference_area() -> Node3D:
	var scene_root := _new_root("Master02RGreenCoastArea")
	_add_box(scene_root, "SeaDepth", Vector3(0, -2.85, -10.5), Vector3(30, 0.34, 13), "shallow_water")
	_add_box(scene_root, "OpenSeaRight", Vector3(10.8, -2.85, 1.0), Vector3(9.0, 0.34, 20.0), "shallow_water")
	_add_box(scene_root, "BeachShelf", Vector3(2.5, -2.52, -6.2), Vector3(14, 0.42, 3.1), "sand", Vector3(0, -3, 0))
	_add_box(scene_root, "SideBeachShelf", Vector3(7.8, -2.52, 1.8), Vector3(2.5, 0.42, 12.0), "sand", Vector3(0, 0, -2))
	for z in [-5.2, -6.15, -7.1]:
		_add_box(scene_root, "RestrainedFoamBand", Vector3(2.2 + 0.18 * sin(z), -2.60, z), Vector3(12.5, 0.025, 0.075), "rock_sunlit", Vector3(0, -2 + z, 0))

	for x in [-8.0, -4.0, 0.0, 4.0]:
		for z in [0.0, 4.0, 8.0]:
			_instance_asset(scene_root, "Ground", "terrain/playable_ground", Vector3(x, 0, z))
	for x in [-8.0, -4.0, 0.0, 4.0]:
		_instance_asset(scene_root, "CliffEdge", "terrain/cliff_straight", Vector3(x, 0, -4.0))
	for z in [0.0, 4.0, 8.0]:
		_instance_asset(scene_root, "SideCliffEdge", "terrain/cliff_straight", Vector3(6.0, 0, z), Vector3(0, -90, 0))
	_instance_asset(scene_root, "CliffCorner", "terrain/cliff_corner", Vector3(6.0, 0, -4.0), Vector3(0, -90, 0))

	for data in [[Vector3(-2.4, 0.02, 4.0), 8.0], [Vector3(-1.8, 0.02, 0.3), -4.0], [Vector3(-0.9, 0.02, -2.9), -12.0]]:
		_instance_asset(scene_root, "ConnectedSoilPath", "terrain/soil_path", data[0], Vector3(0, data[1], 0), Vector3(1.25, 1, 1.15))

	_instance_asset(scene_root, "CottageFront", "village_ruin/door_wall", Vector3(-5.8, 0, 4.9))
	_instance_asset(scene_root, "CottageSide", "village_ruin/building_wall", Vector3(-7.85, 0, 2.85), Vector3(0, 90, 0))
	_instance_asset(scene_root, "CottageRoof", "village_ruin/roof_piece", Vector3(-5.8, 2.76, 2.85))
	_add_box(scene_root, "BlueWayfindingBanner", Vector3(-3.82, 1.48, 4.5), Vector3(0.08, 1.35, 0.72), "fabric_blue", Vector3(0, 0, -4))
	_add_box(scene_root, "BannerCrossbar", Vector3(-3.82, 2.2, 4.5), Vector3(0.18, 0.18, 1.0), "wood_dark")

	_instance_asset(scene_root, "RuinArchHero", "village_ruin/ruin_arch", Vector3(0.6, 0, -3.25), Vector3(0, 8, 0))
	_instance_asset(scene_root, "RuinWallFragment", "village_ruin/ruin_wall", Vector3(3.55, 0, -2.95), Vector3(0, -12, 0), Vector3(0.78, 0.9, 0.86))
	_instance_asset(scene_root, "FencePathWest", "village_ruin/fence_straight", Vector3(-3.75, 0, 0.55), Vector3(0, 83, 0))
	_instance_asset(scene_root, "FencePathEast", "village_ruin/fence_straight", Vector3(2.1, 0, 1.1), Vector3(0, 78, 0))
	_instance_asset(scene_root, "FenceTurn", "village_ruin/fence_corner", Vector3(4.15, 0, 0.7), Vector3(0, -8, 0))

	_instance_asset(scene_root, "BroadleafTree", "nature/tree_base_a", Vector3(-5.0, 0, -0.2), Vector3(0, 22, 0), Vector3(1.12, 1.12, 1.12))
	_instance_asset(scene_root, "CoastalBentTree", "nature/tree_base_b", Vector3(3.7, 0, 3.2), Vector3(0, -34, 0), Vector3(0.92, 0.92, 0.92))
	_instance_asset(scene_root, "BackgroundTreeWest", "nature/tree_base_b", Vector3(-8.1, 0, -2.4), Vector3(0, 38, 0), Vector3(0.78, 0.78, 0.78))
	_instance_asset(scene_root, "BackgroundTreeEast", "nature/tree_base_a", Vector3(5.25, 0, -1.7), Vector3(0, -18, 0), Vector3(0.68, 0.68, 0.68))
	for data in [[Vector3(-3.2, 0, 2.0), 15.0, 1.0], [Vector3(1.85, 0, 2.8), -10.0, 1.2], [Vector3(4.45, 0, -0.6), 55.0, 0.9], [Vector3(-2.5, 0, -2.2), 82.0, 0.86]]:
		_instance_asset(scene_root, "BushCluster", "nature/bush", data[0], Vector3(0, data[1], 0), Vector3.ONE * data[2])
	for data in [[Vector3(-3.0, 0, 3.0), 0.0, 1.0], [Vector3(0.8, 0, 1.6), 60.0, 0.9], [Vector3(3.3, 0, 2.0), 110.0, 1.1], [Vector3(-1.5, 0, -1.7), 25.0, 0.86], [Vector3(4.1, 0, -2.0), 75.0, 0.92]]:
		_instance_asset(scene_root, "BroadGrassCluster", "nature/grass_cluster", data[0], Vector3(0, data[1], 0), Vector3.ONE * data[2])
	for data in [[Vector3(-5.7, 0, 1.1), 15.0, 0.8], [Vector3(-0.2, 0, 2.9), 35.0, 0.76], [Vector3(5.7, 0, 2.2), 80.0, 0.82], [Vector3(6.0, 0, -2.2), 112.0, 0.72]]:
		_instance_asset(scene_root, "SupportingGrass", "nature/grass_cluster", data[0], Vector3(0, data[1], 0), Vector3.ONE * data[2])
	for data in [[Vector3(-4.6, 0, 2.6), 15.0, 0.58], [Vector3(-2.1, 0, 1.2), -22.0, 0.66], [Vector3(0.2, 0, 2.25), 48.0, 0.62], [Vector3(2.7, 0, 0.45), 74.0, 0.7], [Vector3(4.6, 0, -0.5), 96.0, 0.64]]:
		_instance_asset(scene_root, "LowGroundCover", "nature/bush", data[0], Vector3(0, data[1], 0), Vector3.ONE * data[2])
	for data in [["nature/rock_medium", Vector3(-1.0, 0, 2.2), 18.0, 0.72], ["nature/rock_medium", Vector3(4.55, 0, 1.65), -32.0, 0.9], ["nature/rock_small", Vector3(2.0, 0, -1.85), 14.0, 1.0], ["nature/rock_small", Vector3(-3.7, 0, -2.4), -18.0, 0.8]]:
		_instance_asset(scene_root, "DirectionalRock", data[0], data[1], Vector3(0, data[2], 0), Vector3.ONE * data[3])

	for island in [[Vector3(-6.5, -2.6, -11.0), Vector3(1.2, 2.4, 1.0), 0.5], [Vector3(1.5, -2.62, -12.2), Vector3(1.8, 3.4, 1.4), 1.4], [Vector3(7.5, -2.62, -10.4), Vector3(1.0, 1.9, 0.9), 2.2]]:
		_add_boulder(scene_root, "SeaStack", island[0], island[1], island[2], "rock_cliff")
		_add_boulder(scene_root, "SeaStackSunPlane", island[0] + Vector3(-0.15, island[1].y * 0.42, 0), island[1] * Vector3(0.55, 0.38, 0.56), island[2] + 0.7, "rock_sunlit")

	_add_flower_patch(scene_root, Vector3(-3.85, 0, 1.7))
	_add_flower_patch(scene_root, Vector3(2.9, 0, 2.3))
	_add_flower_patch(scene_root, Vector3(-1.8, 0, 3.1))
	_add_flower_patch(scene_root, Vector3(4.6, 0, 0.2))
	return scene_root


func _add_flower_patch(scene_root: Node3D, position: Vector3) -> void:
	for index in range(5):
		var offset := Vector3(0.18 * cos(float(index) * 2.1), 0.05, 0.18 * sin(float(index) * 1.7))
		_add_box(scene_root, "WhiteFlower", position + offset + Vector3(0, 0.22, 0), Vector3(0.14, 0.08, 0.14), "rock_sunlit", Vector3(0, index * 23, index * 9))
		_add_prism(scene_root, "FlowerStem", position + offset + Vector3(0, 0.11, 0), Vector3(0.06, 0.22, 0.07), "grass_foliage_dark")


func _save_reference(file_name: String, scene_root: Node3D) -> void:
	var packed := PackedScene.new()
	if packed.pack(scene_root) != OK:
		_fail("Could not pack reference base")
	if ResourceSaver.save(packed, REFERENCE_ROOT.path_join(file_name + ".tscn")) != OK:
		_fail("Could not save reference base")
	root.remove_child(scene_root)
	scene_root.free()


func _build_reference_view(file_name: String, camera_name: String, camera_position: Vector3, target: Vector3, fov: float) -> void:
	var scene_root := _new_root(file_name.to_pascal_case())
	var area := load(REFERENCE_ROOT.path_join("master_02r_green_coast_area.tscn")).instantiate() as Node3D
	area.name = "GreenCoastPlayableArea"
	scene_root.add_child(area)
	area.owner = scene_root

	var environment := WorldEnvironment.new()
	environment.name = "WarmCoastalEnvironment"
	var env_resource := Environment.new()
	env_resource.background_mode = Environment.BG_COLOR
	env_resource.background_color = Color("#75b2d0")
	env_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_resource.ambient_light_color = Color("#c8d0bf")
	env_resource.ambient_light_energy = 0.30
	env_resource.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env_resource
	scene_root.add_child(environment)
	environment.owner = scene_root

	var sun := DirectionalLight3D.new()
	sun.name = "WarmSun"
	sun.light_color = Color("#ffe8bd")
	sun.light_energy = 0.62
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.62
	sun.rotation_degrees = Vector3(-48, -38, 0)
	scene_root.add_child(sun)
	sun.owner = scene_root

	var fill := DirectionalLight3D.new()
	fill.name = "CoolSkyFill"
	fill.light_color = Color("#b8d6df")
	fill.light_energy = 0.16
	fill.rotation_degrees = Vector3(-64, 135, 0)
	scene_root.add_child(fill)
	fill.owner = scene_root

	var camera := Camera3D.new()
	camera.name = camera_name
	camera.current = true
	camera.fov = fov
	camera.position = camera_position
	scene_root.add_child(camera)
	camera.owner = scene_root
	camera.look_at(target, Vector3.UP)

	var packed := PackedScene.new()
	if packed.pack(scene_root) != OK:
		_fail("Could not pack reference view: " + file_name)
	if ResourceSaver.save(packed, REFERENCE_ROOT.path_join(file_name + ".tscn")) != OK:
		_fail("Could not save reference view: " + file_name)
	root.remove_child(scene_root)
	scene_root.free()


func _load_asset(relative_path: String) -> PackedScene:
	return load(SCENE_ROOT.path_join(relative_path + ".tscn")) as PackedScene


func _instance_asset(scene_root: Node3D, node_name: String, relative_path: String, position: Vector3, rotation := Vector3.ZERO, scale := Vector3.ONE) -> Node3D:
	var instance := _load_asset(relative_path).instantiate() as Node3D
	instance.name = node_name
	instance.position = position
	instance.rotation_degrees = rotation
	instance.scale = scale
	scene_root.add_child(instance)
	instance.owner = scene_root
	return instance


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
