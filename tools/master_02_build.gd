extends SceneTree

const ASSET_ROOT := "res://assets/art/green_coast_prod_v01"
const SCENE_ROOT := "res://scenes/art/green_coast_prod_v01"
const REFERENCE_ROOT := "res://scenes/reference"

var _materials: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_make_directories()
	_build_materials()
	_build_terrain_assets()
	_build_nature_assets()
	_build_village_assets()
	_build_reference_area()
	print("MASTER02_BUILD_OK materials=%d terrain=5 nature=6 village_ruin=7 reference_areas=1" % _materials.size())
	quit(0)


func _make_directories() -> void:
	for directory in [
		ASSET_ROOT.path_join("materials"),
		SCENE_ROOT.path_join("terrain"),
		SCENE_ROOT.path_join("nature"),
		SCENE_ROOT.path_join("village_ruin"),
		REFERENCE_ROOT,
	]:
		var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
		if error != OK:
			_fail("Could not create MASTER-02 directory: " + directory)


func _build_materials() -> void:
	_make_material("grass", Color("#789f3b"), 0.92)
	_make_material("grass_foliage_dark", Color("#315f38"), 0.94)
	_make_material("grass_foliage_light", Color("#679441"), 0.93)
	_make_material("soil_path", Color("#bf8752"), 0.95)
	_make_material("rock_cliff", Color("#85858a"), 0.9)
	_make_material("rock_sunlit", Color("#b3aa9a"), 0.91)
	_make_material("sand", Color("#d8b878"), 0.96)
	_make_material("shallow_water", Color("#2fa8bf", 0.82), 0.22, 0.0, true)
	_make_material("wood", Color("#945029"), 0.86)
	_make_material("wood_dark", Color("#5c3928"), 0.9)
	_make_material("stone", Color("#aaa08f"), 0.92)
	_make_material("fabric_blue", Color("#2f72bd"), 0.88)
	_make_material("metal", Color("#6c7480"), 0.42, 0.32)
	_make_material("accent_warm", Color("#f3c94c"), 0.78)


func _make_material(file_name: String, color: Color, roughness: float, metallic := 0.0, transparent := false) -> void:
	var material := StandardMaterial3D.new()
	material.resource_name = "prod_" + file_name
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	var path := ASSET_ROOT.path_join("materials").path_join(file_name + ".tres")
	if ResourceSaver.save(material, path) != OK:
		_fail("Could not save MASTER-02 material: " + path)
	_materials[file_name] = load(path) as Material


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
		_fail("Could not pack MASTER-02 scene: " + relative_path)
	var path := SCENE_ROOT.path_join(relative_path + ".tscn")
	if ResourceSaver.save(packed, path) != OK:
		_fail("Could not save MASTER-02 scene: " + path)
	root.remove_child(scene_root)
	scene_root.free()


