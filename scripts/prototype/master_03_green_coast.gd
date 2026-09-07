extends "res://scripts/prototype/macro_01_game.gd"

const PROD_ROOT := "res://scenes/art/green_coast_prod_v01/"
const PROD_MATERIAL_ROOT := "res://assets/art/green_coast_prod_v01/materials/"

var _master_03_world: Node3D
var _master_03_bench: Node3D
var _master_03_display: Node3D
var _master_03_trophy: Node3D
var _master_03_region_gate: Node3D
var _master_03_water: MeshInstance3D
var _master_03_ready := false


func _ready() -> void:
	super._ready()
	_suppress_legacy_green_coast_visuals()
	_build_master_03_green_coast()
	_tune_master_03_lighting()
	_master_03_ready = true
	_apply_master_03_state()


func _process(delta: float) -> void:
	super._process(delta)
	if _master_03_water != null:
		_master_03_water.position.y = -1.32 + sin(Time.get_ticks_msec() * 0.00055) * 0.025


func _apply_progress_to_world() -> void:
	super._apply_progress_to_world()
	_apply_master_03_state()


func _apply_m04_world_state() -> void:
	super._apply_m04_world_state()
	_apply_master_03_state()


func _apply_macro_world_state() -> void:
	super._apply_macro_world_state()
	_apply_master_03_state()


func get_master_03_snapshot() -> Dictionary:
	return {
		"production_ready": _master_03_ready,
		"module_instances": _master_03_world.get_child_count() if _master_03_world != null else 0,
		"player_height": 2.0,
		"player_radius": 0.55,
		"nav_agent_radius": 0.75,
		"grid_connection": 4.0,
		"green_coast_bounds": Rect2(Vector2(-15.0, -12.0), Vector2(43.0, 24.0)),
	}


func _apply_master_03_state() -> void:
	if not _master_03_ready:
		return
	if _master_03_bench != null:
		_master_03_bench.visible = _bench_installed
	if _master_03_display != null:
		_master_03_display.visible = _souvenir_displayed
	if _master_03_trophy != null:
		_master_03_trophy.visible = _boss_trophy_displayed
	if _master_03_region_gate != null:
		_master_03_region_gate.visible = _region_two_unlocked


func _suppress_legacy_green_coast_visuals() -> void:
	var generated := get_node_or_null("GeneratedWorld") as Node3D
	if generated != null:
		generated.visible = false
	var sea := get_node_or_null("Sea") as MeshInstance3D
	if sea != null:
		sea.visible = false
	var floor_mesh := get_node_or_null("NavigationRegion3D/Floor/Mesh") as MeshInstance3D
	if floor_mesh != null:
		floor_mesh.visible = false

	var navigation_region := get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	if navigation_region != null:
		for child in navigation_region.get_children():
			var node := child as Node3D
			if node == null:
				continue
			var suppress := node.name == "Hut" or node.name.begins_with("Tree") or node.name.begins_with("Ruin") or node.name.begins_with("CoastRock") or node.name == "ForestRock" or node.name.begins_with("M04Arena") or node.name.begins_with("Pillar")
			if suppress:
				_hide_meshes(node)

	var continuous := get_node_or_null("MACRO01World/ContinuousTerrain") as Node3D
	if continuous != null:
		continuous.visible = false
	for node_path in [
		"MACRO01World/HomeStorage", "MACRO01World/RegionProgress", "MACRO01World/ThemePoint",
		"MACRO01World/RegionTwoGate", "MACRO01World/RegionTwoWorkbench",
		"Interactables/WeaponWorkbench", "Interactables/RestPoint", "Interactables/BossTrophySlot",
	]:
		var legacy := get_node_or_null(node_path) as Node3D
		if legacy != null:
			_hide_meshes(legacy)

	var boss_world := get_node_or_null("M04BossWorld") as Node3D
	if boss_world != null:
		for child in boss_world.get_children():
			var node := child as Node3D
			if node == null:
				continue
			if node.name.begins_with("ArenaMark") or node.name.begins_with("ArenaEntranceFence") or node.name.begins_with("ArenaEntrance") or node.name == "RuinDepthPath" or node.name == "TideCrestDisplayed":
				_hide_meshes(node)


func _hide_meshes(root_node: Node) -> void:
	for mesh in root_node.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).visible = false
	if root_node is MeshInstance3D:
		(root_node as MeshInstance3D).visible = false


