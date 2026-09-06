extends "res://scripts/prototype/m03_green_coast.gd"

const BOSS_SCRIPT := preload("res://scripts/prototype/m04_boss.gd")
const BLADE_LEVEL_TWO_DAMAGE := 30.0
const ARENA_BOUNDS := Rect2(Vector2(17.15, -3.0), Vector2(10.8, 11.0))
const ARENA_ENTRANCE_X := 14.82
const ARENA_TRIGGER_X := 17.45
const BOSS_SPAWN := Vector3(23.0, 1.0, 2.5)
const BOSS_REWARD_POSITION := Vector3(23.0, 0.42, 4.7)

var _boss_defeated := false
var _boss_reward_claimed := false
var _boss_trophy_owned := false
var _boss_trophy_displayed := false
var _boss_growth_core_owned := false
var _green_coast_first_loop_completed := false
var _arena_discovered := false
var _boss_encounter_active := false
var _m04_ready := false

var _m04_world: Node3D
var _boss: CharacterBody3D
var _arena_access_gate: StaticBody3D
var _encounter_barrier: StaticBody3D
var _boss_reward: Node3D
var _boss_trophy_slot: Node3D
var _boss_trophy_visual: Node3D
var _boss_hud: PanelContainer
var _boss_name_label: Label
var _boss_health_bar: ProgressBar


func _ready() -> void:
	super._ready()
	var hints := find_children("PauseHint", "Label", true, false)
	if not hints.is_empty():
		var hint := hints[0] as Label
		hint.offset_left = -500.0
		hint.offset_top = 112.0
		hint.offset_right = -22.0
		hint.offset_bottom = 164.0
		hint.add_theme_font_size_override("font_size", 16)
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var marker := candidate as MeshInstance3D
		if marker.mesh == null:
			continue
		var uses_slot_material := marker.material_override == _slot_material
		if not uses_slot_material:
			for surface_index in marker.mesh.get_surface_count():
				if marker.mesh.surface_get_material(surface_index) == _slot_material:
					uses_slot_material = true
					break
		if uses_slot_material:
			marker.scale.x *= 0.62
			marker.scale.z *= 0.62
	_setup_m04()


func _process(delta: float) -> void:
	super._process(delta)
	if not _m04_ready or _flow_mode != FlowMode.PLAY:
		return
	_update_arena_access()
	if not _boss_defeated and not _boss_encounter_active and _first_combat_loop_completed:
		var point := Vector2(_player.global_position.x, _player.global_position.z)
		if _player.global_position.x >= ARENA_TRIGGER_X and ARENA_BOUNDS.has_point(point):
			_start_boss_encounter()


func _setup_m04() -> void:
	_build_boss_arena()
	_create_boss()
	_create_boss_hud()
	_create_home_trophy_display()
	_m04_ready = true
	_apply_m04_world_state()
	_refresh_hud()


