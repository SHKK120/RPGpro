extends "res://scripts/prototype/m04_green_coast.gd"

const REGION_GREEN_COAST := "green_coast"
const REGION_TWO := "region_2_prototype"
const REGION_TWO_ELEVATION := 8.0
const REGION_TWO_CENTER := Vector3(0.0, REGION_TWO_ELEVATION, 38.0)
const REGION_TWO_BOUNDS := Rect2(Vector2(-9.5, 30.0), Vector2(19.0, 16.0))
const REGION_TWO_ENTRY := Vector3(0.0, REGION_TWO_ELEVATION + 1.0, 44.2)
const GREEN_COAST_RETURN := Vector3(7.0, 1.0, 7.2)
const HOME_REGION_GATE := Vector3(10.8, 0.05, 6.4)
const REGION_TWO_RECIPE_COST := 3
const TERRAIN_WATER_MATERIAL := preload("res://assets/art/green_coast_v01/materials/water.tres")

var _current_region_id := REGION_GREEN_COAST
var _region_two_unlocked := false
var _region_two_discovered := false
var _region_two_ore := 0
var _region_two_collected: Dictionary = {}
var _homestead_region_two_unlocked := false
var _crafted_region_two_sample := false
var _coastal_theme_unlocked := false
var _selected_home_theme := "basic"
var _home_storage := {"wood": 0, "stone": 0, "monster_core": 0, "region2_ore": 0}
var _macro_first_skeleton_completed := false
var _macro_ready := false
var _macro_world: Node3D
var _region_two_world: Node3D
var _theme_visuals: Array[MeshInstance3D] = []
var _crafted_visual: Node3D
var _region_two_enemy: CharacterBody3D


func _ready() -> void:
	super._ready()
	_camera.call("set_follow_target_height", true)
	_setup_macro_world()
	_macro_ready = true
	_apply_macro_world_state()
	_apply_region_navigation_mode()
	var title := get_node_or_null("UI/StartMenu/Panel/VBox/Title") as Label
	if title != null:
		title.text = "RPGPRO · FIRST SKELETON"
	var subtitle := get_node_or_null("UI/StartMenu/Panel/VBox/Subtitle") as Label
	if subtitle != null:
		subtitle.text = "Home → Green Coast → Region 2 Prototype"
	_refresh_hud()


func _process(delta: float) -> void:
	super._process(delta)
	if not _macro_ready or _flow_mode != FlowMode.PLAY:
		return
	if _green_coast_first_loop_completed and not _region_two_unlocked:
		_region_two_unlocked = true
		_coastal_theme_unlocked = true
		_apply_macro_world_state()
		_save_after_change("Green Coast 완료: 거점의 새 지역 통로가 열렸습니다.")


func is_player_near_vista() -> bool:
	if _player == null:
		return false
	if _current_region_id == REGION_TWO:
		return _player.global_position.z <= REGION_TWO_CENTER.z - 6.7 and absf(_player.global_position.x - REGION_TWO_CENTER.x) <= 7.5
	return super.is_player_near_vista()


func _vista_transform() -> Transform3D:
	if _current_region_id == REGION_TWO:
		# From the northern highland rim, frame the real lower Green Coast rather
		# than a detached backdrop. Home, forest/plain and the sea share the scene.
		var overview_position := _player.global_position + Vector3(0, 9.0, 11.5)
		var lower_world_target := Vector3(0, 0.4, 3.0)
		return Transform3D(Basis.IDENTITY, overview_position).looking_at(lower_world_target, Vector3.UP)
	return super._vista_transform()


func _normal_camera_transform() -> Transform3D:
	if _current_region_id == REGION_TWO:
		var return_position := Vector3(
			_player.global_position.x + _normal_horizontal_offset.x,
			_player.global_position.y + 8.5,
			_player.global_position.z + _normal_horizontal_offset.y,
		)
		return Transform3D(_normal_camera_basis, return_position)
	return super._normal_camera_transform()


func _update_coast_edge_trigger() -> void:
	if _current_region_id == REGION_GREEN_COAST:
		super._update_coast_edge_trigger()
		return
	if _vista_state == VistaState.PLAY and is_player_near_vista():
		enter_vista()
	elif _vista_state == VistaState.VISTA:
		var left_edge := _player.global_position.z > REGION_TWO_CENTER.z - 5.8 or absf(_player.global_position.x - REGION_TWO_CENTER.x) > 7.5
		if left_edge:
			exit_vista()
		else:
			_camera.global_transform = _vista_transform()