func _build_master_03_green_coast() -> void:
	_master_03_world = Node3D.new()
	_master_03_world.name = "MASTER03GreenCoastProduction"
	add_child(_master_03_world)
	_build_land_and_paths()
	_build_home_village()
	_build_forest_and_nature()
	_build_ruins_and_secret()
	_build_cliff_coast_and_vista()
	_build_boss_landmark()
	_build_terraced_route_frames()
	_build_route_dressing()
	_build_distant_coastal_layers()
	_replace_stateful_home_visuals()
	_tune_master_03_hud()


func _build_land_and_paths() -> void:
	var grass := load(PROD_MATERIAL_ROOT + "grass.tres") as Material
	var rock := load(PROD_MATERIAL_ROOT + "rock_cliff.tres") as Material
	_add_visual_box(_master_03_world, "GreenCoastGround", Vector3(0, -0.235, 0), Vector3(30, 0.46, 24), grass)
	_add_visual_box(_master_03_world, "BossGround", Vector3(21.35, -0.235, 2.5), Vector3(13, 0.46, 11), grass)
	_add_visual_box(_master_03_world, "LandMass", Vector3(6.5, -1.15, 0), Vector3(43, 1.9, 24), rock)

	# The old connected loop remains authoritative for navigation.  These pieces
	# make the main route, alternate return and arena approach visible.
	_add_path_segment("HomeToForest", Vector3(0, 0.01, 5.3), Vector3(-8, 0.01, 1.8), 1.0)
	_add_path_segment("ForestToRuin", Vector3(-8, 0.012, 1.8), Vector3(8, 0.012, -1.8), 1.0)
	_add_path_segment("RuinToVista", Vector3(8, 0.014, -1.8), Vector3(0, 0.014, -8.8), 1.0)
	_add_path_segment("ReturnShortcut", Vector3(0, 0.016, -8.8), Vector3(0, 0.016, 5.3), 0.70)
	_add_path_segment("ArenaApproach", Vector3(12.7, 0.018, 2.5), Vector3(19.4, 0.018, 2.5), 1.15)


func _add_path_segment(node_name: String, from: Vector3, to: Vector3, width_scale: float) -> void:
	var delta := to - from
	var length := delta.length()
	var pieces := maxi(1, ceili(length / 3.25))
	for index in range(pieces):
		var t := (float(index) + 0.5) / float(pieces)
		var position := from.lerp(to, t)
		var module := _instance_prod("terrain/path_irregular", "%s_%02d" % [node_name, index], position, Vector3(0, atan2(delta.x, delta.z), 0), Vector3(width_scale, 1, length / (4.0 * pieces) * 1.08))
		if index % 2 == 1:
			module.position.x += 0.08


func _build_home_village() -> void:
	# Cottage follows the existing solid hut footprint, so visuals and collision
	# read as one object without changing the proven play surface.
	_instance_prod("village_ruin/foundation", "CottageFoundation", Vector3(6.5, -0.03, 8.9), Vector3.ZERO, Vector3(1.25, 1, 0.78))
	_instance_prod("village_ruin/door_wall", "CottageFront", Vector3(6.5, 0.0, 7.28))
	_instance_prod("village_ruin/building_wall", "CottageBack", Vector3(6.5, 0.0, 10.50), Vector3(0, PI, 0))
	_instance_prod("village_ruin/window_wall", "CottageWest", Vector3(3.92, 0.0, 8.9), Vector3(0, PI * 0.5, 0), Vector3(0.82, 1, 1))
	_instance_prod("village_ruin/window_wall", "CottageEast", Vector3(9.08, 0.0, 8.9), Vector3(0, PI * 0.5, 0), Vector3(0.82, 1, 1))
	# RoofPiece ridge runs on local Z.  The cottage depth also runs on Z, so no
	# 90-degree yaw is applied here; the previous yaw visibly inverted the roof.
	_instance_prod("village_ruin/roof_piece", "CottageRoof", Vector3(6.5, 2.65, 8.9), Vector3.ZERO, Vector3(1.24, 1, 0.84))
	_instance_prod("village_ruin/porch", "CottagePorch", Vector3(6.5, 0.0, 6.78), Vector3.ZERO, Vector3(0.75, 1, 0.55))
	_instance_prod("village_ruin/stairs", "CottageSteps", Vector3(6.5, -0.02, 5.98), Vector3.ZERO, Vector3(0.75, 1, 0.75))

	# Small production yard: silhouettes, stateful roles and a readable exit gate.
	_instance_prod("village_ruin/fence_corner", "HomeFenceCorner", Vector3(-5.8, 0, 10.8))
	_instance_prod("village_ruin/fence_straight", "HomeFenceSouthA", Vector3(-1.8, 0, 10.8))
	_instance_prod("village_ruin/fence_straight", "HomeFenceSouthB", Vector3(2.2, 0, 10.8))
	_instance_prod("village_ruin/fence_gate", "HomeTrailGate", Vector3(0, 0, 5.8))
	_instance_prod("village_ruin/crate", "SupplyCrateA", Vector3(-5.35, 0, 7.65), Vector3(0, 0.24, 0))
	_instance_prod("village_ruin/crate", "SupplyCrateB", Vector3(-6.20, 0, 8.18), Vector3(0, -0.14, 0), Vector3(0.72, 0.72, 0.72))
	_instance_prod("village_ruin/barrel", "SupplyBarrel", Vector3(-4.35, 0, 8.25))
	_instance_prod("village_ruin/sign", "VillageSign", Vector3(3.0, 0, 5.3), Vector3(0, -0.45, 0))
	_instance_prod("village_ruin/lantern", "VillageLantern", Vector3(8.95, 0, 6.55), Vector3(0, PI, 0))
	_instance_prod("village_ruin/banner", "VillageBanner", Vector3(10.4, 0, 9.5), Vector3(0, -PI * 0.5, 0))