func _build_boss_arena() -> void:
	_m04_world = Node3D.new()
	_m04_world.name = "M04BossWorld"
	add_child(_m04_world)
	var base_region := get_node("NavigationRegion3D") as NavigationRegion3D
	var old_east := base_region.get_node_or_null("BoundaryEast") as StaticBody3D
	if old_east != null:
		old_east.visible = false
		var old_shape := old_east.get_node("CollisionShape3D") as CollisionShape3D
		old_shape.disabled = true
	# M02의 동쪽 울타리 두 칸을 비워 Arena 입구가 외곽에서 바로 읽히게 한다.
	var generated_world := get_node("GeneratedWorld") as Node3D
	for child in generated_world.get_children():
		var old_fence := child as Node3D
		if old_fence != null and old_fence.name.begins_with("FenceEast_") and old_fence.position.z > -1.0 and old_fence.position.z < 6.0:
			old_fence.visible = false

	_add_static_box(base_region, "M04BoundaryEastNorth", Vector3(14.85, 0.75, -5.35), Vector3(0.3, 3.0, 12.7), null)
	_add_static_box(base_region, "M04BoundaryEastSouth", Vector3(14.85, 0.75, 7.85), Vector3(0.3, 3.0, 7.7), null)
	var floor_material := _make_material(Color(0.30, 0.38, 0.31))
	_add_static_box(base_region, "M04ArenaFloor", Vector3(21.35, -0.25, 2.5), Vector3(13.0, 0.5, 11.0), floor_material)
	_add_path(_m04_world, "RuinDepthPath", Vector3(12.8, 0.03, 2.5), Vector3(20.0, 0.03, 2.5), 2.8)

	var navigation_region := NavigationRegion3D.new()
	navigation_region.name = "M04NavigationRegion"
	var navigation_mesh := NavigationMesh.new()
	navigation_mesh.vertices = PackedVector3Array([
		Vector3(14.25, 0.0, -3.0), Vector3(28.0, 0.0, -3.0),
		Vector3(28.0, 0.0, 8.0), Vector3(14.25, 0.0, 8.0),
	])
	navigation_mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	navigation_region.navigation_mesh = navigation_mesh
	add_child(navigation_region)

	var wall_material := _make_material(Color(0.22, 0.30, 0.32))
	_add_static_box(base_region, "M04ArenaNorthWall", Vector3(21.5, 0.9, -3.15), Vector3(13.3, 1.8, 0.35), wall_material)
	_add_static_box(base_region, "M04ArenaSouthWall", Vector3(21.5, 0.9, 8.15), Vector3(13.3, 1.8, 0.35), wall_material)
	_add_static_box(base_region, "M04ArenaEastWall", Vector3(28.15, 0.9, 2.5), Vector3(0.35, 1.8, 11.3), wall_material)
	for z in [-2.25, 7.25]:
		_add_static_box(base_region, "M04ArenaWestWall_%s" % str(z), Vector3(17.0, 0.9, z), Vector3(0.35, 1.8, 1.5), wall_material)
	for pillar_data in [
		["PillarNorthWest", Vector3(18.2, 1.1, -1.8)], ["PillarNorthEast", Vector3(26.8, 1.1, -1.8)],
		["PillarSouthWest", Vector3(18.2, 1.1, 6.8)], ["PillarSouthEast", Vector3(26.8, 1.1, 6.8)],
	]:
		_add_static_box(base_region, pillar_data[0], pillar_data[1], Vector3(0.8, 2.2, 0.8), wall_material)
	_add_visual_box(_m04_world, "ArenaMarkNorth", Vector3(23.0, 0.035, -1.65), Vector3(5.4, 0.05, 0.34), _make_material(Color(0.10, 0.65, 0.72), Color(0.02, 0.35, 0.42)))
	_add_visual_box(_m04_world, "ArenaMarkSouth", Vector3(23.0, 0.035, 6.65), Vector3(5.4, 0.05, 0.34), _make_material(Color(0.10, 0.65, 0.72), Color(0.02, 0.35, 0.42)))

	var entrance_material := _make_material(Color(0.18, 0.52, 0.54), Color(0.02, 0.28, 0.31))
	var entrance_fence_north := _instantiate_art_scene(ART_FENCE_SCENE, _m04_world, "ArenaEntranceFenceNorth", Vector3(14.72, 0.0, -0.86), 90.0)
	entrance_fence_north.scale = Vector3(0.64, 1.0, 1.0)
	var entrance_fence_south := _instantiate_art_scene(ART_FENCE_SCENE, _m04_world, "ArenaEntranceFenceSouth", Vector3(14.72, 0.0, 5.68), 90.0)
	entrance_fence_south.scale = Vector3(0.55, 1.0, 1.0)
	_add_visual_box(_m04_world, "ArenaEntranceNorthPost", Vector3(ARENA_ENTRANCE_X, 1.35, 0.62), Vector3(0.58, 2.7, 0.58), entrance_material)
	_add_visual_box(_m04_world, "ArenaEntranceSouthPost", Vector3(ARENA_ENTRANCE_X, 1.35, 4.38), Vector3(0.58, 2.7, 0.58), entrance_material)
	_add_visual_box(_m04_world, "ArenaEntranceLintel", Vector3(ARENA_ENTRANCE_X, 2.58, 2.5), Vector3(0.58, 0.32, 4.34), entrance_material)
	_arena_access_gate = _add_static_box(base_region, "M04AccessGate", Vector3(ARENA_ENTRANCE_X, 1.0, 2.5), Vector3(0.42, 2.0, 3.15), _make_material(Color(0.34, 0.48, 0.45), Color(0.03, 0.22, 0.2)))
	_encounter_barrier = _add_static_box(base_region, "M04EncounterBarrier", Vector3(ARENA_ENTRANCE_X, 1.0, 2.5), Vector3(0.42, 2.0, 3.15), _make_material(Color(0.08, 0.70, 0.82), Color(0.03, 0.62, 0.78)))
	_set_static_body_active(_encounter_barrier, false)