func _setup_macro_world() -> void:
	_macro_world = Node3D.new()
	_macro_world.name = "MACRO01World"
	add_child(_macro_world)
	_build_continuous_terrain()
	_build_home_roles()
	_build_region_two()


func _build_continuous_terrain() -> void:
	var terrain := Node3D.new()
	terrain.name = "ContinuousTerrain"
	_macro_world.add_child(terrain)

	# Existing playable floors sit on this broad foundation. The slight height offset
	# prevents z-fighting while making the coast read as one continuous land mass.
	_add_visual_box(terrain, "GreenCoastFoundation", Vector3(0, -0.42, 5), Vector3(38, 0.8, 38), _combat_material(Color(0.30, 0.43, 0.25)))
	_add_visual_box(terrain, "PlainLowland", Vector3(4, -0.12, 20.5), Vector3(31, 0.22, 15), _combat_material(Color(0.36, 0.49, 0.28)))
	_add_visual_box(terrain, "ForestLowland", Vector3(-13.5, -0.10, 18), Vector3(12, 0.18, 19), _combat_material(Color(0.20, 0.36, 0.23)))
	_add_visual_box(terrain, "RockyApproach", Vector3(12.5, -0.08, 24), Vector3(15, 0.14, 10), ART_STONE_MATERIAL)

	# Water is deliberately lower than every walkable area. It is scenery, not a
	# destination surface, and spans far enough to remain visible from the highland.
	_add_visual_box(terrain, "NorthernSea", Vector3(0, -3.55, -32), Vector3(92, 0.12, 48), TERRAIN_WATER_MATERIAL)
	_add_visual_box(terrain, "WesternSea", Vector3(-35, -3.55, 14), Vector3(28, 0.12, 44), TERRAIN_WATER_MATERIAL)
	_add_visual_box(terrain, "EasternSea", Vector3(35, -3.55, 14), Vector3(28, 0.12, 44), TERRAIN_WATER_MATERIAL)

	# A few large, cheap silhouettes separate the biomes without building a new
	# terrain generator. They are generated once with the scene and have no collision.
	for index in range(7):
		var forest_x := -17.0 + float(index % 3) * 3.1
		var forest_z := 12.5 + float(index / 3) * 4.2
		_add_visual_box(terrain, "ForestCanopy%d" % index, Vector3(forest_x, 1.5, forest_z), Vector3(2.3, 3.0, 2.3), ART_LEAF_MATERIAL, float(index) * 0.37)
	for index in range(6):
		var rock_x := 7.0 + float(index % 3) * 4.1
		var rock_z := 20.5 + float(index / 3) * 4.8
		_add_visual_box(terrain, "RockySilhouette%d" % index, Vector3(rock_x, 0.65, rock_z), Vector3(1.5, 1.3 + float(index % 2) * 0.7, 1.7), ART_CLIFF_MATERIAL, float(index) * 0.28)