func _build_forest_and_nature() -> void:
	var legacy_tree_data := [
		["ForestTreeA", Vector3(-11.2, 0, 3.8), "nature/tree_base_a", 0.95, 0.2],
		["ForestTreeB", Vector3(-9.2, 0, 5.0), "nature/tree_base_b", 0.90, -0.5],
		["ForestTreeC", Vector3(-12.0, 0, 0.2), "nature/tree_base_c", 1.05, 0.0],
		["ForestTreeD", Vector3(-8.0, 0, -2.8), "nature/tree_base_a", 0.86, 1.0],
		["ForestTreeE", Vector3(-5.8, 0, 3.6), "nature/tree_base_b", 0.78, 0.4],
		["ForestTreeF", Vector3(-11.0, 0, -3.4), "nature/tree_base_c", 0.92, -0.2],
	]
	for data in legacy_tree_data:
		_instance_prod(data[2], data[0], data[1], Vector3(0, data[4], 0), Vector3.ONE * data[3])
	for data in [
		["EdgeTreeA", Vector3(-14.2, 0, 7.0), "nature/tree_base_a", 1.08],
		["EdgeTreeB", Vector3(-14.1, 0, -7.0), "nature/tree_base_c", 1.12],
		["EdgeTreeC", Vector3(-4.0, 0, -8.8), "nature/tree_base_b", 0.92],
	]:
		_instance_prod(data[2], data[0], data[1], Vector3(0, data[1].x * 0.07, 0), Vector3.ONE * data[3])
	for data in [
		[Vector3(-13.2, 0, 5.7), 1.0], [Vector3(-12.8, 0, -5.1), 0.86],
		[Vector3(-5.0, 0, 4.7), 0.72], [Vector3(-6.0, 0, -5.9), 0.82],
	]:
		_instance_prod("nature/bush_medium", "ForestBush", data[0], Vector3(0, data[0].z * 0.11, 0), Vector3.ONE * data[1])
	for data in [[Vector3(-7.3, 0, 4.2), "nature/flower_white"], [Vector3(-6.1, 0, 1.2), "nature/flower_yellow"], [Vector3(-11.9, 0, -1.1), "nature/flower_purple"], [Vector3(-4.5, 0, -6.6), "nature/grass_cluster"]]:
		_instance_prod(data[1], "GroundCover", data[0])
	_instance_prod("nature/long_log", "FallenLog", Vector3(-12.6, 0, 8.7), Vector3(0, -0.28, 0))
	_instance_prod("nature/stump", "ForestStump", Vector3(-6.0, 0, 6.7), Vector3(0, 0.2, 0), Vector3.ONE * 0.72)