func _create_boss() -> void:
	_boss = CharacterBody3D.new()
	_boss.name = "TideboundGuardian"
	_boss.set_script(BOSS_SCRIPT)
	_boss.position = BOSS_SPAWN
	_boss.collision_layer = 1
	_boss.collision_mask = 1
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.82
	capsule.height = 2.3
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = capsule
	_boss.add_child(collision)
	var health := HEALTH_SCRIPT.new()
	health.name = "Health"
	_boss.add_child(health)
	var visual_root := Node3D.new()
	visual_root.name = "VisualRoot"
	_boss.add_child(visual_root)
	var body_material := _combat_material(Color(0.12, 0.31, 0.37), Color(0.02, 0.10, 0.14))
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.66
	body_mesh.bottom_radius = 0.96
	body_mesh.height = 2.18
	body_mesh.radial_segments = 8
	body_mesh.material = body_material
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = body_mesh
	body.material_override = body_material
	visual_root.add_child(body)
	var armor_material := _combat_material(Color(0.40, 0.48, 0.48))
	var dark_stone_material := _combat_material(Color(0.20, 0.25, 0.26))
	_add_box_visual(visual_root, "ShoulderLeft", Vector3(-0.74, 0.48, 0), Vector3(0.62, 0.36, 0.76), armor_material)
	_add_box_visual(visual_root, "ShoulderRight", Vector3(0.74, 0.48, 0), Vector3(0.62, 0.36, 0.76), armor_material)
	_add_box_visual(visual_root, "ArmLeft", Vector3(-0.87, -0.08, 0), Vector3(0.34, 0.92, 0.42), dark_stone_material)
	_add_box_visual(visual_root, "ArmRight", Vector3(0.87, -0.08, 0), Vector3(0.34, 0.92, 0.42), dark_stone_material)
	_add_box_visual(visual_root, "TideMask", Vector3(0, 0.62, -0.61), Vector3(0.58, 0.48, 0.16), armor_material)
	var belt_mesh := CylinderMesh.new()
	belt_mesh.top_radius = 0.88
	belt_mesh.bottom_radius = 0.94
	belt_mesh.height = 0.16
	belt_mesh.radial_segments = 8
	belt_mesh.material = dark_stone_material
	var belt := MeshInstance3D.new()
	belt.name = "StoneBelt"
	belt.position.y = -0.06
	belt.mesh = belt_mesh
	visual_root.add_child(belt)
	var crest_material := _combat_material(Color(0.24, 0.70, 0.72), Color(0.03, 0.24, 0.28))
	for index in range(3):
		var crystal_mesh := PrismMesh.new()
		crystal_mesh.size = Vector3(0.38, 1.25 - index * 0.15, 0.38)
		crystal_mesh.material = crest_material
		var crystal := MeshInstance3D.new()
		crystal.name = "TideCrest%d" % index
		crystal.mesh = crystal_mesh
		crystal.position = Vector3((index - 1) * 0.5, 1.25 - abs(index - 1) * 0.1, 0.08)
		crystal.rotation_degrees.z = (index - 1) * -18.0
		visual_root.add_child(crystal)
	var warning_material := StandardMaterial3D.new()
	warning_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	warning_material.albedo_color = Color(1.0, 0.12, 0.18, 0.35)
	warning_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var warning_mesh := CylinderMesh.new()
	warning_mesh.top_radius = 1.0
	warning_mesh.bottom_radius = 1.0
	warning_mesh.height = 0.025
	warning_mesh.radial_segments = 32
	warning_mesh.material = warning_material
	var warning := MeshInstance3D.new()
	warning.name = "WarningCircle"
	warning.mesh = warning_mesh
	warning.position.y = -0.97
	_boss.add_child(warning)
	_combat_world.add_child(_boss)
	_boss.call("configure", self, _player, ARENA_BOUNDS)
	_boss.connect("defeated", _on_boss_defeated)
	_boss.connect("health_changed", _refresh_boss_hud)