func _build_home_roles() -> void:
	var storage := _make_interactable("HomeStorage", "home_storage", Vector3(-4.8, 0.05, 7.7))
	_add_static_box(storage, "Chest", Vector3.ZERO, Vector3(1.35, 0.9, 0.85), ART_WOOD_MATERIAL)
	_add_label(storage, "STORAGE", Vector3(0, 1.25, 0))

	var progress := _make_interactable("RegionProgress", "region_progress", Vector3(5.1, 0.05, 7.8))
	_add_static_box(progress, "Board", Vector3.ZERO, Vector3(1.7, 1.55, 0.22), ART_WOOD_MATERIAL)
	_add_label(progress, "REGION MAP", Vector3(0, 1.25, 0))

	var theme := _make_interactable("ThemePoint", "home_theme", Vector3(-5.0, 0.05, 9.5))
	_add_static_box(theme, "Post", Vector3.ZERO, Vector3(0.32, 1.7, 0.32), ART_WOOD_MATERIAL)
	for side in [-1.0, 1.0]:
		var banner := _add_visual_box(theme, "Banner", Vector3(side * 0.38, 1.12, 0), Vector3(0.58, 0.9, 0.08), _combat_material(Color(0.36, 0.47, 0.42)))
		_theme_visuals.append(banner)
	_add_label(theme, "HOME THEME", Vector3(0, 1.9, 0))

	var gate := _make_interactable("RegionTwoGate", "region_two_gate", HOME_REGION_GATE)
	_add_static_box(gate, "LeftPost", Vector3(-0.9, 1.0, 0), Vector3(0.38, 2.0, 0.45), ART_RUIN_MATERIAL)
	_add_static_box(gate, "RightPost", Vector3(0.9, 1.0, 0), Vector3(0.38, 2.0, 0.45), ART_RUIN_MATERIAL)
	_add_visual_box(gate, "Lintel", Vector3(0, 2.0, 0), Vector3(2.2, 0.35, 0.5), ART_ACCENT_MATERIAL)
	_add_label(gate, "REGION 2", Vector3(0, 2.55, 0))
	for step in range(5):
		_add_visual_box(_macro_world, "RegionGatePath%d" % step, Vector3(7.7 + float(step) * 0.68, 0.045, 6.35), Vector3(0.56, 0.06, 0.82), ART_ACCENT_MATERIAL)

	var macro_bench := _make_interactable("RegionTwoWorkbench", "macro_workbench", Vector3(-1.2, 0.05, 10.1))
	_add_static_box(macro_bench, "Top", Vector3(0, 0.78, 0), Vector3(1.55, 0.18, 0.72), ART_WOOD_MATERIAL)
	_add_visual_box(macro_bench, "Blueprint", Vector3(0, 0.92, 0), Vector3(0.78, 0.05, 0.48), ART_ACCENT_MATERIAL)

	_crafted_visual = Node3D.new()
	_crafted_visual.name = "RegionTwoCraftedLamp"
	_crafted_visual.position = Vector3(2.1, 0.05, 9.3)
	_macro_world.add_child(_crafted_visual)
	_add_visual_box(_crafted_visual, "Base", Vector3(0, 0.18, 0), Vector3(0.65, 0.3, 0.65), ART_STONE_MATERIAL)
	_add_visual_box(_crafted_visual, "Stem", Vector3(0, 0.75, 0), Vector3(0.18, 1.15, 0.18), CHARACTER_METAL)
	_add_visual_box(_crafted_visual, "Light", Vector3(0, 1.42, 0), Vector3(0.62, 0.62, 0.62), ART_ACCENT_MATERIAL)