func _build_ruins_and_secret() -> void:
	_instance_prod("village_ruin/ruin_wall", "RuinBackA", Vector3(7.1, 0, -4.85), Vector3.ZERO, Vector3(0.72, 1, 1))
	_instance_prod("village_ruin/ruin_wall", "RuinBackB", Vector3(10.2, 0, -4.85), Vector3.ZERO, Vector3(0.72, 0.86, 1))
	_instance_prod("village_ruin/ruin_corner", "RuinCornerWest", Vector3(5.75, 0, -3.05), Vector3(0, PI, 0), Vector3(0.82, 1, 0.82))
	_instance_prod("village_ruin/ruin_broken_column", "RuinColumnEast", Vector3(11.25, 0, -3.1), Vector3.ZERO, Vector3.ONE * 1.08)
	_instance_prod("village_ruin/ruin_arch", "SecretArch", Vector3(8.5, 0, -2.55), Vector3.ZERO, Vector3.ONE * 1.04)
	_instance_prod("village_ruin/ruin_rubble", "SecretRubbleA", Vector3(6.65, 0, -4.1), Vector3(0, 0.45, 0), Vector3.ONE * 0.78)
	_instance_prod("village_ruin/ruin_rubble", "SecretRubbleB", Vector3(10.7, 0, -4.0), Vector3(0, -0.3, 0), Vector3.ONE * 0.68)
	_instance_prod("nature/bush", "RuinOvergrowth", Vector3(12.4, 0, -5.1), Vector3.ZERO, Vector3.ONE * 0.68)
	_instance_prod("nature/flower_purple", "RuinFlowers", Vector3(6.1, 0, -1.6), Vector3.ZERO, Vector3.ONE * 0.85)
	_instance_prod("village_ruin/sign", "RuinTrailSign", Vector3(3.9, 0, -0.8), Vector3(0, 0.65, 0), Vector3.ONE * 0.9)


func _build_cliff_coast_and_vista() -> void:
	for index in range(8):
		var x := -14.0 + index * 4.0
		var path := "terrain/cliff_straight"
		if index == 0 or index == 7:
			path = "terrain/cliff_end_cap"
		_instance_prod(path, "NorthCliff%02d" % index, Vector3(x, -2.0, -11.92), Vector3.ZERO)
	for data in [[-14.6, -8.0, PI * 0.5], [-14.6, -4.0, PI * 0.5], [-14.6, 0.0, PI * 0.5], [-14.6, 4.0, PI * 0.5], [-14.6, 8.0, PI * 0.5]]:
		_instance_prod("terrain/cliff_straight", "WestCliff", Vector3(data[0], -2.0, data[1]), Vector3(0, data[2], 0))
	for index in range(8):
		_instance_prod("terrain/sand_to_water" if index % 2 == 0 else "terrain/rocky_beach", "Beach%02d" % index, Vector3(-14.0 + index * 4.0, -1.24, -15.8), Vector3.ZERO)
	for data in [[-10.8, -17.8, 0.8], [-4.5, -18.7, 1.2], [5.2, -18.2, 0.72], [11.8, -19.2, 1.05]]:
		_instance_prod("terrain/rock_large", "ShoreRock", Vector3(data[0], -1.16, data[1]), Vector3(0, data[0] * 0.08, 0), Vector3.ONE * data[2])
	_instance_prod("terrain/sea_stack", "VistaSeaStack", Vector3(10.5, -1.28, -26.5), Vector3(0, -0.3, 0), Vector3.ONE * 1.4)
	_instance_prod("terrain/sea_stack", "FarSeaStack", Vector3(-13.5, -1.45, -32.0), Vector3(0, 0.55, 0), Vector3.ONE * 0.9)
	_instance_prod("nature/driftwood", "BeachDriftwood", Vector3(-6.5, -1.10, -15.2), Vector3(0, 0.35, 0), Vector3.ONE * 0.9)
	_instance_prod("nature/reed_cluster", "CoastalReeds", Vector3(6.5, -1.08, -14.6), Vector3.ZERO, Vector3.ONE * 0.9)
	_instance_prod("village_ruin/dock", "FishingDock", Vector3(-10.5, -1.22, -18.1), Vector3.ZERO, Vector3(0.82, 0.82, 1.25))
	_instance_prod("village_ruin/fishing_rack", "FishingRack", Vector3(-10.5, -0.88, -16.1), Vector3.ZERO, Vector3.ONE * 0.72)
	_instance_prod("village_ruin/rope", "DockRope", Vector3(-8.8, -0.85, -16.1), Vector3.ZERO, Vector3.ONE * 0.72)

	var water_material := load(PROD_MATERIAL_ROOT + "shallow_water.tres") as Material
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(100, 70)
	water_mesh.subdivide_width = 30
	water_mesh.subdivide_depth = 20
	water_mesh.material = water_material
	_master_03_water = MeshInstance3D.new()
	_master_03_water.name = "CoastalSea"
	_master_03_water.mesh = water_mesh
	_master_03_water.position = Vector3(0, -1.32, -42)
	_master_03_world.add_child(_master_03_water)


