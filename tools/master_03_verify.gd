extends SceneTree

const GAME_SCENE := preload("res://scenes/prototype/green_coast_m02.tscn")
const VERIFY_SAVE := "user://prototypes/master_03_verify/save.json"

var _checks: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_verify_files()
	var game := await _spawn_game()
	game.set("save_path_override", VERIFY_SAVE)
	game.call("_start_new_game")
	await process_frame
	_check(bool(game.get("_master_03_ready")), "production layer ready")
	_check((game.call("get_master_03_snapshot") as Dictionary).get("module_instances", 0) >= 80, "production density")
	await _verify_movement_and_navigation(game)
	await _verify_gather_vista_and_home(game)
	await _verify_combat_boss_and_retry(game)
	_verify_region_two_and_return(game)
	var before_save: Dictionary = game.call("get_macro_snapshot")
	var before_combat_save: Dictionary = game.call("get_combat_snapshot")
	_check(bool(game.call("_save_game")), "save write")
	game.queue_free()
	await process_frame
	var loaded := await _spawn_game()
	loaded.set("save_path_override", VERIFY_SAVE)
	var result: Dictionary = loaded.call("_load_save_data")
	_check(bool(result.get("ok", false)), "continue load")
	loaded.call("_apply_loaded_data", result.get("data", {}))
	var after_load: Dictionary = loaded.call("get_macro_snapshot")
	var after_combat_load: Dictionary = loaded.call("get_combat_snapshot")
	_check(before_save.get("macro_first_skeleton_completed") == after_load.get("macro_first_skeleton_completed"), "continue progression")
	_check(before_combat_save.get("weapon_level") == after_combat_load.get("weapon_level") and int(after_combat_load.get("weapon_level", -1)) == 2, "continue weapon")
	_check(bool(after_combat_load.get("boss_trophy_displayed", false)), "continue trophy")
	_check(String(after_load.get("current_region_id", "")) == "green_coast", "continue home region")
	_check(_verify_old_save_shape(loaded), "old save compatibility")
	print("MASTER03_VERIFY_OK checks=%d snapshot=%s" % [_checks.size(), JSON.stringify(after_load)])
	loaded.queue_free()
	await process_frame
	_remove_verify_files()
	quit(0)


func _spawn_game() -> Node:
	var game := GAME_SCENE.instantiate()
	root.add_child(game)
	current_scene = game
	for index in range(5):
		await process_frame
	return game


func _verify_movement_and_navigation(game: Node) -> void:
	var player := game.get_node("Player") as CharacterBody3D
	var start := player.global_position
	Input.action_press("move_left")
	for index in range(12):
		await physics_frame
	Input.action_release("move_left")
	_check(player.global_position.distance_to(start) > 0.18, "WASD movement")
	var accepted := bool(player.call("_try_accept_destination", Vector3(-7.5, 0.0, 1.8), true))
	_check(accepted, "right-click destination acceptance")
	player.call("cancel_active_movement")
	var map_rid: RID = (player.get_node("NavigationAgent3D") as NavigationAgent3D).get_navigation_map()
	var route := NavigationServer3D.map_get_path(map_rid, player.global_position, Vector3(8.0, 0.0, -2.0), true)
	_check(route.size() >= 2, "connected Green Coast navigation")


func _verify_gather_vista_and_home(game: Node) -> void:
	var interactables := game.get("_interactables") as Node3D
	for child in interactables.get_children():
		var target := child as Node3D
		if target == null or not bool(target.get_meta("active", true)):
			continue
		var kind := String(target.get_meta("kind", ""))
		if kind == "wood":
			game.call("_collect_resource", target, String(target.get_meta("pickup_id", "")), "Wood", 1, true)
		elif kind == "stone":
			game.call("_collect_resource", target, String(target.get_meta("pickup_id", "")), "Stone", 1, false)
		elif kind == "souvenir":
			game.call("_collect_souvenir", target, String(target.get_meta("pickup_id", "")))
	_check(int(game.get("_wood")) == 5 and int(game.get("_stone")) == 3, "gather resources")
	_check(bool(game.get("_souvenir_owned")), "ruin secret souvenir")
	var player := game.get_node("Player") as CharacterBody3D
	player.global_position = Vector3(0, 1, -10.8)
	_check(bool(game.call("enter_vista")), "vista enter")
	await create_timer(1.05).timeout
	player.global_position = Vector3(0, 1, -8.5)
	game.call("exit_vista")
	await create_timer(1.05).timeout
	_check(bool(game.get("_vista_seen")), "vista completion")
	game.call("_install_bench")
	game.call("_display_souvenir")
	_check(bool(game.get("_bench_installed")) and bool(game.get("_souvenir_displayed")), "home bench and display")


