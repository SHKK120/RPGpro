extends "res://tools/master_02r_build.gd"

# MASTER-03 expands the approved MASTER-02R construction language into the
# reusable Green Coast production kit.  The runtime integration deliberately
# remains separate so these scenes can be inspected and reused on later maps.


func _initialize() -> void:
	call_deferred("_run_master_03")


func _run_master_03() -> void:
	_build_materials()
	_build_extra_materials()
	_build_terrain_assets()
	_build_nature_assets()
	_build_village_assets()
	_upgrade_b_assets()
	_build_extended_terrain()
	_build_extended_nature()
	_build_extended_village_ruins()
	print("MASTER03_BUILD_OK materials=%d terrain=35 nature=18 village_ruin=30" % _materials.size())
	quit(0)


func _build_extra_materials() -> void:
	# Live-world calibration: brighter than the isolated MASTER-02R board while
	# keeping every family away from neon/cyan and clipped white.
	_make_material("grass", Color("#719449"), 0.96)
	_make_material("grass_foliage_dark", Color("#315b3b"), 0.98)
	_make_material("grass_foliage_light", Color("#6b9344"), 0.97)
	_make_material("soil_path", Color("#ad7952"), 0.98)
	_make_material("rock_cliff", Color("#7e7d79"), 0.96)
	_make_material("rock_sunlit", Color("#aaa18d"), 0.96)
	_make_material("sand", Color("#d0af73"), 0.98)
	_make_material("wood", Color("#98572e"), 0.94)
	_make_material("wood_dark", Color("#573522"), 0.96)
	_make_material("stone", Color("#989286"), 0.98)
	_make_material("accent_warm", Color("#a64f31"), 0.95)
	_make_master_03_water_material()
	_make_material("wet_sand", Color("#a28a69"), 0.82)
	_make_material("building_plaster", Color("#d0c1a1"), 0.98)
	_make_material("roof_terracotta", Color("#a64f31"), 0.94)
	_make_material("flower_white", Color("#e1dcc8"), 0.92)
	_make_material("flower_yellow", Color("#c9a446"), 0.94)
	_make_material("flower_purple", Color("#80648e"), 0.94)
	_make_material("rope", Color("#9a7748"), 0.98)
	_make_material("water_foam", Color("#b8d9d2"), 0.76)


func _make_master_03_water_material() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley;

void vertex() {
	float broad = sin((VERTEX.x + VERTEX.z) * 0.28 + TIME * 0.58) * 0.030;
	float cross = sin((VERTEX.x - VERTEX.z) * 0.47 - TIME * 0.34) * 0.014;
	VERTEX.y += broad + cross;
}