func _build_boss_landmark() -> void:
	_instance_prod("terrain/combat_ground_wide", "BossArenaSurface", Vector3(23.0, 0.01, 2.5), Vector3(0, PI * 0.5, 0), Vector3(1.08, 1, 1.35))
	_instance_prod("village_ruin/ruin_arch", "ArenaGate", Vector3(15.0, 0, 2.5), Vector3(0, PI * 0.5, 0), Vector3(1.15, 1.18, 1.15))
	for data in [[18.2, -2.5], [22.4, -2.7], [26.5, -2.5], [18.2, 7.5], [22.4, 7.7], [26.5, 7.5]]:
		_instance_prod("village_ruin/ruin_wall", "ArenaRuinWall", Vector3(data[0], 0, data[1]), Vector3.ZERO, Vector3.ONE * 1.0)
	for data in [[27.6, -1.8], [27.6, 6.8], [18.0, -1.7], [18.0, 6.7]]:
		_instance_prod("village_ruin/ruin_column", "ArenaColumn", Vector3(data[0], 0, data[1]), Vector3.ZERO, Vector3.ONE * 0.86)
	_instance_prod("village_ruin/watchtower", "CoastWatchtower", Vector3(12.0, 0, -8.6), Vector3(0, -0.35, 0), Vector3.ONE * 0.78)
	_instance_prod("village_ruin/banner", "WatchtowerBanner", Vector3(13.0, 3.8, -8.4), Vector3(0, -0.35, 0), Vector3.ONE * 0.72)