func _verify_combat_boss_and_retry(game: Node) -> void:
	# Defeat the fixed enemies through their health path, then collect the actual
	# spawned Core nodes.  This preserves signal ordering and elite completion.
	var enemies: Array = (game.get("_enemies") as Array).duplicate()
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.call("take_melee_hit", 9999.0, Vector3.RIGHT)
	for index in range(45):
		await process_frame
	var interactables := game.get("_interactables") as Node3D
	var core_nodes: Array[Node3D] = []
	for child in interactables.get_children():
		if String(child.get_meta("kind", "")) == "monster_core" and bool(child.get_meta("active", true)):
			core_nodes.append(child as Node3D)
	for core in core_nodes:
		game.call("_collect_monster_core", core)
	_check(int(game.get("_monster_core_count")) >= 4, "enemy drops")
	_check(bool(game.get("_first_combat_loop_completed")), "elite combat completion")
	game.call("_upgrade_weapon")
	_check(int(game.get("_weapon_level")) == 1, "weapon +1")

	game.call("_start_boss_encounter")
	_check(bool(game.get("_boss_encounter_active")), "boss encounter start")
	game.call("damage_player", 9999.0, Vector3.ZERO)
	await create_timer(1.65).timeout
	_check(is_instance_valid(game) and not bool(game.get("_death_sequence_running")), "death retry keeps scene alive")
	var boss := game.get("_boss") as CharacterBody3D
	var boss_retry: Dictionary = boss.call("get_health_snapshot")
	_check(int(boss_retry.get("current", 0)) == 300 and int(boss_retry.get("phase", 0)) == 1, "boss retry reset")

	game.call("_start_boss_encounter")
	boss.call("take_melee_hit", 9999.0, Vector3.RIGHT)
	for index in range(50):
		await process_frame
	_check(bool(game.get("_boss_defeated")), "boss defeat")
	var reward := game.get("_boss_reward") as Node3D
	_check(is_instance_valid(reward), "boss reward spawned")
	game.call("_collect_boss_reward", reward)
	game.call("_display_boss_trophy")
	game.call("_upgrade_weapon")
	_check(bool(game.get("_boss_trophy_displayed")), "trophy display")
	_check(int(game.get("_weapon_level")) == 2, "weapon +2")
	_check(bool(game.get("_green_coast_first_loop_completed")), "Green Coast completion")


func _verify_region_two_and_return(game: Node) -> void:
	game.set("_region_two_unlocked", true)
	game.call("_enter_region_two")
	_check(String(game.get("_current_region_id")) == "region_2_prototype", "Region 2 entry")
	var interactables := game.get("_interactables") as Node3D
	for child in interactables.get_children():
		if String(child.get_meta("kind", "")) == "region_two_ore" and bool(child.get_meta("active", true)):
			game.call("_collect_region_two_ore", child)
	game.call("_discover_region_two_homestead")
	game.call("_craft_region_two_sample")
	_check(bool(game.get("_crafted_region_two_sample")), "Region 2 craft")
	_check(bool(game.get("_homestead_region_two_unlocked")), "Region 2 homestead")
	game.call("_return_home")
	_check(String(game.get("_current_region_id")) == "green_coast", "return Home")


func _verify_old_save_shape(game: Node) -> bool:
	var old_data := {
		"version": 1,
		"region_id": "green_coast_m02",
		"player_position": [0.0, 1.0, 5.5],
		"wood": 0,
		"stone": 0,
		"collected_ids": [],
		"souvenir_owned": false,
		"souvenir_displayed": false,
		"bench_installed": false,
	}
	return bool(game.call("_is_valid_save_dictionary", old_data))


func _check(condition: bool, label: String) -> void:
	if not condition:
		push_error("MASTER03_VERIFY_FAIL " + label)
		quit(1)
		return
	_checks.append(label)


func _remove_verify_files() -> void:
	for path in [VERIFY_SAVE, VERIFY_SAVE + ".tmp", VERIFY_SAVE + ".macro.tmp", VERIFY_SAVE.get_base_dir().path_join("save.previous.json")]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