func _add_box(scene_root: Node3D, node_name: String, position: Vector3, size: Vector3, material_name: String, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _materials[material_name]
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.rotation_degrees = rotation
	scene_root.add_child(instance)
	instance.owner = scene_root
	return instance


func _add_cylinder(scene_root: Node3D, node_name: String, position: Vector3, top_radius: float, bottom_radius: float, height: float, material_name: String, rotation := Vector3.ZERO, segments := 8) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	mesh.material = _materials[material_name]
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.rotation_degrees = rotation
	scene_root.add_child(instance)
	instance.owner = scene_root
	return instance


func _add_sphere(scene_root: Node3D, node_name: String, position: Vector3, radius: float, height: float, material_name: String, scale := Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.material = _materials[material_name]
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.scale = scale
	scene_root.add_child(instance)
	instance.owner = scene_root
	return instance


func _add_prism(scene_root: Node3D, node_name: String, position: Vector3, size: Vector3, material_name: String, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := PrismMesh.new()
	mesh.size = size
	mesh.material = _materials[material_name]
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.rotation_degrees = rotation
	scene_root.add_child(instance)
	instance.owner = scene_root
	return instance


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
	_add_box(scene_root, "GrassTop", Vector3(0, -0.12, 0), Vector3(4, 0.24, 4), "grass")
	_add_box(scene_root, "StoneFoundation", Vector3(0, -0.34, 0), Vector3(4, 0.2, 4), "rock_sunlit")
	_add_box_collision(scene_root, "WalkableCollision", Vector3(0, -0.27, 0), Vector3(4, 0.54, 4))
	return scene_root


func _make_soil_path() -> Node3D:
	var scene_root := _new_root("SoilPath4m")
	_add_box(scene_root, "PathColorBlock", Vector3(0, 0.018, 0), Vector3(2.05, 0.035, 4), "soil_path")
	_add_box(scene_root, "SoftEdgeLeft", Vector3(-1.08, 0.01, 0), Vector3(0.12, 0.02, 3.75), "sand", Vector3(0, 0, 1))
	_add_box(scene_root, "SoftEdgeRight", Vector3(1.08, 0.01, 0), Vector3(0.12, 0.02, 3.75), "sand", Vector3(0, 0, -1))
	return scene_root


func _make_cliff_straight() -> Node3D:
	var scene_root := _new_root("CliffStraight4m")
	_add_box(scene_root, "GrassCap", Vector3(0, -0.12, 0.7), Vector3(4, 0.24, 2.6), "grass")
	_add_box(scene_root, "MainRockFace", Vector3(0, -1.35, -0.72), Vector3(4, 2.5, 0.28), "rock_cliff")
	for x in [-1.55, -0.78, 0.0, 0.82, 1.58]:
		_add_prism(scene_root, "RockFacet_%s" % str(x), Vector3(x, -1.35, -0.88), Vector3(0.7, 2.35, 0.34), "rock_sunlit", Vector3(0, 0, 90))
	_add_box_collision(scene_root, "GroundCollision", Vector3(0, -0.27, 0.7), Vector3(4, 0.54, 2.6))
	_add_box_collision(scene_root, "EdgeSafetyCollision", Vector3(0, -0.55, -0.58), Vector3(4, 1.1, 0.4))
	return scene_root


func _make_cliff_corner() -> Node3D:
	var scene_root := _new_root("CliffOuterCorner4m")
	_add_box(scene_root, "GrassCap", Vector3(0.55, -0.12, 0.55), Vector3(2.9, 0.24, 2.9), "grass")
	_add_box(scene_root, "RockFaceSouth", Vector3(0.55, -1.35, -0.92), Vector3(2.9, 2.5, 0.28), "rock_cliff")
	_add_box(scene_root, "RockFaceWest", Vector3(-0.92, -1.35, 0.55), Vector3(0.28, 2.5, 2.9), "rock_cliff")
	for offset in [-0.55, 0.2, 0.95]:
		_add_prism(scene_root, "SouthFacet_%s" % str(offset), Vector3(offset, -1.35, -1.08), Vector3(0.62, 2.3, 0.32), "rock_sunlit", Vector3(0, 0, 90))
		_add_prism(scene_root, "WestFacet_%s" % str(offset), Vector3(-1.08, -1.35, offset), Vector3(0.62, 2.3, 0.32), "rock_sunlit", Vector3(0, 90, 90))
	_add_box_collision(scene_root, "GroundCollision", Vector3(0.55, -0.27, 0.55), Vector3(2.9, 0.54, 2.9))
	return scene_root


func _make_ramp_transition() -> Node3D:
	var scene_root := _new_root("RampTransition4m")
	_add_prism(scene_root, "RockRampBody", Vector3(0, -1.0, 0), Vector3(4, 2, 4), "rock_cliff", Vector3(0, 90, 0))
	_add_box(scene_root, "SoilRampSurface", Vector3(0, -0.96, 0), Vector3(2.35, 0.12, 4.05), "soil_path", Vector3(-26.565, 0, 0))
	_add_box_collision(scene_root, "RampCollision", Vector3(0, -0.96, 0), Vector3(2.35, 0.18, 4.05), Vector3(-26.565, 0, 0))
	return scene_root


func _make_tree_a() -> Node3D:
	var scene_root := _new_root("TreeBaseA")
	_add_cylinder(scene_root, "Trunk", Vector3(0, 1.45, 0), 0.35, 0.52, 2.9, "wood_dark", Vector3(0, 0, -4), 7)
	_add_cylinder(scene_root, "BranchLeft", Vector3(-0.48, 2.35, 0), 0.18, 0.25, 1.3, "wood_dark", Vector3(0, 0, 48), 7)
	_add_cylinder(scene_root, "BranchRight", Vector3(0.52, 2.52, -0.08), 0.16, 0.24, 1.15, "wood_dark", Vector3(6, 0, -52), 7)
	_add_sphere(scene_root, "CrownMain", Vector3(0, 3.55, 0), 1.1, 2.15, "grass_foliage_dark", Vector3(1.2, 0.9, 1.0))
	_add_sphere(scene_root, "CrownSun", Vector3(-0.72, 3.72, 0.1), 0.76, 1.45, "grass_foliage_light")
	_add_sphere(scene_root, "CrownSide", Vector3(0.8, 3.45, -0.12), 0.82, 1.55, "grass_foliage_light", Vector3(1.0, 0.9, 1.1))
	_add_box_collision(scene_root, "TrunkCollision", Vector3(0, 1.35, 0), Vector3(0.9, 2.7, 0.9))
	return scene_root


func _make_tree_b() -> Node3D:
	var scene_root := _new_root("TreeBaseB")
	_add_cylinder(scene_root, "BentTrunk", Vector3(0, 1.3, 0), 0.32, 0.48, 2.65, "wood", Vector3(4, 0, 12), 7)
	_add_cylinder(scene_root, "LongBranch", Vector3(0.62, 2.25, 0), 0.17, 0.25, 1.75, "wood", Vector3(0, 0, -58), 7)
	_add_sphere(scene_root, "CrownLeft", Vector3(-0.25, 3.05, 0), 0.85, 1.55, "grass_foliage_dark", Vector3(1.1, 0.9, 1.0))
	_add_sphere(scene_root, "CrownRight", Vector3(0.95, 2.95, 0.05), 0.92, 1.65, "grass_foliage_light", Vector3(1.2, 0.82, 1.0))
	_add_sphere(scene_root, "CrownTop", Vector3(0.45, 3.55, -0.12), 0.65, 1.2, "grass_foliage_light")
	_add_box_collision(scene_root, "TrunkCollision", Vector3(0, 1.2, 0), Vector3(0.9, 2.4, 0.9), Vector3(0, 0, 12))
	return scene_root


func _make_bush() -> Node3D:
	var scene_root := _new_root("BushBase")
	_add_sphere(scene_root, "LeafMassDark", Vector3(-0.38, 0.48, 0), 0.52, 0.9, "grass_foliage_dark", Vector3(1.2, 0.8, 1.0))
	_add_sphere(scene_root, "LeafMassLight", Vector3(0.28, 0.58, -0.12), 0.58, 1.0, "grass_foliage_light", Vector3(1.15, 0.82, 1.0))
	_add_sphere(scene_root, "LeafMassSide", Vector3(0.62, 0.36, 0.2), 0.4, 0.7, "grass_foliage_dark")
	return scene_root


func _make_grass_cluster() -> Node3D:
	var scene_root := _new_root("GrassCluster")
	for blade in [
		[Vector3(-0.38, 0.3, 0), Vector3(0.14, 0.6, 0.22), -12.0],
		[Vector3(-0.08, 0.42, 0.06), Vector3(0.16, 0.84, 0.2), 5.0],
		[Vector3(0.22, 0.36, -0.05), Vector3(0.14, 0.72, 0.22), 14.0],
		[Vector3(0.43, 0.27, 0.08), Vector3(0.13, 0.54, 0.2), -7.0],
	]:
		_add_prism(scene_root, "Blade", blade[0], blade[1], "grass_foliage_light", Vector3(0, 0, blade[2]))
	return scene_root


func _make_rock_small() -> Node3D:
	var scene_root := _new_root("RockSmall")
	_add_sphere(scene_root, "RockBody", Vector3(0, 0.28, 0), 0.48, 0.62, "rock_cliff", Vector3(1.05, 0.85, 0.9))
	_add_box(scene_root, "SunlitPlane", Vector3(-0.12, 0.48, -0.08), Vector3(0.55, 0.18, 0.48), "rock_sunlit", Vector3(8, 18, 12))
	_add_box_collision(scene_root, "RockCollision", Vector3(0, 0.28, 0), Vector3(0.82, 0.56, 0.72))
	return scene_root


func _make_rock_medium() -> Node3D:
	var scene_root := _new_root("RockMedium")
	_add_sphere(scene_root, "RockBody", Vector3(0, 0.62, 0), 0.86, 1.2, "rock_cliff", Vector3(1.0, 1.0, 0.82))
	_add_sphere(scene_root, "RockSide", Vector3(0.62, 0.36, 0.15), 0.46, 0.72, "rock_sunlit", Vector3(1.0, 0.86, 0.9))
	_add_box_collision(scene_root, "RockCollision", Vector3(0.12, 0.55, 0), Vector3(1.55, 1.1, 1.2))
	return scene_root


func _make_fence_straight() -> Node3D:
	var scene_root := _new_root("FenceStraight4m")
	for x in [-2.0, 0.0, 2.0]:
		_add_box(scene_root, "Post", Vector3(x, 0.72, 0), Vector3(0.3, 1.44, 0.34), "wood_dark")
		_add_box(scene_root, "StoneFoot", Vector3(x, 0.14, 0), Vector3(0.5, 0.28, 0.52), "stone")
	_add_box(scene_root, "RailLow", Vector3(0, 0.55, 0), Vector3(4.15, 0.22, 0.24), "wood", Vector3(0, 0, 2))
	_add_box(scene_root, "RailHigh", Vector3(0, 1.02, 0), Vector3(4.15, 0.22, 0.24), "wood", Vector3(0, 0, -2))
	_add_box_collision(scene_root, "FenceCollision", Vector3(0, 0.72, 0), Vector3(4.3, 1.44, 0.42))
	return scene_root


func _make_fence_corner() -> Node3D:
	var scene_root := _new_root("FenceCorner4m")
	for point in [Vector3(0, 0.72, 0), Vector3(2, 0.72, 0), Vector3(0, 0.72, 2)]:
		_add_box(scene_root, "Post", point, Vector3(0.3, 1.44, 0.34), "wood_dark")
		_add_box(scene_root, "StoneFoot", Vector3(point.x, 0.14, point.z), Vector3(0.5, 0.28, 0.52), "stone")
	for height in [0.55, 1.02]:
		_add_box(scene_root, "RailX", Vector3(1, height, 0), Vector3(2.15, 0.22, 0.24), "wood")
		_add_box(scene_root, "RailZ", Vector3(0, height, 1), Vector3(0.24, 0.22, 2.15), "wood")
	_add_box_collision(scene_root, "FenceCollisionX", Vector3(1, 0.72, 0), Vector3(2.3, 1.44, 0.42))
	_add_box_collision(scene_root, "FenceCollisionZ", Vector3(0, 0.72, 1), Vector3(0.42, 1.44, 2.3))
	return scene_root


func _make_ruin_wall() -> Node3D:
	var scene_root := _new_root("RuinWall4m")
	for x in [-1.5, -0.5, 0.5, 1.5]:
		for y in [0.35, 1.05, 1.75]:
			var top_missing: bool = float(y) > 1.5 and (float(x) == -0.5 or float(x) == 1.5)
			if not top_missing:
				_add_box(scene_root, "StoneBlock", Vector3(x, y, 0), Vector3(0.92, 0.62, 0.62), "stone", Vector3(0, 0, 1 if x > 0 else -1))
	_add_box(scene_root, "MossCap", Vector3(-1.45, 2.08, 0), Vector3(0.72, 0.12, 0.58), "grass_foliage_light")
	_add_box_collision(scene_root, "WallCollision", Vector3(0, 1.05, 0), Vector3(4, 2.1, 0.7))
	return scene_root


func _make_ruin_arch() -> Node3D:
	var scene_root := _new_root("RuinArch4m")
	for x in [-1.45, 1.45]:
		for y in [0.35, 1.05, 1.75]:
			_add_box(scene_root, "ArchPillar", Vector3(x, y, 0), Vector3(0.78, 0.62, 0.68), "stone", Vector3(0, 0, 2 if x > 0 else -2))
	_add_box(scene_root, "ArchLintel", Vector3(0, 2.25, 0), Vector3(3.55, 0.62, 0.72), "stone")
	_add_prism(scene_root, "ArchCrown", Vector3(0, 2.72, 0), Vector3(3.1, 0.62, 0.7), "rock_sunlit", Vector3(0, 0, 180))
	_add_box(scene_root, "MossLeft", Vector3(-1.2, 2.62, -0.12), Vector3(0.85, 0.12, 0.5), "grass_foliage_light", Vector3(0, 0, -8))
	_add_box_collision(scene_root, "PillarCollisionLeft", Vector3(-1.45, 1.05, 0), Vector3(0.86, 2.1, 0.78))
	_add_box_collision(scene_root, "PillarCollisionRight", Vector3(1.45, 1.05, 0), Vector3(0.86, 2.1, 0.78))
	_add_box_collision(scene_root, "LintelCollision", Vector3(0, 2.25, 0), Vector3(3.55, 0.62, 0.78))
	return scene_root


func _make_building_wall() -> Node3D:
	var scene_root := _new_root("BuildingWall4m")
	_add_box(scene_root, "PlasterPanel", Vector3(0, 1.25, 0), Vector3(3.45, 2.5, 0.32), "rock_sunlit")
	for x in [-1.85, 1.85]:
		_add_box(scene_root, "TimberPost", Vector3(x, 1.35, -0.04), Vector3(0.3, 2.7, 0.42), "wood_dark")
		_add_box(scene_root, "StoneFoot", Vector3(x, 0.2, 0), Vector3(0.5, 0.4, 0.52), "stone")
	_add_box(scene_root, "TopBeam", Vector3(0, 2.5, -0.04), Vector3(4, 0.3, 0.42), "wood")
	_add_box(scene_root, "StoneBase", Vector3(0, 0.18, 0), Vector3(3.55, 0.36, 0.48), "stone")
	_add_box_collision(scene_root, "WallCollision", Vector3(0, 1.3, 0), Vector3(4, 2.6, 0.5))
	return scene_root


func _make_door_wall() -> Node3D:
	var scene_root := _new_root("DoorWall4m")
	for x in [-1.62, 1.62]:
		_add_box(scene_root, "PlasterPier", Vector3(x, 1.25, 0), Vector3(0.75, 2.5, 0.32), "rock_sunlit")
		_add_box(scene_root, "TimberPost", Vector3(x + (0.48 if x < 0 else -0.48), 1.35, -0.04), Vector3(0.24, 2.7, 0.42), "wood_dark")
	_add_box(scene_root, "Door", Vector3(0, 1.05, 0.03), Vector3(1.35, 2.1, 0.24), "wood")
	_add_box(scene_root, "DoorInset", Vector3(0, 1.08, -0.11), Vector3(0.95, 1.68, 0.08), "wood_dark")
	_add_box(scene_root, "Lintel", Vector3(0, 2.32, -0.04), Vector3(1.9, 0.3, 0.45), "wood")
	_add_box(scene_root, "TopBeam", Vector3(0, 2.5, -0.04), Vector3(4, 0.3, 0.42), "wood")
	_add_box(scene_root, "Handle", Vector3(0.42, 1.05, -0.19), Vector3(0.1, 0.1, 0.1), "metal")
	_add_box_collision(scene_root, "WallCollision", Vector3(0, 1.3, 0), Vector3(4, 2.6, 0.5))
	return scene_root


func _make_roof_piece() -> Node3D:
	var scene_root := _new_root("RoofPiece4m")
	_add_box(scene_root, "RoofSlopeLeft", Vector3(-1.05, 0.58, 0), Vector3(2.45, 0.24, 4.3), "wood", Vector3(0, 0, -31))
	_add_box(scene_root, "RoofSlopeRight", Vector3(1.05, 0.58, 0), Vector3(2.45, 0.24, 4.3), "wood", Vector3(0, 0, 31))
	_add_cylinder(scene_root, "Ridge", Vector3(0, 1.24, 0), 0.16, 0.16, 4.35, "wood_dark", Vector3(90, 0, 0), 8)
	return scene_root


func _build_reference_area() -> void:
	var scene_root := _new_root("Master02ProductionBaseline")
	var environment := WorldEnvironment.new()
	environment.name = "BrightWarmEnvironment"
	var env_resource := Environment.new()
	env_resource.background_mode = Environment.BG_COLOR
	env_resource.background_color = Color("#91cada")
	env_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_resource.ambient_light_color = Color("#f6e4c2")
	env_resource.ambient_light_energy = 0.38
	env_resource.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env_resource
	scene_root.add_child(environment)
	environment.owner = scene_root

	var sun := DirectionalLight3D.new()
	sun.name = "WarmSun"
	sun.light_color = Color("#fff0c0")
	sun.light_energy = 0.82
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-52, -35, 0)
	scene_root.add_child(sun)
	sun.owner = scene_root

	var camera := Camera3D.new()
	camera.name = "GameplayCamera"
	camera.current = true
	camera.fov = 46.0
	camera.position = Vector3(14.5, 12.5, 16.5)
	scene_root.add_child(camera)
	camera.owner = scene_root
	camera.look_at(Vector3(0, 0.9, 0.5), Vector3.UP)

	_add_box(scene_root, "Sea", Vector3(0, -0.72, -9), Vector3(34, 0.18, 12), "shallow_water")
	_add_box(scene_root, "Beach", Vector3(0, -0.44, -3.6), Vector3(20, 0.3, 3.5), "sand")

	_instance_asset(scene_root, "TerrainA", "terrain/playable_ground", Vector3(-6, 0, 4))
	_instance_asset(scene_root, "TerrainB", "terrain/playable_ground", Vector3(-2, 0, 4))
	_instance_asset(scene_root, "TerrainC", "terrain/playable_ground", Vector3(2, 0, 4))
	_instance_asset(scene_root, "TerrainD", "terrain/playable_ground", Vector3(6, 0, 4))
	_instance_asset(scene_root, "PathA", "terrain/soil_path", Vector3(-2, 0, 4))
	_instance_asset(scene_root, "PathB", "terrain/soil_path", Vector3(-2, 0, 0))
	_instance_asset(scene_root, "CliffStraightA", "terrain/cliff_straight", Vector3(-6, 0, 0))
	_instance_asset(scene_root, "CliffStraightB", "terrain/cliff_straight", Vector3(-2, 0, 0))
	_instance_asset(scene_root, "CliffCorner", "terrain/cliff_corner", Vector3(3.45, 0, 0.05))
	_instance_asset(scene_root, "Ramp", "terrain/ramp_transition", Vector3(7.2, 0, 0.4), Vector3(0, 180, 0))

	_instance_asset(scene_root, "TreeA", "nature/tree_base_a", Vector3(-6.2, 0, 5.1), Vector3(0, 18, 0))
	_instance_asset(scene_root, "TreeB", "nature/tree_base_b", Vector3(5.5, 0, 4.7), Vector3(0, -22, 0))
	_instance_asset(scene_root, "BushA", "nature/bush", Vector3(-4.5, 0, 2.9))
	_instance_asset(scene_root, "BushB", "nature/bush", Vector3(4.1, 0, 4.6), Vector3(0, 60, 0), Vector3(1.18, 1.05, 1.18))
	_instance_asset(scene_root, "GrassA", "nature/grass_cluster", Vector3(-3.7, 0, 5.3))
	_instance_asset(scene_root, "GrassB", "nature/grass_cluster", Vector3(3.4, 0, 5.6), Vector3(0, 110, 0), Vector3(0.85, 0.9, 0.85))
	_instance_asset(scene_root, "RockSmall", "nature/rock_small", Vector3(0.2, 0, 1.5), Vector3(0, 25, 0))
	_instance_asset(scene_root, "RockMedium", "nature/rock_medium", Vector3(6.2, -0.28, -2.6), Vector3(0, -30, 0))

	_instance_asset(scene_root, "FenceA", "village_ruin/fence_straight", Vector3(-5.6, 0, 6.0), Vector3(0, 90, 0))
	_instance_asset(scene_root, "FenceCorner", "village_ruin/fence_corner", Vector3(-5.6, 0, 4.0), Vector3(0, 90, 0))
	_instance_asset(scene_root, "RuinWall", "village_ruin/ruin_wall", Vector3(0.5, 0, 6.0), Vector3(0, 180, 0))
	_instance_asset(scene_root, "RuinArch", "village_ruin/ruin_arch", Vector3(3.9, 0, 6.0), Vector3(0, 180, 0))
	_instance_asset(scene_root, "BuildingWall", "village_ruin/building_wall", Vector3(-7.0, 0, 7.8), Vector3(0, 90, 0))
	_instance_asset(scene_root, "DoorWall", "village_ruin/door_wall", Vector3(-7.0, 0, 3.8), Vector3(0, 90, 0))
	_instance_asset(scene_root, "Roof", "village_ruin/roof_piece", Vector3(-7.0, 2.7, 5.8), Vector3(0, 0, 0))

	for rock_data in [
		[Vector3(-8.0, -0.3, -5.1), Vector3(1.2, 1.5, 1.1)],
		[Vector3(-5.8, -0.45, -7.0), Vector3(0.75, 0.95, 0.8)],
		[Vector3(4.8, -0.35, -6.2), Vector3(1.0, 1.25, 0.9)],
	]:
		var coast_rock := _load_asset("nature/rock_medium").instantiate() as Node3D
		coast_rock.position = rock_data[0]
		coast_rock.scale = rock_data[1]
		scene_root.add_child(coast_rock)
		coast_rock.owner = scene_root

	var packed := PackedScene.new()
	if packed.pack(scene_root) != OK:
		_fail("Could not pack MASTER-02 reference area")
	if ResourceSaver.save(packed, REFERENCE_ROOT.path_join("master_02_production_baseline.tscn")) != OK:
		_fail("Could not save MASTER-02 reference area")
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