func _build_route_dressing() -> void:
	# Dense but collision-free shoulders are the main visual correction from the
	# sparse first live pass.  They preserve the proven walkable corridor.
	var bushes := [
		Vector3(-2.2, 0, 5.0), Vector3(-4.0, 0, 4.2), Vector3(-6.2, 0, 2.9),
		Vector3(-7.4, 0, 0.4), Vector3(-5.5, 0, -1.2), Vector3(-2.8, 0, -2.8),
		Vector3(1.8, 0, -4.8), Vector3(4.0, 0, -4.0), Vector3(5.1, 0, -0.2),
		Vector3(9.8, 0, 0.7), Vector3(12.5, 0, -1.2), Vector3(11.8, 0, -7.0),
		Vector3(5.8, 0, -8.8), Vector3(-1.8, 0, -9.5), Vector3(-7.8, 0, -8.5),
	]
	for index in range(bushes.size()):
		var scene_name := "nature/bush_medium" if index % 3 == 0 else "nature/bush"
		var scale_value := 0.55 + float(index % 4) * 0.09
		_instance_prod(scene_name, "RouteBush%02d" % index, bushes[index], Vector3(0, index * 0.63, 0), Vector3.ONE * scale_value)

	var rock_positions := [
		Vector3(-3.1, 0, 3.8), Vector3(-5.4, 0, 2.0), Vector3(-3.9, 0, -1.7),
		Vector3(2.8, 0, -3.4), Vector3(4.6, 0, -1.8), Vector3(6.0, 0, 1.0),
		Vector3(10.8, 0, 1.7), Vector3(12.8, 0, -5.2), Vector3(8.3, 0, -8.6),
		Vector3(2.0, 0, -9.4), Vector3(-5.4, 0, -9.1), Vector3(-10.7, 0, -7.8),
	]
	for index in range(rock_positions.size()):
		var scene_name := "nature/rock_medium" if index % 4 == 0 else "nature/rock_small"
		_instance_prod(scene_name, "RouteRock%02d" % index, rock_positions[index], Vector3(0, index * 0.49, 0), Vector3.ONE * (0.52 + (index % 3) * 0.12))

	var flower_scenes := ["nature/flower_white", "nature/flower_yellow", "nature/flower_purple", "nature/grass_cluster"]
	var flower_positions := [
		Vector3(-1.5, 0, 4.6), Vector3(-3.5, 0, 4.8), Vector3(-5.1, 0, 3.0),
		Vector3(-6.9, 0, 0.8), Vector3(-4.7, 0, -0.7), Vector3(-2.0, 0, -3.0),
		Vector3(1.5, 0, -4.4), Vector3(3.8, 0, -3.5), Vector3(5.2, 0, 0.4),
		Vector3(10.3, 0, 1.2), Vector3(11.9, 0, -1.7), Vector3(10.9, 0, -6.8),
		Vector3(5.0, 0, -8.5), Vector3(-2.4, 0, -9.0), Vector3(-7.0, 0, -8.0),
		Vector3(-12.2, 0, -6.2), Vector3(-12.5, 0, 6.5), Vector3(3.4, 0, 5.3),
	]
	for index in range(flower_positions.size()):
		_instance_prod(flower_scenes[index % flower_scenes.size()], "RouteGroundCover%02d" % index, flower_positions[index], Vector3(0, index * 0.41, 0), Vector3.ONE * (0.62 + (index % 3) * 0.10))

	# Fence fragments frame the main road and coast without closing shortcuts.
	for data in [
		[Vector3(-4.5, 0, 3.6), -0.42, 0.82], [Vector3(-7.5, 0, 1.0), -1.35, 0.72],
		[Vector3(-2.8, 0, -3.6), -0.75, 0.72], [Vector3(3.0, 0, -5.0), -0.72, 0.74],
		[Vector3(6.8, 0, -0.1), 0.35, 0.70], [Vector3(-5.5, 0, -9.8), 0.0, 0.78],
		[Vector3(4.7, 0, -9.8), 0.0, 0.78],
	]:
		_instance_prod("village_ruin/fence_straight", "RouteFence", data[0], Vector3(0, data[1], 0), Vector3(data[2], 0.92, 0.92))

	# The target reads as a continuous coastal grove, not isolated specimen trees.
	# These collision-free crowns frame routes while leaving the proven navigation
	# corridor and combat sight lines untouched.
	var framing_trees := [
		[Vector3(-2.8, 0, 8.0), "nature/tree_base_a", 0.82, 0.30],
		[Vector3(-7.4, 0, 6.8), "nature/tree_base_b", 0.96, -0.55],
		[Vector3(-10.2, 0, 1.8), "nature/tree_base_a", 1.06, 0.18],
		[Vector3(-9.6, 0, -5.8), "nature/tree_base_c", 0.94, 0.0],
		[Vector3(-4.6, 0, -7.4), "nature/tree_base_b", 0.88, 0.62],
		[Vector3(1.8, 0, -7.9), "nature/tree_base_a", 0.78, -0.25],
		[Vector3(4.7, 0, 2.4), "nature/tree_base_a", 0.74, 0.52],
		[Vector3(10.8, 0, 5.8), "nature/tree_base_b", 0.82, -0.38],
		[Vector3(13.2, 0, -4.4), "nature/tree_base_c", 0.92, 0.0],
	]
	for index in range(framing_trees.size()):
		var data: Array = framing_trees[index]
		_instance_prod(data[1], "RouteTree%02d" % index, data[0], Vector3(0, data[3], 0), Vector3.ONE * data[2])


func _build_terraced_route_frames() -> void:
	# Raised non-walkable shelves establish the stepped island silhouette from the
	# latest Green Coast layout while the original flat navigation stays authoritative.
	var shelf_data := [
		[Vector3(-13.2, -2.0, 9.0), Vector3(1.25, 1.0, 1.25), 0.0],
		[Vector3(-13.2, -2.0, 5.0), Vector3(1.25, 1.0, 1.25), 0.0],
		[Vector3(-13.2, -2.0, 1.0), Vector3(1.25, 1.0, 1.25), 0.0],
		[Vector3(-13.2, -2.0, -3.0), Vector3(1.25, 1.0, 1.25), 0.0],
		[Vector3(-9.2, -2.0, -10.8), Vector3(1.18, 1.0, 1.12), 0.0],
		[Vector3(-5.2, -2.0, -10.8), Vector3(1.18, 1.0, 1.12), 0.0],
		[Vector3(6.8, -2.0, -10.8), Vector3(1.18, 1.0, 1.12), 0.0],
		[Vector3(10.8, -2.0, -10.8), Vector3(1.18, 1.0, 1.12), 0.0],
	]
	for index in range(shelf_data.size()):
		var data: Array = shelf_data[index]
		_instance_prod("terrain/cliff_plateau", "RouteShelf%02d" % index, data[0], Vector3(0, data[2], 0), data[1])
	# Hero-scale rock shoulders break the straight shelf seams and create layered
	# silhouettes at the path turns.
	for index in range(12):
		var angle := TAU * float(index) / 12.0
		var radius_x := 12.8 if index % 2 == 0 else 10.8
		var position := Vector3(cos(angle) * radius_x, -0.15, sin(angle) * 9.6)
		_instance_prod("terrain/rock_large", "TerraceShoulder%02d" % index, position, Vector3(0, angle * 0.7, 0), Vector3.ONE * (0.62 + float(index % 3) * 0.12))