func _build_region_two() -> void:
	_region_two_world = Node3D.new()
	_region_two_world.name = "Region2Prototype"
	_macro_world.add_child(_region_two_world)
	_add_static_box(_region_two_world, "HighlandFloor", Vector3(0, REGION_TWO_ELEVATION - 0.25, 38), Vector3(20, 0.5, 18), _combat_material(Color(0.31, 0.39, 0.27)))

	# Collision remains at the rim, but its visible mesh is hidden. The visible rock
	# faces start at ground level and extend downward, so this reads as a drop rather
	# than a wall surrounding the player.
	var west_edge := _add_static_box(_region_two_world, "WestEdgeCollision", Vector3(-10.2, REGION_TWO_ELEVATION + 0.45, 38), Vector3(0.45, 1.4, 18), ART_CLIFF_MATERIAL)
	var east_edge := _add_static_box(_region_two_world, "EastEdgeCollision", Vector3(10.2, REGION_TWO_ELEVATION + 0.45, 38), Vector3(0.45, 1.4, 18), ART_CLIFF_MATERIAL)
	var north_edge := _add_static_box(_region_two_world, "NorthEdgeCollision", Vector3(0, REGION_TWO_ELEVATION + 0.45, 29.4), Vector3(20, 1.4, 0.45), ART_CLIFF_MATERIAL)
	var south_left_edge := _add_static_box(_region_two_world, "SouthLeftEdgeCollision", Vector3(-5.8, REGION_TWO_ELEVATION + 0.45, 46.6), Vector3(8.2, 1.4, 0.45), ART_CLIFF_MATERIAL)
	var south_right_edge := _add_static_box(_region_two_world, "SouthRightEdgeCollision", Vector3(5.8, REGION_TWO_ELEVATION + 0.45, 46.6), Vector3(8.2, 1.4, 0.45), ART_CLIFF_MATERIAL)
	for edge in [west_edge, east_edge, north_edge, south_left_edge, south_right_edge]:
		edge.visible = false
	_add_visual_box(_region_two_world, "WestCliffFace", Vector3(-10.0, REGION_TWO_ELEVATION - 4.0, 38), Vector3(1.0, 8.0, 18), ART_CLIFF_MATERIAL)
	_add_visual_box(_region_two_world, "EastCliffFace", Vector3(10.0, REGION_TWO_ELEVATION - 4.0, 38), Vector3(1.0, 8.0, 18), ART_CLIFF_MATERIAL)
	_add_visual_box(_region_two_world, "NorthCliffFace", Vector3(0, REGION_TWO_ELEVATION - 4.0, 29.6), Vector3(20, 8.0, 1.0), ART_CLIFF_MATERIAL)
	_add_visual_box(_region_two_world, "SouthLeftCliffFace", Vector3(-5.8, REGION_TWO_ELEVATION - 4.0, 46.4), Vector3(8.2, 8.0, 1.0), ART_CLIFF_MATERIAL)
	_add_visual_box(_region_two_world, "SouthRightCliffFace", Vector3(5.8, REGION_TWO_ELEVATION - 4.0, 46.4), Vector3(8.2, 8.0, 1.0), ART_CLIFF_MATERIAL)
	_build_region_two_navigation()

	for index in range(7):
		var z := 43.2 - float(index) * 1.75
		_add_visual_box(_region_two_world, "Path%d" % index, Vector3(0, REGION_TWO_ELEVATION + 0.04, z), Vector3(3.0, 0.08, 1.3), ART_SOIL_MATERIAL)
	for index in range(9):
		var x := -7.8 + float(index) * 2.0
		var z := 32.8 + sin(float(index) * 1.7) * 1.1
		_add_visual_box(_region_two_world, "WindStone%d" % index, Vector3(x, REGION_TWO_ELEVATION + 0.35, z), Vector3(0.7, 0.7 + float(index % 3) * 0.22, 0.65), ART_STONE_MATERIAL, float(index) * 0.31)

	var landmark := Node3D.new()
	landmark.name = "BrokenBeaconLandmark"
	landmark.position = Vector3(6.0, REGION_TWO_ELEVATION, 33.8)
	_region_two_world.add_child(landmark)
	_add_static_box(landmark, "Tower", Vector3.ZERO, Vector3(2.0, 5.2, 2.0), ART_RUIN_MATERIAL)
	_add_visual_box(landmark, "Beacon", Vector3(0, 3.0, 0), Vector3(2.8, 0.45, 2.8), ART_ACCENT_MATERIAL, 0.2)
	_add_label(landmark, "BROKEN BEACON", Vector3(0, 3.65, 0))

	_add_region_two_pickup("HighlandOre01", "r2_ore_01", Vector3(-5.0, REGION_TWO_ELEVATION + 0.22, 39.8))
	_add_region_two_pickup("HighlandOre02", "r2_ore_02", Vector3(-5.9, REGION_TWO_ELEVATION + 0.22, 37.0))
	_add_region_two_pickup("HighlandOre03", "r2_ore_03", Vector3(2.8, REGION_TWO_ELEVATION + 0.22, 36.3))
	_add_region_two_pickup("HighlandOre04", "r2_ore_04", Vector3(7.0, REGION_TWO_ELEVATION + 0.22, 39.2))

	var homestead := _make_interactable("HighlandHomestead", "region_two_homestead", Vector3(-7.0, REGION_TWO_ELEVATION + 0.05, 33.5))
	_add_static_box(homestead, "Foundation", Vector3.ZERO, Vector3(3.2, 0.22, 2.6), ART_STONE_MATERIAL)
	_add_visual_box(homestead, "Marker", Vector3(0, 0.85, 0), Vector3(0.22, 1.6, 0.22), ART_ACCENT_MATERIAL)
	_add_label(homestead, "HOMESTEAD SITE", Vector3(0, 1.9, 0))

	var future := Node3D.new()
	future.name = "FutureBossArea"
	future.position = Vector3(7.2, REGION_TWO_ELEVATION, 32.0)
	_region_two_world.add_child(future)
	_add_static_box(future, "SealedDoor", Vector3.ZERO, Vector3(4.2, 3.3, 0.7), ART_RUIN_MATERIAL)
	_add_visual_box(future, "Seal", Vector3(0, 1.7, -0.38), Vector3(1.0, 1.0, 0.12), ART_ACCENT_MATERIAL, 0.78, Vector3.FORWARD)

	var return_gate := _make_interactable("RegionTwoReturn", "region_two_return", Vector3(0.0, REGION_TWO_ELEVATION + 0.05, 45.0))
	_add_static_box(return_gate, "Left", Vector3(-0.82, 1.0, 0), Vector3(0.35, 2.0, 0.4), ART_RUIN_MATERIAL)
	_add_static_box(return_gate, "Right", Vector3(0.82, 1.0, 0), Vector3(0.35, 2.0, 0.4), ART_RUIN_MATERIAL)
	_add_label(return_gate, "HOME", Vector3(0, 2.2, 0))

	_region_two_enemy = _add_enemy("HighlandSentinel", Vector3(4.2, REGION_TWO_ELEVATION + 1.0, 39.2), {
		"display_name": "Highland Sentinel", "health": 96.0, "move_speed": 2.35,
		"damage": 20.0, "aggro_range": 7.5, "attack_range": 1.65,
		"windup": 0.78, "cooldown": 1.35, "leash": 8.0, "core_drop": 2,
		"elite": true, "scale": 1.08, "color": Color(0.46, 0.34, 0.58),
	})