void fragment() {
	float band = 0.5 + 0.5 * sin((UV.x * 18.0 + UV.y * 11.0) + TIME * 0.22);
	vec3 deep = vec3(0.08, 0.39, 0.55);
	vec3 light_coast = vec3(0.16, 0.58, 0.68);
	ALBEDO = mix(deep, light_coast, 0.34 + band * 0.10);
	ROUGHNESS = 0.38;
}
"""
	var material := ShaderMaterial.new()
	material.resource_name = "prod_shallow_water"
	material.shader = shader
	var path := ASSET_ROOT.path_join("materials/shallow_water.tres")
	if ResourceSaver.save(material, path) != OK:
		_fail("Could not save MASTER-03 water material: " + path)
	_materials["shallow_water"] = load(path) as Material


func _upgrade_b_assets() -> void:
	var ground := _make_playable_ground()
	_add_boulder(ground, "EdgeRockA", Vector3(-1.55, 0.13, 1.45), Vector3(0.34, 0.25, 0.31), 0.4, "rock_sunlit")
	_add_boulder(ground, "EdgeRockB", Vector3(1.60, 0.10, -1.45), Vector3(0.24, 0.19, 0.28), 1.8, "rock_cliff")
	_add_box(ground, "GrassVariation", Vector3(0.85, 0.071, 0.92), Vector3(1.05, 0.018, 0.74), "grass_foliage_light", Vector3(0, 0.18, 0))
	_save_scene("terrain/playable_ground", ground)

	var path := _make_soil_path()
	_add_box(path, "SoftShoulderA", Vector3(-0.78, 0.073, 0.15), Vector3(0.38, 0.018, 1.25), "grass_foliage_light", Vector3(0, -0.08, 0))
	_add_box(path, "SoftShoulderB", Vector3(0.76, 0.071, -0.48), Vector3(0.31, 0.016, 0.88), "grass_foliage_dark", Vector3(0, 0.12, 0))
	_save_scene("terrain/soil_path", path)

	var straight := _make_cliff_straight()
	_add_boulder(straight, "FootRock", Vector3(1.45, 0.30, 1.93), Vector3(0.72, 0.58, 0.55), 2.1, "rock_cliff")
	_save_scene("terrain/cliff_straight", straight)

	var corner := _make_cliff_corner()
	_add_boulder(corner, "CornerFoot", Vector3(-1.42, 0.33, 1.42), Vector3(0.72, 0.62, 0.78), 1.3, "rock_sunlit")
	_save_scene("terrain/cliff_corner", corner)

	var ramp := _make_ramp_transition()
	_add_boulder(ramp, "RampFootA", Vector3(-1.55, 0.24, 1.48), Vector3(0.52, 0.42, 0.56), 0.8, "rock_cliff")
	_add_boulder(ramp, "RampFootB", Vector3(1.58, 0.21, 1.25), Vector3(0.42, 0.36, 0.48), 2.4, "rock_sunlit")
	_save_scene("terrain/ramp_transition", ramp)

	var bush := _make_bush()
	_add_blob(bush, "LeafMassE", Vector3(-0.44, 0.55, 0.30), Vector3(0.74, 0.72, 0.66), "grass_foliage_light", 2.7)
	_add_blob(bush, "LeafMassF", Vector3(0.42, 0.46, -0.30), Vector3(0.66, 0.58, 0.62), "grass_foliage_dark", 4.0)
	_save_scene("nature/bush", bush)

	var grass := _make_grass_cluster()
	for index in range(4):
		_add_prism(grass, "ExtraBlade%d" % index, Vector3(-0.42 + index * 0.28, 0.31 + (index % 2) * 0.08, 0.16), Vector3(0.10, 0.62 + (index % 2) * 0.16, 0.20), "grass_foliage_light", Vector3(0, index * 0.42, (-0.12 + index * 0.07)))
	_save_scene("nature/grass_cluster", grass)


func _build_extended_terrain() -> void:
	_save_scene("terrain/ground_large", _make_ground("GroundLarge", Vector3(8, 0.14, 8)))
	_save_scene("terrain/ground_medium", _make_ground("GroundMedium", Vector3(6, 0.14, 6)))
	_save_scene("terrain/ground_small", _make_ground("GroundSmall", Vector3(4, 0.14, 4)))
	_save_scene("terrain/ground_transition", _make_ground_transition())
	_save_scene("terrain/combat_ground_wide", _make_combat_ground())
	_save_scene("terrain/path_straight", _make_path_variant("PathStraight", 0))
	_save_scene("terrain/path_corner", _make_path_variant("PathCorner", 1))
	_save_scene("terrain/path_t_junction", _make_path_variant("PathTJunction", 2))
	_save_scene("terrain/path_wide", _make_path_variant("PathWide", 3))
	_save_scene("terrain/path_narrow", _make_path_variant("PathNarrow", 4))
	_save_scene("terrain/path_irregular", _make_path_variant("PathIrregular", 5))
	_save_scene("terrain/cliff_inner_corner", _make_cliff_variant("CliffInnerCorner", 0))
	_save_scene("terrain/cliff_outer_corner", _make_cliff_variant("CliffOuterCorner", 1))
	_save_scene("terrain/cliff_end_cap", _make_cliff_variant("CliffEndCap", 2))
	_save_scene("terrain/cliff_ledge_step", _make_cliff_variant("CliffLedgeStep", 3))
	_save_scene("terrain/cliff_plateau", _make_cliff_variant("CliffPlateau", 4))
	_save_scene("terrain/cliff_transition", _make_cliff_variant("CliffTransition", 5))
	_save_scene("terrain/ramp_wide", _make_ramp("RampWide", 3.4))
	_save_scene("terrain/ramp_narrow", _make_ramp("RampNarrow", 2.0))
	_save_scene("terrain/natural_steps", _make_steps("NaturalSteps", false))
	_save_scene("terrain/stone_stairs", _make_steps("StoneStairs", true))
	_save_scene("terrain/small_step", _make_small_step())
	_save_scene("terrain/sand_tile", _make_coast_tile("SandTile", 0))
	_save_scene("terrain/rocky_beach", _make_coast_tile("RockyBeach", 1))
	_save_scene("terrain/beach_transition", _make_coast_tile("BeachTransition", 2))
	_save_scene("terrain/cliff_to_beach", _make_coast_tile("CliffToBeach", 3))
	_save_scene("terrain/sand_to_water", _make_coast_tile("SandToWater", 4))
	_save_scene("terrain/shoreline_edge", _make_coast_tile("ShorelineEdge", 5))
	_save_scene("terrain/rock_large", _make_large_rock())
	_save_scene("terrain/sea_stack", _make_sea_stack())


func _make_ground(node_name: String, size: Vector3) -> Node3D:
	var asset := _new_root(node_name)
	_add_box(asset, "WalkableCap", Vector3(0, 0.07, 0), size, "grass")
	_add_box(asset, "StoneFoundation", Vector3(0, -0.18, 0), Vector3(size.x, 0.36, size.z), "rock_cliff")
	_add_box_collision(asset, "SimpleCollision", Vector3(0, -0.11, 0), Vector3(size.x, 0.5, size.z))
	return asset


func _make_ground_transition() -> Node3D:
	var asset := _make_ground("GroundTransition", Vector3(4, 0.14, 4))
	_add_box(asset, "SoilBlendA", Vector3(0.55, 0.151, 0.18), Vector3(2.65, 0.018, 1.35), "soil_path", Vector3(0, 0.1, 0))
	_add_box(asset, "SoilBlendB", Vector3(-0.45, 0.153, 1.25), Vector3(1.75, 0.018, 1.05), "soil_path", Vector3(0, -0.1, 0))
	return asset


func _make_combat_ground() -> Node3D:
	var asset := _make_ground("CombatGroundWide", Vector3(10, 0.14, 8))
	for data in [[-3.6, -2.7, 0.55], [3.4, 2.8, 0.48], [4.0, -2.5, 0.35], [-3.9, 2.4, 0.32]]:
		_add_boulder(asset, "BoundaryRock", Vector3(data[0], 0.16, data[1]), Vector3(data[2], data[2] * 0.7, data[2]), data[0], "rock_sunlit")
	return asset


func _make_path_variant(node_name: String, kind: int) -> Node3D:
	var asset := _new_root(node_name)
	var width := 1.55 if kind == 4 else (3.0 if kind == 3 else 2.25)
	_add_box(asset, "SoilMain", Vector3(0, 0.035, 0), Vector3(width, 0.07, 4), "soil_path")
	if kind in [1, 2]:
		_add_box(asset, "SoilBranch", Vector3(1.0, 0.037, 1.0), Vector3(2.0, 0.07, width), "soil_path")
	if kind == 2:
		_add_box(asset, "SoilBranchLeft", Vector3(-1.0, 0.038, 1.0), Vector3(2.0, 0.07, width), "soil_path")
	if kind == 5:
		_add_box(asset, "SoilOffset", Vector3(0.34, 0.038, -0.65), Vector3(width * 0.92, 0.07, 2.4), "soil_path", Vector3(0, -0.12, 0))
	for index in range(3):
		_add_boulder(asset, "InsetStone%d" % index, Vector3(-0.42 + index * 0.42, 0.075, -1.15 + index * 0.95), Vector3(0.18, 0.08, 0.16), index + kind, "rock_sunlit")
	return asset


func _make_cliff_variant(node_name: String, kind: int) -> Node3D:
	var asset := _new_root(node_name)
	var cap_size := Vector3(4, 0.14, 4)
	_add_box(asset, "GrassCap", Vector3(0, 2.05, 0), cap_size, "grass")
	_add_mesh(asset, "FacetedFace", _cliff_face_mesh(4.0, 4.0, "rock_cliff", kind * 0.63), Vector3(0, 0, 1.94))
	if kind in [0, 1, 4]:
		_add_mesh(asset, "SideFace", _cliff_face_mesh(4.0, 4.0, "rock_sunlit", 1.1 + kind), Vector3(-1.94, 0, 0), Vector3(0, PI * 0.5, 0))
	if kind in [2, 3, 5]:
		_add_boulder(asset, "Shoulder", Vector3(-1.35 + kind * 0.18, 0.62, 1.52), Vector3(0.9, 1.1, 0.82), kind, "rock_sunlit")
	_add_box_collision(asset, "CliffCollision", Vector3(0, 0, 0), Vector3(4, 4.1, 4))
	return asset


func _make_ramp(node_name: String, width: float) -> Node3D:
	var asset := _new_root(node_name)
	_add_box(asset, "WalkableSlope", Vector3(0, 1.0, 0), Vector3(width, 0.18, 4.3), "soil_path", Vector3(-0.46, 0, 0))
	_add_box(asset, "RockShoulderL", Vector3(-width * 0.56, 0.72, 0), Vector3(0.42, 1.6, 4.1), "rock_cliff", Vector3(-0.40, 0, 0))
	_add_box(asset, "RockShoulderR", Vector3(width * 0.56, 0.72, 0), Vector3(0.42, 1.6, 4.1), "rock_sunlit", Vector3(-0.40, 0, 0))
	_add_box_collision(asset, "SlopeCollision", Vector3(0, 0.92, 0), Vector3(width, 0.28, 4.2), Vector3(-0.46, 0, 0))
	return asset


func _make_steps(node_name: String, dressed: bool) -> Node3D:
	var asset := _new_root(node_name)
	for index in range(5):
		var material := "stone" if dressed else ("rock_sunlit" if index % 2 == 0 else "rock_cliff")
		_add_box(asset, "Step%d" % index, Vector3(0, 0.18 + index * 0.36, 1.55 - index * 0.68), Vector3(2.8, 0.36, 0.78), material, Vector3(0, (index - 2) * 0.018, 0))
	_add_box_collision(asset, "StepRampCollision", Vector3(0, 0.85, 0.18), Vector3(2.75, 0.22, 4.0), Vector3(-0.48, 0, 0))
	return asset


func _make_small_step() -> Node3D:
	var asset := _new_root("SmallStep")
	_add_box(asset, "StoneStep", Vector3(0, 0.20, 0), Vector3(2.3, 0.4, 1.25), "stone")
	_add_box_collision(asset, "Collision", Vector3(0, 0.20, 0), Vector3(2.3, 0.4, 1.25))
	return asset


func _make_coast_tile(node_name: String, kind: int) -> Node3D:
	var asset := _new_root(node_name)
	_add_box(asset, "Sand", Vector3(0, 0.02, 0), Vector3(4, 0.12, 4), "sand")
	if kind in [2, 3]:
		_add_box(asset, "GrassBlend", Vector3(0, 0.10, -1.35), Vector3(4, 0.08, 1.3), "grass")
	if kind in [4, 5]:
		_add_box(asset, "WetBand", Vector3(0, 0.095, 0.65), Vector3(4, 0.04, 1.15), "wet_sand")
		_add_box(asset, "Water", Vector3(0, 0.10, 1.45), Vector3(4, 0.035, 1.05), "shallow_water")
		_add_box(asset, "Foam", Vector3(0, 0.13, 0.92), Vector3(4, 0.018, 0.12), "water_foam")
	if kind in [1, 3]:
		for index in range(4):
			_add_boulder(asset, "BeachRock%d" % index, Vector3(-1.2 + index * 0.78, 0.15, -0.6 + (index % 2) * 1.2), Vector3(0.42 + index * 0.07, 0.33 + index * 0.08, 0.46), index * 1.1, "rock_sunlit")
	return asset


func _make_large_rock() -> Node3D:
	var asset := _new_root("RockLarge")
	_add_boulder(asset, "MainMass", Vector3(0, 0.95, 0), Vector3(2.2, 2.05, 1.8), 0.7, "rock_cliff")
	_add_boulder(asset, "SunPlane", Vector3(-0.65, 1.10, -0.10), Vector3(1.12, 1.45, 1.05), 2.2, "rock_sunlit")
	_add_box_collision(asset, "SimpleCollision", Vector3(0, 0.78, 0), Vector3(1.8, 1.56, 1.45))
	return asset


func _make_sea_stack() -> Node3D:
	var asset := _new_root("SeaStack")
	_add_boulder(asset, "Base", Vector3(0, 0.55, 0), Vector3(2.6, 1.15, 2.2), 0.5, "rock_cliff")
	_add_boulder(asset, "Spire", Vector3(0.18, 2.15, -0.10), Vector3(1.45, 3.25, 1.25), 1.6, "rock_sunlit")
	return asset


func _build_extended_nature() -> void:
	_save_scene("nature/tree_base_c", _make_tree_c())
	_save_scene("nature/bush_medium", _make_bush_medium())
	_save_scene("nature/flower_white", _make_flower_cluster("FlowerWhite", "flower_white"))
	_save_scene("nature/flower_yellow", _make_flower_cluster("FlowerYellow", "flower_yellow"))
	_save_scene("nature/flower_purple", _make_flower_cluster("FlowerPurple", "flower_purple"))
	_save_scene("nature/coastal_plant", _make_coastal_plant("CoastalPlant", false))
	_save_scene("nature/reed_cluster", _make_coastal_plant("ReedCluster", true))
	_save_scene("nature/long_log", _make_log("LongLog", 3.6))
	_save_scene("nature/short_log", _make_log("ShortLog", 2.2))
	_save_scene("nature/stump", _make_stump())
	_save_scene("nature/driftwood", _make_driftwood())
	_save_scene("nature/rock_large", _make_large_rock())


func _make_tree_c() -> Node3D:
	var asset := _new_root("TreeBaseC")
	_add_taper(asset, "Trunk", Vector3(0, 1.65, 0), 0.24, 0.43, 3.3, "wood_dark", Vector3.ZERO, 7)
	for index in range(4):
		var y := 1.75 + index * 0.65
		var radius := 1.35 - index * 0.19
		_add_taper(asset, "PineTier%d" % index, Vector3(0, y, 0), 0.10, radius, 1.25, "grass_foliage_dark" if index % 2 == 0 else "grass_foliage_light", Vector3.ZERO, 8)
	_add_box_collision(asset, "TrunkCollision", Vector3(0, 1.35, 0), Vector3(0.64, 2.7, 0.64))
	return asset


func _make_bush_medium() -> Node3D:
	var asset := _new_root("BushMedium")
	for data in [[-0.65, 0.48, 0.0, 1.1], [0.15, 0.68, -0.08, 1.35], [0.72, 0.48, 0.12, 1.0], [-0.08, 0.42, 0.62, 0.86], [0.10, 0.38, -0.63, 0.82]]:
		_add_blob(asset, "LeafMass", Vector3(data[0], data[1], data[2]), Vector3(data[3], data[3] * 0.78, data[3] * 0.92), "grass_foliage_light" if data[0] > 0.3 else "grass_foliage_dark", data[0] * 2.0)
	return asset


func _make_flower_cluster(node_name: String, flower_material: String) -> Node3D:
	var asset := _new_root(node_name)
	for index in range(7):
		var angle := TAU * float(index) / 7.0
		var radius := 0.18 + float(index % 3) * 0.13
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		_add_prism(asset, "Stem%d" % index, Vector3(x, 0.23 + (index % 2) * 0.07, z), Vector3(0.06, 0.45, 0.08), "grass_foliage_dark", Vector3(0, angle, 0.10))
		_add_blob(asset, "Bloom%d" % index, Vector3(x, 0.50 + (index % 2) * 0.08, z), Vector3(0.16, 0.12, 0.16), flower_material, angle)
	return asset


func _make_coastal_plant(node_name: String, reeds: bool) -> Node3D:
	var asset := _new_root(node_name)
	for index in range(8):
		var x := -0.55 + index * 0.16
		var height := 0.62 + (index % 3) * 0.24
		_add_prism(asset, "Blade%d" % index, Vector3(x, height * 0.5, sin(index * 1.7) * 0.22), Vector3(0.10, height, 0.16), "grass_foliage_light" if index % 2 == 0 else "grass_foliage_dark", Vector3(0, index * 0.38, (-0.14 + index * 0.035)))
		if reeds and index % 2 == 0:
			_add_taper(asset, "Cattail%d" % index, Vector3(x, height + 0.12, sin(index * 1.7) * 0.22), 0.06, 0.075, 0.34, "wood_dark", Vector3.ZERO, 6)
	return asset


func _make_log(node_name: String, length: float) -> Node3D:
	var asset := _new_root(node_name)
	_add_taper(asset, "Log", Vector3(0, 0.34, 0), 0.35, 0.48, length, "wood", Vector3(0, 0, PI * 0.5), 8)
	_add_taper(asset, "DarkEnd", Vector3(-length * 0.5, 0.34, 0), 0.31, 0.31, 0.06, "wood_dark", Vector3(0, 0, PI * 0.5), 8)
	_add_box_collision(asset, "SimpleCollision", Vector3(0, 0.34, 0), Vector3(length, 0.68, 0.72))
	return asset


func _make_stump() -> Node3D:
	var asset := _new_root("Stump")
	_add_taper(asset, "StumpBody", Vector3(0, 0.55, 0), 0.68, 0.82, 1.1, "wood_dark", Vector3.ZERO, 8)
	_add_taper(asset, "CutTop", Vector3(0, 1.11, 0), 0.61, 0.61, 0.08, "wood", Vector3.ZERO, 8)
	_add_box_collision(asset, "SimpleCollision", Vector3(0, 0.52, 0), Vector3(1.25, 1.04, 1.25))
	return asset


func _make_driftwood() -> Node3D:
	var asset := _new_root("Driftwood")
	_add_taper(asset, "Main", Vector3(0, 0.25, 0), 0.16, 0.27, 3.4, "building_plaster", Vector3(0, 0, PI * 0.5), 7)
	_add_taper(asset, "ForkA", Vector3(0.85, 0.47, 0.0), 0.09, 0.18, 1.4, "building_plaster", Vector3(0, 0, -0.78), 7)
	_add_taper(asset, "ForkB", Vector3(-0.55, 0.38, 0.0), 0.08, 0.16, 1.05, "building_plaster", Vector3(0, 0, 0.72), 7)
	return asset


func _build_extended_village_ruins() -> void:
	_save_scene("village_ruin/window_wall", _make_window_wall())
	_save_scene("village_ruin/building_corner", _make_building_corner())
	_save_scene("village_ruin/gable", _make_gable())
	_save_scene("village_ruin/porch", _make_porch())
	_save_scene("village_ruin/stairs", _make_village_stairs())
	_save_scene("village_ruin/foundation", _make_foundation())
	_save_scene("village_ruin/fence_gate", _make_fence_gate())
	_save_scene("village_ruin/fence_end", _make_fence_end(false))
	_save_scene("village_ruin/fence_broken", _make_fence_end(true))
	_save_scene("village_ruin/ruin_corner", _make_ruin_corner())
	_save_scene("village_ruin/ruin_column", _make_ruin_column(false))
	_save_scene("village_ruin/ruin_broken_column", _make_ruin_column(true))
	_save_scene("village_ruin/ruin_rubble", _make_ruin_rubble())
	_save_scene("village_ruin/sign", _make_sign())
	_save_scene("village_ruin/lantern", _make_lantern())
	_save_scene("village_ruin/banner", _make_banner())
	_save_scene("village_ruin/crate", _make_crate())
	_save_scene("village_ruin/barrel", _make_barrel())
	_save_scene("village_ruin/rope", _make_rope())
	_save_scene("village_ruin/fishing_rack", _make_fishing_rack())
	_save_scene("village_ruin/dock", _make_dock())
	_save_scene("village_ruin/watchtower", _make_watchtower())


func _make_window_wall() -> Node3D:
	var asset := _new_root("WindowWall")
	_add_box(asset, "Plaster", Vector3(0, 1.45, 0), Vector3(4, 2.9, 0.34), "building_plaster")
	_add_box(asset, "StoneBase", Vector3(0, 0.28, -0.02), Vector3(4.1, 0.56, 0.46), "stone")
	for x in [-1.82, 1.82]: _add_box(asset, "Frame", Vector3(x, 1.55, -0.22), Vector3(0.26, 3.1, 0.28), "wood_dark")
	for y in [0.86, 2.2]: _add_box(asset, "Frame", Vector3(0, y, -0.22), Vector3(4.0, 0.23, 0.28), "wood")
	_add_box(asset, "WindowDark", Vector3(0, 1.52, -0.23), Vector3(1.30, 1.18, 0.08), "grass_foliage_dark")
	_add_box(asset, "MullionV", Vector3(0, 1.52, -0.29), Vector3(0.10, 1.34, 0.12), "wood")
	_add_box(asset, "MullionH", Vector3(0, 1.52, -0.29), Vector3(1.42, 0.10, 0.12), "wood")
	_add_box_collision(asset, "WallCollision", Vector3(0, 1.45, 0), Vector3(4, 2.9, 0.38))
	return asset


func _make_building_corner() -> Node3D:
	var asset := _new_root("BuildingCorner")
	_add_box(asset, "Post", Vector3(0, 1.55, 0), Vector3(0.42, 3.1, 0.42), "wood_dark")
	_add_box(asset, "StoneFoot", Vector3(0, 0.25, 0), Vector3(0.62, 0.5, 0.62), "stone")
	return asset


func _make_gable() -> Node3D:
	var asset := _new_root("Gable")
	_add_prism(asset, "PlasterGable", Vector3(0, 0.95, 0), Vector3(4, 1.9, 0.34), "building_plaster", Vector3(0, PI * 0.5, 0))
	_add_box(asset, "Beam", Vector3(0, 0.18, -0.2), Vector3(4.1, 0.24, 0.28), "wood_dark")
	_add_box(asset, "BraceL", Vector3(-1.0, 0.70, -0.22), Vector3(2.15, 0.20, 0.25), "wood", Vector3(0, 0, 0.55))
	_add_box(asset, "BraceR", Vector3(1.0, 0.70, -0.22), Vector3(2.15, 0.20, 0.25), "wood", Vector3(0, 0, -0.55))
	return asset


func _make_porch() -> Node3D:
	var asset := _new_root("Porch")
	for index in range(5): _add_box(asset, "Plank%d" % index, Vector3(-1.6 + index * 0.8, 0.23, 0), Vector3(0.68, 0.18, 2.2), "wood")
	for x in [-1.8, 1.8]:
		_add_box(asset, "Post", Vector3(x, 0.65, 0), Vector3(0.28, 1.3, 0.28), "wood_dark")
	_add_box_collision(asset, "DeckCollision", Vector3(0, 0.23, 0), Vector3(4, 0.28, 2.2))
	return asset


func _make_village_stairs() -> Node3D:
	var asset := _new_root("VillageStairs")
	for index in range(3): _add_box(asset, "Step%d" % index, Vector3(0, 0.14 + index * 0.22, 0.65 - index * 0.42), Vector3(1.75, 0.28, 0.58), "stone")
	_add_box_collision(asset, "SlopeCollision", Vector3(0, 0.36, 0.2), Vector3(1.7, 0.22, 1.65), Vector3(-0.42, 0, 0))
	return asset


func _make_foundation() -> Node3D:
	var asset := _new_root("Foundation")
	_add_box(asset, "StoneFoundation", Vector3(0, 0.30, 0), Vector3(4.2, 0.6, 4.2), "stone")
	_add_box(asset, "FloorCap", Vector3(0, 0.63, 0), Vector3(4.0, 0.08, 4.0), "wood")
	_add_box_collision(asset, "Collision", Vector3(0, 0.30, 0), Vector3(4.2, 0.6, 4.2))
	return asset


func _make_fence_gate() -> Node3D:
	var asset := _new_root("FenceGate")
	for x in [-1.75, 1.75]:
		_add_taper(asset, "Post", Vector3(x, 1.0, 0), 0.22, 0.31, 2.0, "wood_dark", Vector3.ZERO, 6)
		_add_box(asset, "MetalBand", Vector3(x, 1.35, -0.02), Vector3(0.42, 0.16, 0.42), "metal")
	for y in [0.58, 1.35]: _add_box(asset, "GateRail", Vector3(0, y, 0), Vector3(3.1, 0.20, 0.20), "wood", Vector3(0, 0, -0.08 if y < 1 else 0.08))
	_add_box(asset, "Brace", Vector3(0, 0.98, 0.02), Vector3(3.15, 0.18, 0.18), "wood_dark", Vector3(0, 0, 0.42))
	return asset


func _make_fence_end(broken: bool) -> Node3D:
	var asset := _new_root("FenceBroken" if broken else "FenceEnd")
	_add_taper(asset, "Post", Vector3(-1.55, 0.92, 0), 0.22, 0.30, 1.84, "wood_dark", Vector3.ZERO, 6)
	var length := 2.0 if broken else 3.0
	for y in [0.58, 1.30]: _add_box(asset, "Rail", Vector3(-0.55, y, 0), Vector3(length, 0.18, 0.18), "wood", Vector3(0, 0, (0.18 if broken else 0.02)))
	return asset


func _make_ruin_corner() -> Node3D:
	var asset := _new_root("RuinCorner")
	for i in range(4):
		_add_stone_block(asset, "StoneA%d" % i, Vector3(-1.45 + i * 0.92, 0.36 + (i % 2) * 0.07, 0), Vector3(0.82, 0.68, 0.72), i * 0.9)
		_add_stone_block(asset, "StoneB%d" % i, Vector3(0, 0.36 + (i % 2) * 0.06, -1.45 + i * 0.92), Vector3(0.72, 0.68, 0.82), i * 1.3)
	for i in range(3):
		_add_stone_block(asset, "UpperA%d" % i, Vector3(-1.0 + i * 0.92, 1.05, 0), Vector3(0.84, 0.68, 0.72), 2.0 + i)
		_add_stone_block(asset, "UpperB%d" % i, Vector3(0, 1.05, -1.0 + i * 0.92), Vector3(0.72, 0.68, 0.84), 3.0 + i)
	return asset


func _make_ruin_column(broken: bool) -> Node3D:
	var asset := _new_root("RuinBrokenColumn" if broken else "RuinColumn")
	var count := 3 if broken else 5
	for index in range(count): _add_stone_block(asset, "Course%d" % index, Vector3(0, 0.34 + index * 0.66, 0), Vector3(0.82 - (index % 2) * 0.05, 0.64, 0.82), index * 0.8, Vector3(0, index * 0.11, 0))
	_add_box_collision(asset, "SimpleCollision", Vector3(0, count * 0.33, 0), Vector3(0.72, count * 0.66, 0.72))
	return asset


func _make_ruin_rubble() -> Node3D:
	var asset := _new_root("RuinRubble")
	for index in range(7):
		var angle := index * 1.7
		_add_boulder(asset, "Rubble%d" % index, Vector3(cos(angle) * (0.45 + index * 0.10), 0.12 + (index % 3) * 0.08, sin(angle) * (0.35 + index * 0.08)), Vector3(0.38 + (index % 2) * 0.22, 0.28 + (index % 3) * 0.12, 0.42), angle, "stone" if index % 2 == 0 else "rock_sunlit")
	return asset


func _make_sign() -> Node3D:
	var asset := _new_root("Sign")
	_add_taper(asset, "Post", Vector3(0, 1.0, 0), 0.16, 0.23, 2.0, "wood_dark", Vector3.ZERO, 6)
	_add_box(asset, "Board", Vector3(0.55, 1.55, 0), Vector3(1.45, 0.55, 0.18), "wood", Vector3(0, 0, -0.06))
	_add_box(asset, "Arrow", Vector3(1.30, 1.55, 0), Vector3(0.42, 0.24, 0.20), "wood", Vector3(0, 0, 0.78))
	return asset


func _make_lantern() -> Node3D:
	var asset := _new_root("Lantern")
	_add_taper(asset, "Post", Vector3(0, 1.25, 0), 0.18, 0.26, 2.5, "wood_dark", Vector3.ZERO, 6)
	_add_box(asset, "Arm", Vector3(0.45, 2.24, 0), Vector3(1.0, 0.16, 0.18), "wood")
	_add_box(asset, "LanternFrame", Vector3(0.82, 1.82, 0), Vector3(0.42, 0.58, 0.42), "metal")
	_add_box(asset, "Glow", Vector3(0.82, 1.82, 0), Vector3(0.27, 0.40, 0.27), "flower_yellow")
	return asset


func _make_banner() -> Node3D:
	var asset := _new_root("Banner")
	_add_taper(asset, "Post", Vector3(0, 1.35, 0), 0.16, 0.24, 2.7, "wood_dark", Vector3.ZERO, 6)
	_add_box(asset, "Crossbar", Vector3(0.52, 2.35, 0), Vector3(1.25, 0.14, 0.16), "wood")
	_add_box(asset, "Fabric", Vector3(0.62, 1.72, 0.02), Vector3(0.82, 1.18, 0.08), "fabric_blue")
	_add_prism(asset, "FabricTail", Vector3(0.62, 1.02, 0.02), Vector3(0.82, 0.38, 0.08), "fabric_blue", Vector3(0, PI * 0.5, 0))
	return asset


func _make_crate() -> Node3D:
	var asset := _new_root("Crate")
	_add_box(asset, "Body", Vector3(0, 0.55, 0), Vector3(1.1, 1.1, 1.1), "wood")
	for y in [0.08, 1.02]: _add_box(asset, "Band", Vector3(0, y, -0.57), Vector3(1.22, 0.14, 0.10), "wood_dark")
	_add_box(asset, "BraceA", Vector3(0, 0.55, -0.59), Vector3(1.28, 0.13, 0.10), "wood_dark", Vector3(0, 0, 0.72))
	_add_box(asset, "BraceB", Vector3(0, 0.55, -0.60), Vector3(1.28, 0.13, 0.10), "wood_dark", Vector3(0, 0, -0.72))
	_add_box_collision(asset, "Collision", Vector3(0, 0.55, 0), Vector3(1.1, 1.1, 1.1))
	return asset


func _make_barrel() -> Node3D:
	var asset := _new_root("Barrel")
	_add_taper(asset, "Body", Vector3(0, 0.68, 0), 0.55, 0.48, 1.36, "wood", Vector3.ZERO, 10)
	for y in [0.22, 0.68, 1.14]: _add_taper(asset, "Band", Vector3(0, y, 0), 0.57, 0.57, 0.10, "metal", Vector3.ZERO, 10)
	_add_box_collision(asset, "Collision", Vector3(0, 0.68, 0), Vector3(0.95, 1.36, 0.95))
	return asset


func _make_rope() -> Node3D:
	var asset := _new_root("Rope")
	for index in range(4): _add_taper(asset, "Coil%d" % index, Vector3(0, 0.12 + index * 0.07, 0), 0.62 - index * 0.08, 0.62 - index * 0.08, 0.08, "rope", Vector3.ZERO, 12)
	return asset


func _make_fishing_rack() -> Node3D:
	var asset := _new_root("FishingRack")
	for x in [-1.5, 1.5]: _add_taper(asset, "Post", Vector3(x, 1.1, 0), 0.16, 0.24, 2.2, "wood_dark", Vector3.ZERO, 6)
	_add_box(asset, "Crossbar", Vector3(0, 2.05, 0), Vector3(3.45, 0.18, 0.20), "wood")
	for index in range(4):
		_add_taper(asset, "Rope%d" % index, Vector3(-0.9 + index * 0.6, 1.55, 0), 0.025, 0.025, 0.9, "rope", Vector3.ZERO, 5)
		_add_prism(asset, "Fish%d" % index, Vector3(-0.9 + index * 0.6, 1.02, 0), Vector3(0.22, 0.48, 0.12), "metal", Vector3(0, PI * 0.5, 0))
	return asset


func _make_dock() -> Node3D:
	var asset := _new_root("Dock")
	for index in range(7): _add_box(asset, "Plank%d" % index, Vector3(-1.8 + index * 0.6, 0.34, 0), Vector3(0.50, 0.18, 4.2), "wood")
	for x in [-1.95, 1.95]:
		for z in [-1.75, 1.75]: _add_taper(asset, "Post", Vector3(x, 0.18, z), 0.16, 0.24, 2.0, "wood_dark", Vector3.ZERO, 7)
	_add_box_collision(asset, "DeckCollision", Vector3(0, 0.34, 0), Vector3(4.2, 0.22, 4.2))
	return asset


func _make_watchtower() -> Node3D:
	var asset := _new_root("Watchtower")
	_add_box(asset, "StoneBase", Vector3(0, 1.15, 0), Vector3(2.8, 2.3, 2.8), "stone")
	for x in [-1.05, 1.05]:
		for z in [-1.05, 1.05]: _add_taper(asset, "TowerPost", Vector3(x, 3.2, z), 0.18, 0.28, 4.1, "wood_dark", Vector3.ZERO, 6)
	_add_box(asset, "Deck", Vector3(0, 4.95, 0), Vector3(3.9, 0.28, 3.9), "wood")
	for side in [-1.0, 1.0]:
		_add_box(asset, "Roof", Vector3(0, 6.15, side * 0.82), Vector3(4.5, 0.22, 2.15), "roof_terracotta", Vector3(side * 0.50, 0, 0))
	_add_box_collision(asset, "BaseCollision", Vector3(0, 1.15, 0), Vector3(2.8, 2.3, 2.8))
	return asset