func _build_distant_coastal_layers() -> void:
	# Build distant islands from several moderate modules.  The previous enormous
	# single scales flattened into green slabs and made sea stacks read as cones.
	var island_centers := [Vector3(-19, -2.0, -33), Vector3(2, -2.3, -40), Vector3(23, -2.1, -35)]
	for island_index in range(island_centers.size()):
		var center: Vector3 = island_centers[island_index]
		for piece_index in range(5):
			var offset := Vector3((piece_index - 2) * 3.3, (piece_index % 2) * 0.28, sin(piece_index * 1.7) * 2.0)
			var scale_value := Vector3(1.15 + (piece_index % 2) * 0.28, 0.88 + (piece_index % 3) * 0.12, 1.10 + ((piece_index + 1) % 2) * 0.25)
			_instance_prod("terrain/cliff_plateau", "DistantIsland%02d_%02d" % [island_index, piece_index], center + offset, Vector3(0, (piece_index - 2) * 0.16, 0), scale_value)
		for tree_index in range(3):
			var tree_position := center + Vector3((tree_index - 1) * 4.1, 2.0, -0.8 + tree_index * 0.75)
			_instance_prod("nature/tree_base_c", "DistantPine%02d_%02d" % [island_index, tree_index], tree_position, Vector3.ZERO, Vector3.ONE * (0.62 + tree_index * 0.10))
	for data in [
		[Vector3(-11, -1.25, -27), 0.72], [Vector3(11, -1.28, -29), 0.86],
		[Vector3(30, -1.32, -30), 0.68],
	]:
		_instance_prod("terrain/rock_large", "DistantSeaRock", data[0], Vector3(0, data[0].x * 0.03, 0), Vector3.ONE * data[1])


func _replace_stateful_home_visuals() -> void:
	_master_03_bench = _make_production_bench("InstalledBench", Vector3(-3.8, 0, 7.0))
	_master_03_display = _make_production_display("SouvenirDisplay", Vector3(2.8, 0, 7.0), false)
	_master_03_trophy = _make_production_display("TrophyDisplay", Vector3(0.8, 0, 8.25), true)
	_master_03_region_gate = _instance_prod("village_ruin/ruin_arch", "RegionTwoProductionGate", HOME_REGION_GATE, Vector3(0, PI * 0.5, 0), Vector3(0.75, 0.86, 0.75))
	_instance_prod("village_ruin/crate", "HomeStorageProduction", Vector3(-4.8, 0, 7.7), Vector3(0, 0.18, 0), Vector3(1.15, 0.9, 0.9))
	_instance_prod("village_ruin/sign", "RegionBoardProduction", Vector3(5.1, 0, 7.8), Vector3(0, PI * 0.5, 0), Vector3.ONE * 0.78)
	_instance_prod("village_ruin/banner", "ThemeProduction", Vector3(-5.0, 0, 9.5), Vector3.ZERO, Vector3.ONE * 0.76)
	_make_production_bench("WeaponWorkbenchProduction", Vector3(-1.2, 0, 8.4))
	_instance_prod("village_ruin/lantern", "RestLantern", Vector3(3.7, 0, 8.25), Vector3.ZERO, Vector3.ONE * 0.65)
	_make_production_bench("RegionWorkbenchProduction", Vector3(-1.2, 0, 10.1))