func _build_region_two_navigation() -> void:
	var region := NavigationRegion3D.new()
	region.name = "Region2Navigation"
	var mesh := NavigationMesh.new()
	mesh.agent_radius = 0.55
	mesh.vertices = PackedVector3Array([
		Vector3(-9.5, REGION_TWO_ELEVATION, 30.0), Vector3(4.7, REGION_TWO_ELEVATION, 30.0),
		Vector3(4.7, REGION_TWO_ELEVATION, 35.0), Vector3(-9.5, REGION_TWO_ELEVATION, 35.0),
		Vector3(9.5, REGION_TWO_ELEVATION, 35.0), Vector3(9.5, REGION_TWO_ELEVATION, 46.0),
		Vector3(4.7, REGION_TWO_ELEVATION, 46.0), Vector3(-9.5, REGION_TWO_ELEVATION, 46.0),
	])
	mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	mesh.add_polygon(PackedInt32Array([3, 2, 6, 7]))
	mesh.add_polygon(PackedInt32Array([2, 4, 5, 6]))
	region.navigation_mesh = mesh
	_region_two_world.add_child(region)


func _make_interactable(node_name: String, kind: String, position: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	node.position = position
	node.set_meta("kind", kind)
	node.set_meta("active", true)
	_interactables.add_child(node)
	return node


func _add_region_two_pickup(node_name: String, pickup_id: String, position: Vector3) -> void:
	var pickup := _make_interactable(node_name, "region_two_ore", position)
	pickup.set_meta("pickup_id", pickup_id)
	_add_visual_box(pickup, "Ore", Vector3.ZERO, Vector3(0.52, 0.52, 0.52), _combat_material(Color(0.52, 0.35, 0.70), Color(0.18, 0.06, 0.32)), 0.62, Vector3(1, 1, 0).normalized())


func _add_label(parent: Node3D, text: String, position: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = position
	label.font_size = 28
	label.outline_size = 8
	label.modulate = Color(0.85, 0.95, 0.88)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)


func _interaction_label(target: Node3D) -> String:
	match String(target.get_meta("kind", "")):
		"home_storage":
			return "보관함 정리 (모두 넣기/꺼내기)"
		"region_progress":
			return "지역 진행 확인"
		"home_theme":
			return "Home 테마 변경" if _coastal_theme_unlocked else "Home 테마 (Green Coast 완료 필요)"
		"region_two_gate":
			return "Region 2로 이동" if _region_two_unlocked else "잠긴 지역 통로"
		"region_two_return":
			return "Home으로 귀환"
		"region_two_ore":
			return "Highland Ore 줍기"
		"region_two_homestead":
			return "새 집터 확인"
		"macro_workbench":
			return "Highland Lamp 확인" if _crafted_region_two_sample else "Highland Lamp 제작 (Ore 3)"
	return super._interaction_label(target)


func _has_interaction_line_of_sight(target: Node3D) -> bool:
	var macro_kind := String(target.get_meta("kind", ""))
	if macro_kind in ["home_storage", "region_progress", "home_theme", "region_two_gate", "region_two_return", "region_two_ore", "region_two_homestead", "macro_workbench"]:
		return true
	return super._has_interaction_line_of_sight(target)


func _interact_with_nearest() -> void:
	_update_nearest_interactable()
	if _nearest_interactable == null:
		return
	match String(_nearest_interactable.get_meta("kind", "")):
		"home_storage":
			_use_home_storage()
		"region_progress":
			_show_region_progress()
		"home_theme":
			_toggle_home_theme()
		"region_two_gate":
			_enter_region_two()
		"region_two_return":
			_return_home()
		"region_two_ore":
			_collect_region_two_ore(_nearest_interactable)
		"region_two_homestead":
			_discover_region_two_homestead()
		"macro_workbench":
			_craft_region_two_sample()
		_:
			super._interact_with_nearest()


func _use_home_storage() -> void:
	var has_player_items := _wood + _stone + _monster_core_count + _region_two_ore > 0
	if has_player_items:
		_home_storage["wood"] += _wood
		_home_storage["stone"] += _stone
		_home_storage["monster_core"] += _monster_core_count
		_home_storage["region2_ore"] += _region_two_ore
		_wood = 0
		_stone = 0
		_monster_core_count = 0
		_region_two_ore = 0
		_save_after_change("보유 자원을 Home Storage에 모두 넣었습니다.")
	else:
		_wood += int(_home_storage["wood"])
		_stone += int(_home_storage["stone"])
		_monster_core_count += int(_home_storage["monster_core"])
		_region_two_ore += int(_home_storage["region2_ore"])
		_home_storage = {"wood": 0, "stone": 0, "monster_core": 0, "region2_ore": 0}
		_save_after_change("Home Storage의 자원을 모두 꺼냈습니다.")


func _show_region_progress() -> void:
	_show_message("Green Coast: %s · Trophy: %s | Region 2: %s · Vista: %s · Homestead: %s" % [
		"완료" if _green_coast_first_loop_completed else "진행 중",
		"전시" if _boss_trophy_displayed else "미전시",
		"발견" if _region_two_discovered else ("해금" if _region_two_unlocked else "잠김"),
		"확인" if _vista_seen and _current_region_id == REGION_TWO else "미확인",
		"발견" if _homestead_region_two_unlocked else "미발견",
	], false)


func _toggle_home_theme() -> void:
	if not _coastal_theme_unlocked:
		_show_message("Green Coast 완결 결과를 먼저 확인하세요.", true)
		return
	_selected_home_theme = "coastal" if _selected_home_theme == "basic" else "basic"
	_apply_macro_world_state()
	_save_after_change("Home 테마를 %s로 바꿨습니다." % _selected_home_theme.capitalize())


func _enter_region_two() -> void:
	if not _region_two_unlocked:
		_show_message("Green Coast 완료 전에는 이 통로를 사용할 수 없습니다.", true)
		return
	_region_two_discovered = true
	_teleport_to_region(REGION_TWO, REGION_TWO_ENTRY)
	_save_after_change("Region 2 Prototype에 진입했습니다.")


func _return_home() -> void:
	_teleport_to_region(REGION_GREEN_COAST, GREEN_COAST_RETURN)
	_save_after_change("Home으로 돌아왔습니다.")


func _teleport_to_region(region_id: String, destination: Vector3) -> void:
	if _vista_state != VistaState.PLAY:
		exit_vista()
	_end_attack_visual()
	_clear_active_projectiles()
	_player.call("cancel_active_movement")
	var camera_offset := _camera.global_position - _player.global_position
	_player.global_position = destination
	_player.velocity = Vector3.ZERO
	_camera.global_position = destination + camera_offset
	_current_region_id = region_id
	_apply_region_navigation_mode()


func _apply_region_navigation_mode() -> void:
	if _player == null:
		return
	if _current_region_id == REGION_TWO:
		_player.call("set_click_destination_bounds", true, REGION_TWO_BOUNDS)
	else:
		_player.call("set_click_destination_bounds", true, Rect2(Vector2(-14.0, -11.5), Vector2(42.0, 23.0)))


func _collect_region_two_ore(target: Node3D) -> void:
	var pickup_id := String(target.get_meta("pickup_id", ""))
	if _region_two_collected.has(pickup_id):
		return
	_region_two_collected[pickup_id] = true
	_region_two_ore += 1
	target.visible = false
	target.set_meta("active", false)
	_save_after_change("Highland Ore +1")


func _discover_region_two_homestead() -> void:
	if _homestead_region_two_unlocked:
		_show_message("발견한 두 번째 집터입니다. 실제 이사는 이후 작업입니다.", false)
		return
	_homestead_region_two_unlocked = true
	_save_after_change("새로운 집터를 발견했습니다.")


func _craft_region_two_sample() -> void:
	if _crafted_region_two_sample:
		_show_message("Highland Lamp가 Home 고정 슬롯에 설치되어 있습니다.", false)
		return
	if _region_two_ore < REGION_TWO_RECIPE_COST:
		_show_message("Highland Ore %d개가 필요합니다." % REGION_TWO_RECIPE_COST, true)
		return
	_region_two_ore -= REGION_TWO_RECIPE_COST
	_crafted_region_two_sample = true
	_macro_first_skeleton_completed = _homestead_region_two_unlocked
	_apply_macro_world_state()
	_save_after_change("Highland Lamp를 제작해 Home에 설치했습니다.")


func _apply_macro_world_state() -> void:
	if not _macro_ready:
		return
	for child in _interactables.get_children():
		var target := child as Node3D
		if target == null:
			continue
		if String(target.get_meta("kind", "")) == "region_two_ore":
			var collected := _region_two_collected.has(String(target.get_meta("pickup_id", "")))
			target.visible = not collected
			target.set_meta("active", not collected)
	_crafted_visual.visible = _crafted_region_two_sample
	var theme_color := Color(0.20, 0.58, 0.62) if _selected_home_theme == "coastal" else Color(0.36, 0.47, 0.42)
	for visual in _theme_visuals:
		visual.material_override = _combat_material(theme_color)


func _current_objective() -> String:
	if not _green_coast_first_loop_completed:
		return super._current_objective()
	if not _region_two_discovered:
		return "Home의 청록색 Region Gate로 가세요."
	if _current_region_id == REGION_TWO:
		if _region_two_ore < REGION_TWO_RECIPE_COST:
			return "Landmark 주변에서 Highland Ore를 찾으세요."
		if not _homestead_region_two_unlocked:
			return "서쪽 높은 지대의 새 집터를 찾으세요."
		return "남쪽 통로로 Home에 돌아가 새 물건을 만드세요."
	if not _crafted_region_two_sample:
		return "Region 2 Workbench에서 Highland Lamp를 만드세요."
	return "첫 세계 골격 완료: 저장 후 Continue로 진행을 확인하세요."


func _refresh_hud() -> void:
	super._refresh_hud()
	if not _macro_ready:
		return
	var resource_label := get_node_or_null("UI/HUD/Stats/VBox/ResourceLabel") as Label
	if resource_label != null:
		resource_label.text += "   |   %s · Ore %d" % ["R2" if _current_region_id == REGION_TWO else "Home/R1", _region_two_ore]


func _reset_progress() -> void:
	super._reset_progress()
	_current_region_id = REGION_GREEN_COAST
	_region_two_unlocked = false
	_region_two_discovered = false
	_region_two_ore = 0
	_region_two_collected.clear()
	_homestead_region_two_unlocked = false
	_crafted_region_two_sample = false
	_coastal_theme_unlocked = false
	_selected_home_theme = "basic"
	_home_storage = {"wood": 0, "stone": 0, "monster_core": 0, "region2_ore": 0}
	_macro_first_skeleton_completed = false
	if _macro_ready:
		_apply_macro_world_state()
		_apply_region_navigation_mode()


func _save_game() -> bool:
	_update_first_loop_completion()
	if _green_coast_first_loop_completed:
		_region_two_unlocked = true
		_coastal_theme_unlocked = true
	if not super._save_game():
		return false
	var path := _save_path()
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parser.data
	data.merge({
		"current_region_id": _current_region_id,
		"region_2_unlocked": _region_two_unlocked,
		"region_2_discovered": _region_two_discovered,
		"region2_resource_count": _region_two_ore,
		"region2_resource_pickup_ids": _sorted_macro_ids(),
		"homestead_region2_unlocked": _homestead_region_two_unlocked,
		"crafted_region2_sample": _crafted_region_two_sample,
		"coastal_theme_unlocked": _coastal_theme_unlocked,
		"selected_home_theme": _selected_home_theme,
		"home_storage": _home_storage,
		"macro_first_skeleton_completed": _macro_first_skeleton_completed,
	}, true)
	var temp_path := path + ".macro.tmp"
	if not _write_text_file(temp_path, JSON.stringify(data, "\t")):
		return false
	if not _read_and_validate_save(temp_path).get("ok", false):
		return false
	if DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) != OK:
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) == OK