func _create_boss_hud() -> void:
	_boss_hud = PanelContainer.new()
	_boss_hud.name = "BossHUD"
	_boss_hud.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_hud.position = Vector2(-270, 174)
	_boss_hud.size = Vector2(540, 74)
	_boss_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.05, 0.07, 0.92)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.14, 0.76, 0.88, 0.9)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 9
	panel_style.content_margin_bottom = 9
	_boss_hud.add_theme_stylebox_override("panel", panel_style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_boss_hud.add_child(box)
	_boss_name_label = Label.new()
	_boss_name_label.text = "TIDEBOUND GUARDIAN"
	_boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name_label.add_theme_font_size_override("font_size", 19)
	_boss_name_label.add_theme_color_override("font_color", Color(0.72, 0.96, 1.0))
	box.add_child(_boss_name_label)
	_boss_health_bar = ProgressBar.new()
	_boss_health_bar.max_value = 300.0
	_boss_health_bar.value = 300.0
	_boss_health_bar.show_percentage = false
	_boss_health_bar.custom_minimum_size = Vector2(500, 20)
	box.add_child(_boss_health_bar)
	get_node("UI").add_child(_boss_hud)
	_boss_hud.visible = false


func _create_home_trophy_display() -> void:
	_boss_trophy_slot = Node3D.new()
	_boss_trophy_slot.name = "BossTrophySlot"
	_boss_trophy_slot.position = Vector3(0.8, 0.04, 8.25)
	_boss_trophy_slot.set_meta("kind", "boss_trophy_display")
	_boss_trophy_slot.set_meta("active", false)
	_interactables.add_child(_boss_trophy_slot)
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 0.78
	ring_mesh.bottom_radius = 0.78
	ring_mesh.height = 0.05
	ring_mesh.radial_segments = 20
	ring_mesh.material = _make_material(Color(0.20, 0.54, 0.55), Color(0.02, 0.14, 0.16))
	var ring := MeshInstance3D.new()
	ring.mesh = ring_mesh
	_boss_trophy_slot.add_child(ring)

	_boss_trophy_visual = Node3D.new()
	_boss_trophy_visual.name = "TideCrestDisplayed"
	_boss_trophy_visual.position = _boss_trophy_slot.position
	_m04_world.add_child(_boss_trophy_visual)
	_add_box_visual(_boss_trophy_visual, "Pedestal", Vector3(0, 0.45, 0), Vector3(1.25, 0.9, 1.0), _make_material(Color(0.24, 0.30, 0.31)))
	var crest_material := _combat_material(Color(0.28, 0.72, 0.72), Color(0.04, 0.28, 0.30))
	for index in range(3):
		var crest_mesh := PrismMesh.new()
		crest_mesh.size = Vector3(0.28, 0.85 - index * 0.1, 0.28)
		crest_mesh.material = crest_material
		var crest := MeshInstance3D.new()
		crest.mesh = crest_mesh
		crest.position = Vector3((index - 1) * 0.34, 1.25, 0)
		crest.rotation_degrees.z = (index - 1) * -20.0
		_boss_trophy_visual.add_child(crest)
	_boss_trophy_visual.visible = false


func _start_boss_encounter() -> void:
	if _boss_defeated or _boss_encounter_active or not is_combat_active():
		return
	_arena_discovered = true
	_boss_encounter_active = true
	_player.call("cancel_active_movement")
	_player.call("set_click_destination_bounds", true, ARENA_BOUNDS)
	_set_static_body_active(_encounter_barrier, true)
	_boss_hud.visible = true
	_boss.call("activate_encounter")
	_refresh_boss_hud()
	_refresh_hud()
	_show_message("Tidebound Guardian · 바다에 묶인 수호자의 시험", false)


func _on_boss_defeated() -> void:
	if _boss_defeated:
		return
	_boss_defeated = true
	_boss_encounter_active = false
	_player.call("set_click_destination_bounds", false)
	_set_static_body_active(_encounter_barrier, false)
	_boss_hud.visible = false
	_clear_active_projectiles()
	_spawn_boss_reward_if_needed()
	_refresh_hud()
	if _save_game():
		_show_message("Tidebound Guardian 격파 · 빛나는 보상을 확인하세요.", false)
	else:
		_show_message("보스를 격파했지만 저장하지 못했습니다. 보상은 이 실행에 유지됩니다.", true)


func _spawn_boss_reward_if_needed() -> void:
	if not _m04_ready or not _boss_defeated or _boss_reward_claimed:
		return
	if is_instance_valid(_boss_reward):
		_boss_reward.visible = true
		_boss_reward.set_meta("active", true)
		return
	_boss_reward = Node3D.new()
	_boss_reward.name = "TideboundReward"
	_boss_reward.position = BOSS_REWARD_POSITION
	_boss_reward.set_meta("kind", "boss_reward")
	_boss_reward.set_meta("active", true)
	_interactables.add_child(_boss_reward)
	var core_material := _combat_material(Color(0.30, 0.74, 0.74), Color(0.04, 0.30, 0.34))
	var core_mesh := PrismMesh.new()
	core_mesh.size = Vector3(0.52, 1.05, 0.52)
	core_mesh.material = core_material
	var core := MeshInstance3D.new()
	core.name = "TideCore"
	core.mesh = core_mesh
	_boss_reward.add_child(core)
	for side in [-1.0, 1.0]:
		var crest_mesh := PrismMesh.new()
		crest_mesh.size = Vector3(0.26, 0.72, 0.26)
		crest_mesh.material = core_material
		var crest := MeshInstance3D.new()
		crest.name = "Crest%s" % str(side)
		crest.mesh = crest_mesh
		crest.position = Vector3(side * 0.42, 0.05, 0)
		crest.rotation_degrees.z = side * 28.0
		_boss_reward.add_child(crest)
	_add_pickup_ring(_boss_reward)


func _collect_boss_reward(target: Node3D) -> void:
	if _boss_reward_claimed or not _boss_defeated or not bool(target.get_meta("active", true)):
		return
	_boss_reward_claimed = true
	_boss_trophy_owned = true
	_boss_growth_core_owned = true
	target.set_meta("active", false)
	target.visible = false
	_nearest_interactable = null
	target.queue_free()
	_boss_reward = null
	_apply_m04_world_state()
	_refresh_hud()
	_save_after_change("Tide Crest와 Tide Core를 획득했습니다.")


func _display_boss_trophy() -> void:
	if not _boss_trophy_owned or _boss_trophy_displayed:
		return
	_boss_trophy_displayed = true
	_apply_m04_world_state()
	_refresh_hud()
	_save_after_change("Tide Crest를 거점에 전시했습니다.")


func _upgrade_weapon() -> void:
	if _weapon_level == 0:
		super._upgrade_weapon()
		return
	if _weapon_level >= 2:
		_show_message("Prototype Blade는 이미 +2입니다.", false)
		return
	if not _boss_growth_core_owned:
		_show_message("Tide Core가 필요합니다.", true)
		return
	_boss_growth_core_owned = false
	_weapon_level = 2
	_update_first_loop_completion()
	_refresh_hud()
	_save_after_change("Prototype Blade +2 · 피해 24 → 30")


func _interaction_label(target: Node3D) -> String:
	match String(target.get_meta("kind", "")):
		"boss_reward":
			return "Tide Crest와 Tide Core 획득"
		"boss_trophy_display":
			return "Tide Crest 전시"
		"weapon_workbench":
			if _weapon_level == 0:
				return "Prototype Blade 강화 (Core 4)"
			if _weapon_level == 1:
				return "Prototype Blade +2 강화 (Tide Core)" if _boss_growth_core_owned else "Prototype Blade 확인"
			return "Prototype Blade +2 확인"
	return super._interaction_label(target)


func _interact_with_nearest() -> void:
	_update_nearest_interactable()
	if _nearest_interactable == null:
		return
	match String(_nearest_interactable.get_meta("kind", "")):
		"boss_reward":
			_collect_boss_reward(_nearest_interactable)
		"boss_trophy_display":
			_display_boss_trophy()
		_:
			super._interact_with_nearest()


func _current_objective() -> String:
	if not _first_combat_loop_completed:
		return super._current_objective()
	if not _boss_defeated:
		return "Tidebound Guardian을 쓰러뜨리세요." if _arena_discovered else "폐허 깊은 곳의 강한 존재를 찾아보세요."
	if not _boss_reward_claimed:
		return "보스를 쓰러뜨렸습니다. 보상을 확인하세요."
	if not _boss_trophy_displayed:
		return "거점으로 돌아가 Trophy를 전시하세요."
	if _weapon_level == 1:
		return "Tide Core로 무기를 강화하세요."
	if _weapon_level >= 2:
		return "Green Coast의 첫 원정을 완료했습니다."
	return "Monster Core로 무기를 먼저 +1 강화하세요."


func _refresh_hud() -> void:
	super._refresh_hud()
	if not has_node("UI/HUD/Stats/VBox/ResourceLabel"):
		return
	var hp_current := PLAYER_MAX_HEALTH
	var hp_max := PLAYER_MAX_HEALTH
	if _player_health != null:
		hp_current = float(_player_health.current_health)
		hp_max = float(_player_health.max_health)
	var souvenir_text := "보유" if _souvenir_owned else "미발견"
	if _souvenir_displayed:
		souvenir_text = "전시됨"
	var tide_core_text := "보유" if _boss_growth_core_owned else "없음"
	var crest_text := "전시됨" if _boss_trophy_displayed else ("보유" if _boss_trophy_owned else "미획득")
	var resource_label := get_node("UI/HUD/Stats/VBox/ResourceLabel") as Label
	resource_label.add_theme_font_size_override("font_size", 17)
	resource_label.text = "HP %d/%d · Core %d · Blade +%d · Tide %s · Crest %s · 목재 %d 돌 %d · 기념품 %s" % [int(ceil(hp_current)), int(hp_max), _monster_core_count, _weapon_level, tide_core_text, crest_text, _wood, _stone, souvenir_text]
	(get_node("UI/HUD/Stats/VBox/ObjectiveLabel") as Label).text = "현재 목표: " + _current_objective()
	_refresh_boss_hud()


func _refresh_boss_hud() -> void:
	if _boss_hud == null or _boss == null:
		return
	_boss_hud.visible = _boss_encounter_active and _flow_mode == FlowMode.PLAY
	var snapshot: Dictionary = _boss.call("get_health_snapshot")
	_boss_health_bar.max_value = float(snapshot.get("maximum", 300.0))
	_boss_health_bar.value = float(snapshot.get("current", 0.0))
	_boss_name_label.text = "TIDEBOUND GUARDIAN  ·  PHASE %d" % int(snapshot.get("phase", 1))


func _current_weapon_damage() -> float:
	if _weapon_level >= 2:
		return BLADE_LEVEL_TWO_DAMAGE
	return super._current_weapon_damage()


func _maximum_weapon_level() -> int:
	return 2


func _additional_melee_targets() -> Array[CharacterBody3D]:
	var targets: Array[CharacterBody3D] = []
	if _boss_encounter_active and is_instance_valid(_boss):
		targets.append(_boss)
	return targets


func is_boss_encounter_active() -> bool:
	return _boss_encounter_active and is_combat_active()


func _on_enemy_defeated(enemy: CharacterBody3D, core_amount: int, was_elite: bool) -> void:
	super._on_enemy_defeated(enemy, core_amount, was_elite)
	_update_arena_access()
	_refresh_hud()


func _before_player_death_recovery() -> void:
	if _boss_encounter_active:
		# 치명타를 계산 중인 보스 호출 스택에서 충돌·투사체를 즉시 바꾸지 않는다.
		# 전투 비활성 플래그만 먼저 내리고 실제 정리는 다음 idle 단계에 수행한다.
		_boss_encounter_active = false
		call_deferred("_reset_boss_encounter_for_retry")


func _reset_boss_encounter_for_retry() -> void:
	_boss_encounter_active = false
	_player.call("set_click_destination_bounds", false)
	_set_static_body_active(_encounter_barrier, false)
	if _boss_hud != null:
		_boss_hud.visible = false
	_clear_active_projectiles()
	if is_instance_valid(_boss) and not _boss_defeated:
		_boss.call("reset_for_retry")


func _clear_active_projectiles() -> void:
	if _projectile_root == null:
		return
	for projectile in _projectile_root.get_children():
		projectile.queue_free()


func _update_arena_access() -> void:
	if _arena_access_gate == null:
		return
	_set_static_body_active(_arena_access_gate, not _first_combat_loop_completed)


func _set_static_body_active(body: StaticBody3D, active: bool) -> void:
	if body == null:
		return
	body.visible = active
	var collision := body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null:
		collision.set_deferred("disabled", not active)


func _update_first_loop_completion() -> void:
	_green_coast_first_loop_completed = _boss_defeated and _boss_reward_claimed and _boss_trophy_displayed and _weapon_level >= 2


func _apply_m04_world_state() -> void:
	if not _m04_ready:
		return
	_update_first_loop_completion()
	_update_arena_access()
	_set_static_body_active(_encounter_barrier, false)
	_boss_encounter_active = false
	_player.call("set_click_destination_bounds", false)
	if _boss_defeated:
		_boss.call("set_defeated_world_state")
		_spawn_boss_reward_if_needed()
	else:
		_boss.call("reset_for_retry")
	if _boss_trophy_slot != null:
		_boss_trophy_slot.set_meta("active", _boss_trophy_owned and not _boss_trophy_displayed)
		_boss_trophy_slot.visible = not _boss_trophy_displayed
	if _boss_trophy_visual != null:
		_boss_trophy_visual.visible = _boss_trophy_displayed


func _reset_progress() -> void:
	super._reset_progress()
	_boss_defeated = false
	_boss_reward_claimed = false
	_boss_trophy_owned = false
	_boss_trophy_displayed = false
	_boss_growth_core_owned = false
	_green_coast_first_loop_completed = false
	_arena_discovered = false
	_boss_encounter_active = false
	if _m04_ready:
		if is_instance_valid(_boss_reward):
			_boss_reward.queue_free()
		_boss_reward = null
		_apply_m04_world_state()


func _save_game() -> bool:
	_update_first_loop_completion()
	var path := _save_path()
	var directory := path.get_base_dir()
	var mkdir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
		return false
	var data := {
		"version": SAVE_VERSION,
		"region_id": REGION_ID,
		"player_position": [_player.global_position.x, _player.global_position.y, _player.global_position.z],
		"wood": _wood,
		"stone": _stone,
		"collected_ids": _sorted_collected_ids(),
		"souvenir_owned": _souvenir_owned,
		"souvenir_displayed": _souvenir_displayed,
		"bench_installed": _bench_installed,
		"monster_core_count": _monster_core_count,
		"weapon_level": _weapon_level,
		"first_combat_loop_completed": _first_combat_loop_completed,
		"boss_defeated": _boss_defeated,
		"boss_reward_claimed": _boss_reward_claimed,
		"boss_trophy_owned": _boss_trophy_owned,
		"boss_trophy_displayed": _boss_trophy_displayed,
		"boss_growth_core_owned": _boss_growth_core_owned,
		"green_coast_first_loop_completed": _green_coast_first_loop_completed,
	}
	var temp_path := path + ".tmp"
	if not _write_text_file(temp_path, JSON.stringify(data, "\t")):
		return false
	if not _read_and_validate_save(temp_path).get("ok", false):
		return false
	if FileAccess.file_exists(path):
		var current_result := _read_and_validate_save(path)
		if not current_result.get("ok", false):
			return false
		var backup_path := _backup_path()
		var backup_temp := backup_path + ".tmp"
		if not _write_text_file(backup_temp, FileAccess.get_file_as_string(path)):
			return false
		if not _read_and_validate_save(backup_temp).get("ok", false):
			return false
		var backup_absolute := ProjectSettings.globalize_path(backup_path)
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_absolute)
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_temp), backup_absolute) != OK:
			return false
		if DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) != OK:
			return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) == OK