func _make_production_bench(node_name: String, position: Vector3) -> Node3D:
	var root_node := Node3D.new()
	root_node.name = node_name
	root_node.position = position
	_master_03_world.add_child(root_node)
	var wood := load(PROD_MATERIAL_ROOT + "wood.tres") as Material
	var dark := load(PROD_MATERIAL_ROOT + "wood_dark.tres") as Material
	_add_visual_box(root_node, "Top", Vector3(0, 0.86, 0), Vector3(1.65, 0.18, 0.76), wood)
	for x in [-0.62, 0.62]:
		_add_visual_box(root_node, "Leg", Vector3(x, 0.42, 0), Vector3(0.18, 0.84, 0.58), dark, -0.04 * x)
	_add_visual_box(root_node, "ToolRail", Vector3(0, 1.06, 0.30), Vector3(1.42, 0.18, 0.12), dark)
	return root_node


func _make_production_display(node_name: String, position: Vector3, trophy: bool) -> Node3D:
	var root_node := Node3D.new()
	root_node.name = node_name
	root_node.position = position
	_master_03_world.add_child(root_node)
	var stone := load(PROD_MATERIAL_ROOT + "stone.tres") as Material
	var accent := load(PROD_MATERIAL_ROOT + ("fabric_blue.tres" if trophy else "wet_sand.tres")) as Material
	_add_visual_box(root_node, "Pedestal", Vector3(0, 0.42, 0), Vector3(1.15, 0.84, 0.92), stone)
	for index in range(3 if trophy else 1):
		var prism := PrismMesh.new()
		prism.size = Vector3(0.22, 0.72 - index * 0.08, 0.22)
		prism.material = accent
		var crest := MeshInstance3D.new()
		crest.name = "Crest"
		crest.mesh = prism
		crest.position = Vector3((index - 1) * 0.28 if trophy else 0, 1.12, 0)
		crest.rotation_degrees.z = (index - 1) * -18.0 if trophy else 0.0
		root_node.add_child(crest)
	return root_node


func _instance_prod(relative_path: String, node_name: String, position: Vector3, rotation := Vector3.ZERO, scale := Vector3.ONE) -> Node3D:
	var packed := load(PROD_ROOT + relative_path + ".tscn") as PackedScene
	if packed == null:
		push_error("MASTER-03 missing production asset: " + relative_path)
		return Node3D.new()
	var instance := packed.instantiate() as Node3D
	instance.name = node_name
	instance.position = position
	instance.rotation = rotation
	instance.scale = scale
	_disable_instance_collision(instance)
	_master_03_world.add_child(instance)
	return instance


func _disable_instance_collision(root_node: Node) -> void:
	for body in root_node.find_children("*", "CollisionObject3D", true, false):
		var collision_object := body as CollisionObject3D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
	for shape in root_node.find_children("*", "CollisionShape3D", true, false):
		(shape as CollisionShape3D).disabled = true


func _tune_master_03_lighting() -> void:
	var world_environment := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_environment != null and world_environment.environment != null:
		world_environment.environment.background_color = Color("#75b8d0")
		world_environment.environment.ambient_light_color = Color("#f2dfbd")
		world_environment.environment.ambient_light_energy = 0.54
	var sun := get_node_or_null("Sun") as DirectionalLight3D
	if sun != null:
		sun.light_color = Color("#ffe1ab")
		sun.light_energy = 0.90
		sun.shadow_opacity = 0.48
	var fill := DirectionalLight3D.new()
	fill.name = "MASTER03CoolFill"
	fill.rotation_degrees = Vector3(-32, 148, 0)
	fill.light_color = Color("#86b7c2")
	fill.light_energy = 0.14
	fill.shadow_enabled = false
	add_child(fill)


func _tune_master_03_hud() -> void:
	# Keep gameplay information visible but give the world back more screen space.
	var stats := get_node_or_null("UI/HUD/Stats") as Control
	if stats != null:
		stats.offset_right = 650.0
	var resource_label := get_node_or_null("UI/HUD/Stats/VBox/ResourceLabel") as Label
	var objective_label := get_node_or_null("UI/HUD/Stats/VBox/ObjectiveLabel") as Label
	for label in [resource_label, objective_label]:
		if label != null:
			label.add_theme_font_size_override("font_size", 14)
	var hint := get_node_or_null("UI/HUD/PauseHint") as Label
	if hint != null:
		hint.offset_left = -330.0
		hint.add_theme_font_size_override("font_size", 13)