func _is_valid_save_dictionary(data: Dictionary) -> bool:
	if not super._is_valid_save_dictionary(data):
		return false
	if data.has("current_region_id") and not [REGION_GREEN_COAST, REGION_TWO].has(String(data["current_region_id"])):
		return false
	for key in ["region_2_unlocked", "region_2_discovered", "homestead_region2_unlocked", "crafted_region2_sample", "coastal_theme_unlocked", "macro_first_skeleton_completed"]:
		if data.has(key) and typeof(data[key]) != TYPE_BOOL:
			return false
	for key in ["region2_resource_count"]:
		if data.has(key) and (typeof(data[key]) != TYPE_INT and typeof(data[key]) != TYPE_FLOAT or int(data[key]) < 0):
			return false
	if data.has("region2_resource_pickup_ids") and typeof(data["region2_resource_pickup_ids"]) != TYPE_ARRAY:
		return false
	for pickup_id in data.get("region2_resource_pickup_ids", []):
		if typeof(pickup_id) != TYPE_STRING or not ["r2_ore_01", "r2_ore_02", "r2_ore_03", "r2_ore_04"].has(String(pickup_id)):
			return false
	if data.has("selected_home_theme") and not ["basic", "coastal"].has(String(data["selected_home_theme"])):
		return false
	if data.has("home_storage") and typeof(data["home_storage"]) != TYPE_DICTIONARY:
		return false
	var stored: Dictionary = data.get("home_storage", {})
	for storage_key in ["wood", "stone", "monster_core", "region2_ore"]:
		var stored_value: Variant = stored.get(storage_key, 0)
		if (typeof(stored_value) != TYPE_INT and typeof(stored_value) != TYPE_FLOAT) or int(stored_value) < 0:
			return false
	var unlocked := bool(data.get("region_2_unlocked", false))
	var discovered := bool(data.get("region_2_discovered", false))
	if discovered and not unlocked:
		return false
	if String(data.get("current_region_id", REGION_GREEN_COAST)) == REGION_TWO and (not unlocked or not discovered):
		return false
	if String(data.get("selected_home_theme", "basic")) == "coastal" and not bool(data.get("coastal_theme_unlocked", false)):
		return false
	if bool(data.get("macro_first_skeleton_completed", false)) and (not bool(data.get("crafted_region2_sample", false)) or not bool(data.get("homestead_region2_unlocked", false))):
		return false
	return true