func _is_valid_save_dictionary(data: Dictionary) -> bool:
	if not super._is_valid_save_dictionary(data):
		return false
	for key in ["boss_defeated", "boss_reward_claimed", "boss_trophy_owned", "boss_trophy_displayed", "boss_growth_core_owned", "green_coast_first_loop_completed"]:
		if data.has(key) and typeof(data[key]) != TYPE_BOOL:
			return false
	var defeated := bool(data.get("boss_defeated", false))
	var claimed := bool(data.get("boss_reward_claimed", false))
	var trophy_owned := bool(data.get("boss_trophy_owned", false))
	var trophy_displayed := bool(data.get("boss_trophy_displayed", false))
	var tide_core_owned := bool(data.get("boss_growth_core_owned", false))
	var completed := bool(data.get("green_coast_first_loop_completed", false))
	var weapon_level := int(data.get("weapon_level", 0))
	if claimed and not defeated:
		return false
	if (trophy_owned or tide_core_owned) and not claimed:
		return false
	if trophy_displayed and not trophy_owned:
		return false
	if weapon_level >= 2 and (not claimed or tide_core_owned):
		return false
	if completed and (not defeated or not claimed or not trophy_displayed or weapon_level < 2):
		return false
	return true


func _apply_loaded_data(data: Dictionary) -> void:
	super._apply_loaded_data(data)
	_boss_defeated = bool(data.get("boss_defeated", false))
	_boss_reward_claimed = bool(data.get("boss_reward_claimed", false))
	_boss_trophy_owned = bool(data.get("boss_trophy_owned", false))
	_boss_trophy_displayed = bool(data.get("boss_trophy_displayed", false))
	_boss_growth_core_owned = bool(data.get("boss_growth_core_owned", false))
	_green_coast_first_loop_completed = bool(data.get("green_coast_first_loop_completed", false))
	_arena_discovered = _boss_defeated
	if _m04_ready:
		_apply_m04_world_state()
	_refresh_hud()


func get_combat_snapshot() -> Dictionary:
	var snapshot := super.get_combat_snapshot()
	var boss_snapshot: Dictionary = {}
	if is_instance_valid(_boss):
		boss_snapshot = _boss.call("get_health_snapshot")
	snapshot.merge({
		"boss_defeated": _boss_defeated,
		"boss_reward_claimed": _boss_reward_claimed,
		"boss_trophy_owned": _boss_trophy_owned,
		"boss_trophy_displayed": _boss_trophy_displayed,
		"boss_growth_core_owned": _boss_growth_core_owned,
		"green_coast_first_loop_completed": _green_coast_first_loop_completed,
		"arena_discovered": _arena_discovered,
		"boss_encounter_active": _boss_encounter_active,
		"boss_hud_visible": _boss_hud.visible if _boss_hud != null else false,
		"arena_access_open": _first_combat_loop_completed,
		"encounter_barrier_closed": _encounter_barrier.visible if _encounter_barrier != null else false,
		"boss": boss_snapshot,
		"objective": _current_objective(),
	}, true)
	return snapshot