func _apply_loaded_data(data: Dictionary) -> void:
	super._apply_loaded_data(data)
	_current_region_id = String(data.get("current_region_id", REGION_GREEN_COAST))
	_region_two_unlocked = bool(data.get("region_2_unlocked", _green_coast_first_loop_completed))
	_region_two_discovered = bool(data.get("region_2_discovered", false))
	_region_two_ore = int(data.get("region2_resource_count", 0))
	_region_two_collected.clear()
	for pickup_id in data.get("region2_resource_pickup_ids", []):
		_region_two_collected[String(pickup_id)] = true
	_homestead_region_two_unlocked = bool(data.get("homestead_region2_unlocked", false))
	_crafted_region_two_sample = bool(data.get("crafted_region2_sample", false))
	_coastal_theme_unlocked = bool(data.get("coastal_theme_unlocked", _green_coast_first_loop_completed))
	_selected_home_theme = String(data.get("selected_home_theme", "basic"))
	var loaded_storage: Dictionary = data.get("home_storage", {})
	_home_storage = {
		"wood": int(loaded_storage.get("wood", 0)), "stone": int(loaded_storage.get("stone", 0)),
		"monster_core": int(loaded_storage.get("monster_core", 0)), "region2_ore": int(loaded_storage.get("region2_ore", 0)),
	}
	_macro_first_skeleton_completed = bool(data.get("macro_first_skeleton_completed", false))
	if _macro_ready:
		_apply_macro_world_state()
		_apply_region_navigation_mode()


func _sorted_macro_ids() -> Array:
	var ids := _region_two_collected.keys()
	ids.sort()
	return ids


func get_macro_snapshot() -> Dictionary:
	return {
		"current_region_id": _current_region_id,
		"region_two_unlocked": _region_two_unlocked,
		"region_two_discovered": _region_two_discovered,
		"region_two_ore": _region_two_ore,
		"homestead_region_two_unlocked": _homestead_region_two_unlocked,
		"crafted_region_two_sample": _crafted_region_two_sample,
		"selected_home_theme": _selected_home_theme,
		"home_storage": _home_storage.duplicate(true),
		"macro_first_skeleton_completed": _macro_first_skeleton_completed,
		"blade_hitbox_present": is_instance_valid(_blade_hitbox),
	}
