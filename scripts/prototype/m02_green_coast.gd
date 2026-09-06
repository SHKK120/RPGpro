extends "res://scripts/prototype/m01_coast_preview.gd"

enum FlowMode { START, PLAY, PAUSE }

const SAVE_VERSION := 1
const REGION_ID := "green_coast_m02"
const SAVE_DIRECTORY := "user://prototypes/green_coast_m02"
const SAVE_FILE := SAVE_DIRECTORY + "/save_v1.json"
const SAVE_BACKUP_FILE := SAVE_DIRECTORY + "/save_v1.previous.json"
const SAFE_START := Vector3(0, 1, 5.5)
const BENCH_WOOD_COST := 4
const BENCH_STONE_COST := 2
const INTERACTION_DISTANCE := 2.25
const COAST_LOOK_TRIGGER_Z := -10.65
const COAST_LOOK_RESET_Z := -9.6
const COAST_LOOK_MAX_X := 12.5
const KNOWN_PICKUP_IDS := [
	"wood_gc_01", "wood_gc_02", "wood_gc_03", "wood_gc_04", "wood_gc_05",
	"stone_gc_01", "stone_gc_02", "stone_gc_03", "souvenir_green_coast",
]

@export var save_path_override := ""

var _flow_mode := FlowMode.START
var _wood := 0
var _stone := 0
var _collected_ids: Dictionary = {}
var _souvenir_owned := false
var _souvenir_displayed := false
var _bench_installed := false
var _vista_seen := false
var _nearest_interactable: Node3D
var _interactables: Node3D
var _bench_visual: Node3D
var _display_visual: Node3D
var _toast_timer: Timer

var _ground_material: StandardMaterial3D
var _path_material: StandardMaterial3D
var _wood_material: StandardMaterial3D
var _leaf_material: StandardMaterial3D
var _stone_material: StandardMaterial3D
var _ruin_material: StandardMaterial3D
var _hut_material: StandardMaterial3D
var _roof_material: StandardMaterial3D
var _slot_material: StandardMaterial3D
var _souvenir_material: StandardMaterial3D
var _bench_material: StandardMaterial3D


func _ready() -> void:
	_build_green_coast()
	super._ready()
	_interactables = get_node("Interactables") as Node3D
	_bench_visual = get_node("GeneratedWorld/BenchInstalled") as Node3D
	_display_visual = get_node("GeneratedWorld/SouvenirDisplayed") as Node3D
	_toast_timer = get_node("UI/ToastTimer") as Timer
	_connect_ui()
	_player.call("set_movement_locked", true)
	get_node("UI/HUD").visible = false
	get_node("UI/StartMenu").visible = true
	get_node("UI/PauseMenu").visible = false
	get_node("UI/NewGameConfirm").visible = false
	get_node("UI/InteractionPrompt").visible = false
	get_node("UI/VistaPrompt").visible = false
	_refresh_start_menu()
	_apply_progress_to_world()
	_refresh_hud()


func _process(delta: float) -> void:
	super._process(delta)
	if _flow_mode != FlowMode.PLAY:
		get_node("UI/InteractionPrompt").visible = false
		get_node("UI/VistaPrompt").visible = false
		return
	_update_nearest_interactable()
	_update_coast_edge_trigger()


func _unhandled_input(event: InputEvent) -> void:
	if _flow_mode == FlowMode.START:
		return

	if _flow_mode == FlowMode.PAUSE:
		if event.is_action_pressed("ui_cancel"):
			_resume_game()
		get_viewport().set_input_as_handled()
		return

	if _vista_state == VistaState.ENTERING or _vista_state == VistaState.RETURNING:
		if event.is_action_pressed("ui_cancel") or _event_is_direct_move(event) or event.is_action_pressed("move_to_point") or event.is_action_pressed("view_vista"):
			get_viewport().set_input_as_handled()
		return

	if _vista_state == VistaState.VISTA:
		if event.is_action_pressed("ui_cancel"):
			_open_pause_menu()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("view_vista"):
			get_viewport().set_input_as_handled()
		# 전망은 취소하는 모드가 아니다. 이동 입력은 플레이어에게 전달하고,
		# 실제 절벽 끝 범위를 벗어났을 때 아래 상태 검사에서 자동 종료한다.
		return

	if event.is_action_pressed("ui_cancel"):
		_open_pause_menu()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("view_vista"):
		_interact_with_nearest()
		get_viewport().set_input_as_handled()
		return

	super._unhandled_input(event)


func _finish_vista_entry() -> void:
	super._finish_vista_entry()
	if _vista_state == VistaState.VISTA:
		_player.call("set_movement_locked", false)
		_vista_seen = true
		_refresh_hud()


func is_player_near_vista() -> bool:
	if _player == null:
		return false
	return _player.global_position.z <= COAST_LOOK_TRIGGER_Z and absf(_player.global_position.x) <= COAST_LOOK_MAX_X


func _update_coast_edge_trigger() -> void:
	if _vista_state == VistaState.PLAY and is_player_near_vista():
		enter_vista()
	elif _vista_state == VistaState.VISTA:
		var left_north_edge := _player.global_position.z > COAST_LOOK_RESET_Z or absf(_player.global_position.x) > COAST_LOOK_MAX_X
		if left_north_edge:
			exit_vista()
		else:
			# 끝자락을 따라 옆으로 움직여도 플레이어 기준 전망 구도를 유지한다.
			_camera.global_transform = _vista_transform()


func _update_vista_prompt() -> void:
	if _vista_prompt == null or _vista_prompt_label == null:
		return
	if _vista_state == VistaState.PLAY:
		_vista_prompt.visible = false
		return
	if _vista_state == VistaState.RETURNING:
		_vista_prompt.visible = true
		_vista_prompt_label.text = "평상 시점으로 돌아가는 중"
	else:
		_vista_prompt.visible = true
		_vista_prompt_label.text = "절벽 끝 자동 전망 · 끝자락을 벗어나면 돌아가기"


func _connect_ui() -> void:
	get_node("UI/StartMenu/Panel/VBox/NewButton").pressed.connect(_on_new_game_requested)
	get_node("UI/StartMenu/Panel/VBox/ContinueButton").pressed.connect(_on_continue_requested)
	get_node("UI/StartMenu/Panel/VBox/QuitButton").pressed.connect(_quit_without_save)
	get_node("UI/NewGameConfirm/Panel/VBox/ConfirmButton").pressed.connect(_on_new_game_confirmed)
	get_node("UI/NewGameConfirm/Panel/VBox/CancelButton").pressed.connect(_on_new_game_cancelled)
	get_node("UI/PauseMenu/Panel/VBox/ResumeButton").pressed.connect(_resume_game)
	get_node("UI/PauseMenu/Panel/VBox/SaveQuitButton").pressed.connect(_save_and_quit)
	_toast_timer.timeout.connect(_hide_toast)


func _on_new_game_requested() -> void:
	if FileAccess.file_exists(_save_path()):
		get_node("UI/NewGameConfirm").visible = true
	else:
		_start_new_game()


func _on_new_game_confirmed() -> void:
	get_node("UI/NewGameConfirm").visible = false
	_start_new_game()


func _on_new_game_cancelled() -> void:
	get_node("UI/NewGameConfirm").visible = false


func _on_continue_requested() -> void:
	var load_result := _load_save_data()
	if not load_result.get("ok", false):
		_set_start_message(load_result.get("message", "세이브를 불러오지 못했습니다."), true)
		return
	_apply_loaded_data(load_result["data"])
	await _place_player_on_navigation(load_result["position"])
	_enter_play_mode()
	_show_message("저장된 Green Coast 진행을 불러왔습니다.", false)


func _start_new_game() -> void:
	_reset_progress()
	await _place_player_on_navigation(SAFE_START)
	_enter_play_mode()
	if not _save_game():
		_show_message("새 시험은 시작했지만 초기 저장에 실패했습니다.", true)


func _enter_play_mode() -> void:
	_flow_mode = FlowMode.PLAY
	_player.call("cancel_active_movement")
	_player.call("set_movement_locked", false)
	get_node("UI/StartMenu").visible = false
	get_node("UI/NewGameConfirm").visible = false
	get_node("UI/PauseMenu").visible = false
	get_node("UI/HUD").visible = true
	_refresh_hud()


func _open_pause_menu() -> void:
	if _flow_mode != FlowMode.PLAY or _vista_state == VistaState.ENTERING or _vista_state == VistaState.RETURNING:
		return
	_flow_mode = FlowMode.PAUSE
	_player.call("set_movement_locked", true)
	get_node("UI/PauseMenu").visible = true
	get_node("UI/InteractionPrompt").visible = false
	get_node("UI/VistaPrompt").visible = false


func _resume_game() -> void:
	if _flow_mode != FlowMode.PAUSE:
		return
	_flow_mode = FlowMode.PLAY
	get_node("UI/PauseMenu").visible = false
	_player.call("set_movement_locked", false)


func _save_and_quit() -> void:
	if _save_game():
		get_tree().quit()
	else:
		_show_message("저장에 실패해 종료하지 않았습니다. 기존 파일은 유지됩니다.", true)


func _quit_without_save() -> void:
	get_tree().quit()


func _update_nearest_interactable() -> void:
	_nearest_interactable = null
	if is_player_near_vista():
		get_node("UI/InteractionPrompt").visible = false
		return

	var nearest_distance := INF
	for child in _interactables.get_children():
		var candidate := child as Node3D
		if candidate == null or not candidate.visible or not candidate.get_meta("active", true):
			continue
		var distance := _horizontal_distance(_player.global_position, candidate.global_position)
		if distance > INTERACTION_DISTANCE or distance >= nearest_distance:
			continue
		if not _has_interaction_line_of_sight(candidate):
			continue
		nearest_distance = distance
		_nearest_interactable = candidate

	var prompt := get_node("UI/InteractionPrompt") as Control
	if _nearest_interactable == null:
		prompt.visible = false
		return
	prompt.visible = true
	(get_node("UI/InteractionPrompt/Label") as Label).text = "E: %s" % _interaction_label(_nearest_interactable)


func _has_interaction_line_of_sight(target: Node3D) -> bool:
	var ray_from := _player.global_position + Vector3(0, 0.65, 0)
	var ray_to := target.global_position + Vector3(0, 0.35, 0)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to, 1, [_player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var hit_position: Vector3 = hit["position"]
	return hit_position.distance_to(ray_to) <= 0.2


func _interaction_label(target: Node3D) -> String:
	match String(target.get_meta("kind", "")):
		"wood":
			return "목재 줍기"
		"stone":
			return "돌 줍기"
		"souvenir":
			return "폐허 기념품 발견"
		"bench":
			return "벤치 확인" if _bench_installed else "벤치 제작 (목재 4 · 돌 2)"
		"display":
			return "전시 확인" if _souvenir_displayed else "기념품 전시"
	return "살펴보기"


func _interact_with_nearest() -> void:
	_update_nearest_interactable()
	if _nearest_interactable == null:
		return
	var kind := String(_nearest_interactable.get_meta("kind", ""))
	var pickup_id := String(_nearest_interactable.get_meta("pickup_id", ""))
	match kind:
		"wood":
			_collect_resource(_nearest_interactable, pickup_id, "목재", int(_nearest_interactable.get_meta("amount", 1)), true)
		"stone":
			_collect_resource(_nearest_interactable, pickup_id, "돌", int(_nearest_interactable.get_meta("amount", 1)), false)
		"souvenir":
			_collect_souvenir(_nearest_interactable, pickup_id)
		"bench":
			_install_bench()
		"display":
			_display_souvenir()


func _collect_resource(target: Node3D, pickup_id: String, label: String, amount: int, is_wood: bool) -> void:
	if _collected_ids.has(pickup_id):
		return
	_collected_ids[pickup_id] = true
	if is_wood:
		_wood += amount
	else:
		_stone += amount
	target.visible = false
	target.set_meta("active", false)
	_refresh_hud()
	_save_after_change("%s +%d" % [label, amount])


func _collect_souvenir(target: Node3D, pickup_id: String) -> void:
	if _souvenir_owned or _collected_ids.has(pickup_id):
		return
	_collected_ids[pickup_id] = true
	_souvenir_owned = true
	target.visible = false
	target.set_meta("active", false)
	_refresh_hud()
	_save_after_change("Green Coast 기념품을 발견했습니다.")


func _install_bench() -> void:
	if _bench_installed:
		_show_message("벤치는 이미 설치되어 있습니다.", false)
		return
	if _wood < BENCH_WOOD_COST or _stone < BENCH_STONE_COST:
		_show_message("재료가 부족합니다. 목재 4개와 돌 2개가 필요합니다.", true)
		return
	_wood -= BENCH_WOOD_COST
	_stone -= BENCH_STONE_COST
	_bench_installed = true
	_apply_progress_to_world()
	_refresh_hud()
	_save_after_change("거점에 벤치를 설치했습니다.")


func _display_souvenir() -> void:
	if _souvenir_displayed:
		_show_message("기념품이 이미 전시되어 있습니다.", false)
		return
	if not _souvenir_owned:
		_show_message("폐허에서 기념품을 먼저 찾아야 합니다.", true)
		return
	_souvenir_displayed = true
	_apply_progress_to_world()
	_refresh_hud()
	_save_after_change("기념품을 거점에 전시했습니다.")


func _save_after_change(success_message: String) -> void:
	if _save_game():
		_show_message(success_message + "  저장 완료.", false)
	else:
		_show_message(success_message + "  저장에는 실패했습니다.", true)


func _reset_progress() -> void:
	_wood = 0
	_stone = 0
	_collected_ids.clear()
	_souvenir_owned = false
	_souvenir_displayed = false
	_bench_installed = false
	_vista_seen = false
	_apply_progress_to_world()
	_refresh_hud()


func _apply_progress_to_world() -> void:
	if _interactables == null:
		return
	for child in _interactables.get_children():
		var target := child as Node3D
		if target == null:
			continue
		var kind := String(target.get_meta("kind", ""))
		var pickup_id := String(target.get_meta("pickup_id", ""))
		if kind == "wood" or kind == "stone" or kind == "souvenir":
			var collected := _collected_ids.has(pickup_id)
			target.visible = not collected
			target.set_meta("active", not collected)
	if _bench_visual != null:
		_bench_visual.visible = _bench_installed
	if _display_visual != null:
		_display_visual.visible = _souvenir_displayed


func _refresh_hud() -> void:
	var souvenir_text := "보유" if _souvenir_owned else "미발견"
	if _souvenir_displayed:
		souvenir_text = "전시됨"
	(get_node("UI/HUD/Stats/VBox/ResourceLabel") as Label).text = "목재 %d   돌 %d   기념품 %s" % [_wood, _stone, souvenir_text]
	(get_node("UI/HUD/Stats/VBox/ObjectiveLabel") as Label).text = "현재 목표: " + _current_objective()


func _current_objective() -> String:
	if _bench_installed and _souvenir_displayed:
		return "첫 탐험·귀환 루프 완료"
	if _wood < BENCH_WOOD_COST or _stone < BENCH_STONE_COST:
		return "왼쪽 작은 숲에서 목재 4개·돌 2개 모으기"
	if not _souvenir_owned:
		return "오른쪽 폐허에서 빛나는 기념품 찾기"
	if not _vista_seen:
		return "북쪽 절벽 끝까지 가서 아래 바다 내려다보기"
	if not _bench_installed:
		return "중앙 지름길로 거점에 돌아가 벤치 설치"
	if not _souvenir_displayed:
		return "거점 오른쪽 전시 자리에 기념품 놓기"
	return "Green Coast 둘러보기"


func _show_message(message: String, is_error: bool) -> void:
	var panel := get_node("UI/Toast") as Control
	var label := get_node("UI/Toast/Label") as Label
	label.text = message
	label.modulate = Color(1.0, 0.68, 0.64) if is_error else Color(0.9, 1.0, 0.82)
	panel.visible = true
	_toast_timer.start(3.2)


func _hide_toast() -> void:
	get_node("UI/Toast").visible = false


func _set_start_message(message: String, is_error: bool) -> void:
	var label := get_node("UI/StartMenu/Panel/VBox/Message") as Label
	label.text = message
	label.modulate = Color(1.0, 0.55, 0.5) if is_error else Color(0.8, 0.9, 1.0)


func _refresh_start_menu() -> void:
	var has_save := FileAccess.file_exists(_save_path())
	(get_node("UI/StartMenu/Panel/VBox/ContinueButton") as Button).disabled = not has_save
	_set_start_message("저장된 시험이 있습니다." if has_save else "새 시험을 시작하세요.", false)


func _save_path() -> String:
	return save_path_override if not save_path_override.is_empty() else SAVE_FILE


func _backup_path() -> String:
	if save_path_override.is_empty():
		return SAVE_BACKUP_FILE
	return save_path_override + ".previous"


func _save_game() -> bool:
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
	}
	var temp_path := path + ".tmp"
	if not _write_text_file(temp_path, JSON.stringify(data, "\t")):
		return false
	var temp_result := _read_and_validate_save(temp_path)
	if not temp_result.get("ok", false):
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


func _write_text_file(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	file.close()
	return FileAccess.file_exists(path)


func _load_save_data() -> Dictionary:
	var result := _read_and_validate_save(_save_path())
	if not result.get("ok", false):
		return result
	var data: Dictionary = result["data"]
	return {
		"ok": true,
		"data": data,
		"position": Vector3(float(data["player_position"][0]), float(data["player_position"][1]), float(data["player_position"][2])),
	}


func _read_and_validate_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "message": "M02 저장 파일이 없습니다."}
	var text := FileAccess.get_file_as_string(path)
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {"ok": false, "message": "M02 저장 파일의 JSON 형식이 올바르지 않습니다."}
	var parsed: Variant = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "message": "M02 저장 파일의 JSON 형식이 올바르지 않습니다."}
	var data: Dictionary = parsed
	if not _is_valid_save_dictionary(data):
		return {"ok": false, "message": "M02 저장 버전 또는 내용이 올바르지 않습니다. 원본은 변경하지 않았습니다."}
	return {"ok": true, "data": data}


func _is_valid_save_dictionary(data: Dictionary) -> bool:
	var required := ["version", "region_id", "player_position", "wood", "stone", "collected_ids", "souvenir_owned", "souvenir_displayed", "bench_installed"]
	for key in required:
		if not data.has(key):
			return false
	if int(data["version"]) != SAVE_VERSION or String(data["region_id"]) != REGION_ID:
		return false
	if typeof(data["player_position"]) != TYPE_ARRAY or data["player_position"].size() != 3:
		return false
	for value in data["player_position"]:
		if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
			return false
		if not is_finite(float(value)):
			return false
	if (typeof(data["wood"]) != TYPE_INT and typeof(data["wood"]) != TYPE_FLOAT) or int(data["wood"]) < 0:
		return false
	if (typeof(data["stone"]) != TYPE_INT and typeof(data["stone"]) != TYPE_FLOAT) or int(data["stone"]) < 0:
		return false
	if typeof(data["collected_ids"]) != TYPE_ARRAY:
		return false
	for pickup_id in data["collected_ids"]:
		if typeof(pickup_id) != TYPE_STRING or not KNOWN_PICKUP_IDS.has(String(pickup_id)):
			return false
	for bool_key in ["souvenir_owned", "souvenir_displayed", "bench_installed"]:
		if typeof(data[bool_key]) != TYPE_BOOL:
			return false
	if data["souvenir_displayed"] and not data["souvenir_owned"]:
		return false
	return true


func _apply_loaded_data(data: Dictionary) -> void:
	_wood = int(data["wood"])
	_stone = int(data["stone"])
	_collected_ids.clear()
	for pickup_id in data["collected_ids"]:
		_collected_ids[String(pickup_id)] = true
	_souvenir_owned = bool(data["souvenir_owned"])
	_souvenir_displayed = bool(data["souvenir_displayed"])
	_bench_installed = bool(data["bench_installed"])
	_vista_seen = false
	_apply_progress_to_world()
	_refresh_hud()


func _place_player_on_navigation(requested_position: Vector3) -> void:
	_player.call("set_movement_locked", true)
	_player.call("cancel_active_movement")
	var navigation_agent := _player.get_node("NavigationAgent3D") as NavigationAgent3D
	var navigation_map := navigation_agent.get_navigation_map()
	for frame in range(120):
		if navigation_map.is_valid() and NavigationServer3D.map_get_iteration_id(navigation_map) > 0:
			break
		await get_tree().physics_frame
	var safe_position := SAFE_START
	if navigation_map.is_valid() and NavigationServer3D.map_get_iteration_id(navigation_map) > 0:
		var closest := NavigationServer3D.map_get_closest_point(navigation_map, requested_position)
		if _horizontal_distance(closest, requested_position) <= 1.0:
			safe_position = Vector3(closest.x, SAFE_START.y, closest.z)
	_player.global_position = safe_position
	_player.velocity = Vector3.ZERO
	_camera.global_position.x = safe_position.x + _normal_horizontal_offset.x
	_camera.global_position.z = safe_position.z + _normal_horizontal_offset.y


func _sorted_collected_ids() -> Array:
	var ids := _collected_ids.keys()
	ids.sort()
	return ids


func get_progress_snapshot() -> Dictionary:
	return {
		"flow_mode": FlowMode.keys()[_flow_mode],
		"wood": _wood,
		"stone": _stone,
		"collected_ids": _sorted_collected_ids(),
		"souvenir_owned": _souvenir_owned,
		"souvenir_displayed": _souvenir_displayed,
		"bench_installed": _bench_installed,
		"vista_seen": _vista_seen,
		"objective": _current_objective(),
	}


func _build_green_coast() -> void:
	if has_node("GeneratedWorld"):
		return
	_prepare_materials()
	var world := Node3D.new()
	world.name = "GeneratedWorld"
	add_child(world)
	var region := get_node("NavigationRegion3D") as NavigationRegion3D

	_add_path(world, "PathHomeForest", Vector3(0, 0.02, 5.3), Vector3(-8, 0.02, 1.8), 2.3)
	_add_path(world, "PathForestRuin", Vector3(-8, 0.02, 1.8), Vector3(8, 0.02, -1.8), 2.3)
	_add_path(world, "PathRuinVista", Vector3(8, 0.02, -1.8), Vector3(0, 0.02, -8.8), 2.3)
	_add_path(world, "ShortcutHomeVista", Vector3(0, 0.025, -8.8), Vector3(0, 0.025, 5.3), 1.55)

	_add_static_box(region, "BoundaryWest", Vector3(-14.85, 0.75, 0), Vector3(0.3, 3, 23.4), null)
	_add_static_box(region, "BoundaryEast", Vector3(14.85, 0.75, 0), Vector3(0.3, 3, 23.4), null)
	_add_static_box(region, "BoundarySouth", Vector3(0, 0.75, 11.85), Vector3(29.4, 3, 0.3), null)
	_add_static_box(region, "BoundaryNorth", Vector3(0, 0.75, -11.85), Vector3(29.4, 3, 0.3), null)
	_add_visual_box(world, "FenceWest", Vector3(-14.85, 0.58, 0), Vector3(0.3, 1.15, 23.4), _wood_material)
	_add_visual_box(world, "FenceEast", Vector3(14.85, 0.58, 0), Vector3(0.3, 1.15, 23.4), _wood_material)
	_add_visual_box(world, "FenceSouth", Vector3(0, 0.58, 11.85), Vector3(29.4, 1.15, 0.3), _wood_material)

	_add_static_box(region, "Hut", Vector3(6.5, 1.4, 8.9), Vector3(5.2, 2.8, 3.2), _hut_material)
	_add_visual_box(world, "HutRoof", Vector3(6.5, 3.15, 8.9), Vector3(6.0, 0.55, 4.0), _roof_material, deg_to_rad(45.0), Vector3(0, 0, 1))
	_add_visual_box(world, "HutDoor", Vector3(6.5, 1.05, 7.27), Vector3(1.15, 2.1, 0.08), _wood_material)

	for tree_data in [
		["TreeA", Vector3(-11.2, 0, 3.8)], ["TreeB", Vector3(-9.2, 0, 5.0)],
		["TreeC", Vector3(-12.0, 0, 0.2)], ["TreeD", Vector3(-8.0, 0, -2.8)],
		["TreeE", Vector3(-5.8, 0, 3.6)], ["TreeF", Vector3(-11.0, 0, -3.4)],
	]:
		_add_tree(region, tree_data[0], tree_data[1])

	_add_static_box(region, "RuinBack", Vector3(8.5, 1.15, -4.8), Vector3(6.0, 2.3, 0.45), _ruin_material)
	_add_static_box(region, "RuinLeft", Vector3(5.7, 0.85, -2.9), Vector3(0.45, 1.7, 3.4), _ruin_material)
	_add_static_box(region, "RuinRight", Vector3(11.3, 1.25, -3.2), Vector3(0.45, 2.5, 2.8), _ruin_material)
	_add_visual_box(world, "RuinArch", Vector3(8.5, 2.5, -2.6), Vector3(3.1, 0.45, 0.45), _ruin_material)

	_add_rock_obstacle(region, "CoastRockLeft", Vector3(-4.3, 0, -8.0), 1.6, Vector3(2.5, 1.55, 2.0), -18.0)
	_add_rock_obstacle(region, "CoastRockRight", Vector3(4.8, 0, -7.2), 1.35, Vector3(2.1, 1.35, 1.8), 28.0)
	_add_rock_obstacle(region, "ForestRock", Vector3(-5.2, 0, -0.7), 1.0, Vector3(1.6, 1.0, 1.3), 12.0)
	_add_far_rock(world, "FarIsland", Vector3(-3.0, -1.2, -29), 6.4, 24.0)
	_add_far_rock(world, "FarRock", Vector3(11.5, -1.2, -34), 3.8, -38.0)

	_add_visual_box(world, "CliffFace", Vector3(0, -0.9, -12.5), Vector3(31, 1.8, 1.6), _stone_material)
	_add_visual_box(world, "Beach", Vector3(0, -1.2, -15.0), Vector3(32, 0.25, 4.0), _slot_material)

	_interactables = Node3D.new()
	_interactables.name = "Interactables"
	add_child(_interactables)
	_add_pickup("Wood01", "wood", "wood_gc_01", Vector3(-7.2, 0.24, 3.0), _wood_material)
	_add_pickup("Wood02", "wood", "wood_gc_02", Vector3(-10.0, 0.24, 2.2), _wood_material)
	_add_pickup("Wood03", "wood", "wood_gc_03", Vector3(-8.8, 0.24, -0.4), _wood_material)
	_add_pickup("Wood04", "wood", "wood_gc_04", Vector3(-11.6, 0.24, -1.8), _wood_material)
	_add_pickup("Wood05", "wood", "wood_gc_05", Vector3(-6.8, 0.24, 0.6), _wood_material)
	_add_pickup("Stone01", "stone", "stone_gc_01", Vector3(-10.7, 0.25, 4.2), _stone_material)
	_add_pickup("Stone02", "stone", "stone_gc_02", Vector3(-9.7, 0.25, -2.0), _stone_material)
	_add_pickup("Stone03", "stone", "stone_gc_03", Vector3(-6.4, 0.25, 2.2), _stone_material)
	_add_souvenir("Souvenir", Vector3(8.5, 0.45, -3.2))
	_add_slot("BenchSlot", "bench", Vector3(-3.8, 0.04, 7.0))
	_add_slot("DisplaySlot", "display", Vector3(2.8, 0.04, 7.0))

	_bench_visual = _make_bench(world, Vector3(-3.8, 0, 7.0))
	_bench_visual.name = "BenchInstalled"
	_display_visual = _make_display(world, Vector3(2.8, 0, 7.0))
	_display_visual.name = "SouvenirDisplayed"


func _prepare_materials() -> void:
	_ground_material = _make_material(Color(0.25, 0.43, 0.24))
	_path_material = _make_material(Color(0.54, 0.44, 0.31))
	_wood_material = _make_material(Color(0.34, 0.20, 0.10))
	_leaf_material = _make_material(Color(0.16, 0.42, 0.19))
	_stone_material = _make_material(Color(0.38, 0.40, 0.39))
	_ruin_material = _make_material(Color(0.56, 0.50, 0.39))
	_hut_material = _make_material(Color(0.48, 0.30, 0.16))
	_roof_material = _make_material(Color(0.20, 0.30, 0.22))
	_slot_material = _make_material(Color(0.74, 0.61, 0.38))
	_souvenir_material = _make_material(Color(0.20, 0.85, 0.92), Color(0.08, 0.58, 0.72))
	_bench_material = _make_material(Color(0.62, 0.38, 0.16))


func _make_material(color: Color, emission := Color(0, 0, 0, 0)) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	if emission.a > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 1.5
	return material


func _add_path(parent: Node3D, node_name: String, from: Vector3, to: Vector3, width: float) -> void:
	var delta := to - from
	var mesh := BoxMesh.new()
	mesh.material = _path_material
	mesh.size = Vector3(width, 0.04, delta.length())
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = (from + to) * 0.5
	instance.rotation.y = atan2(delta.x, delta.z)
	parent.add_child(instance)


func _add_static_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	parent.add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	body.add_child(collision)
	if material != null:
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh.material = material
		var visual := MeshInstance3D.new()
		visual.name = "Visual"
		visual.mesh = mesh
		body.add_child(visual)
	return body


func _add_visual_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material, angle := 0.0, axis := Vector3.UP) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.position = position
	visual.rotate(axis, angle)
	parent.add_child(visual)
	return visual


func _add_tree(parent: Node3D, node_name: String, position: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	parent.add_child(body)
	var shape := CylinderShape3D.new()
	shape.radius = 0.58
	shape.height = 2.2
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 1.1
	body.add_child(collision)
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.32
	trunk_mesh.bottom_radius = 0.45
	trunk_mesh.height = 2.2
	trunk_mesh.material = _wood_material
	var trunk := MeshInstance3D.new()
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.1
	body.add_child(trunk)
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.15
	crown_mesh.height = 2.0
	crown_mesh.radial_segments = 8
	crown_mesh.rings = 4
	crown_mesh.material = _leaf_material
	var crown := MeshInstance3D.new()
	crown.mesh = crown_mesh
	crown.position.y = 2.65
	body.add_child(crown)


func _add_rock_obstacle(parent: Node3D, node_name: String, position: Vector3, scale_value: float, collision_size: Vector3, yaw_degrees: float) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.rotation_degrees.y = yaw_degrees
	parent.add_child(body)
	var shape := BoxShape3D.new()
	shape.size = collision_size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = collision_size.y * 0.5
	body.add_child(collision)
	var rock_scene := load("res://assets/prototype/blender/rocks/b2_rock_01.glb") as PackedScene
	var rock := rock_scene.instantiate() as Node3D
	rock.name = "Visual"
	rock.scale = Vector3.ONE * scale_value
	body.add_child(rock)


func _add_far_rock(parent: Node3D, node_name: String, position: Vector3, scale_value: float, yaw_degrees: float) -> void:
	var rock_scene := load("res://assets/prototype/blender/rocks/b2_rock_01.glb") as PackedScene
	var rock := rock_scene.instantiate() as Node3D
	rock.name = node_name
	rock.position = position
	rock.rotation_degrees.y = yaw_degrees
	rock.scale = Vector3.ONE * scale_value
	parent.add_child(rock)


func _add_pickup(node_name: String, kind: String, pickup_id: String, position: Vector3, material: Material) -> void:
	var pickup := Node3D.new()
	pickup.name = node_name
	pickup.position = position
	pickup.set_meta("kind", kind)
	pickup.set_meta("pickup_id", pickup_id)
	pickup.set_meta("amount", 1)
	pickup.set_meta("active", true)
	_interactables.add_child(pickup)
	var mesh: PrimitiveMesh
	if kind == "wood":
		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.18
		log_mesh.bottom_radius = 0.22
		log_mesh.height = 0.9
		log_mesh.radial_segments = 8
		mesh = log_mesh
	else:
		var rock_mesh := BoxMesh.new()
		rock_mesh.size = Vector3(0.55, 0.4, 0.48)
		mesh = rock_mesh
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	if kind == "wood":
		visual.rotation_degrees.z = 90.0
	pickup.add_child(visual)
	_add_pickup_ring(pickup)


func _add_souvenir(node_name: String, position: Vector3) -> void:
	var pickup := Node3D.new()
	pickup.name = node_name
	pickup.position = position
	pickup.set_meta("kind", "souvenir")
	pickup.set_meta("pickup_id", "souvenir_green_coast")
	pickup.set_meta("active", true)
	_interactables.add_child(pickup)
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.12
	mesh.bottom_radius = 0.42
	mesh.height = 0.9
	mesh.radial_segments = 6
	mesh.material = _souvenir_material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	pickup.add_child(visual)
	_add_pickup_ring(pickup)


func _add_slot(node_name: String, kind: String, position: Vector3) -> void:
	var slot := Node3D.new()
	slot.name = node_name
	slot.position = position
	slot.set_meta("kind", kind)
	slot.set_meta("active", true)
	_interactables.add_child(slot)
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.85
	mesh.bottom_radius = 0.85
	mesh.height = 0.05
	mesh.radial_segments = 20
	mesh.material = _slot_material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	slot.add_child(visual)


func _add_pickup_ring(parent: Node3D) -> void:
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 0.38
	ring_mesh.bottom_radius = 0.38
	ring_mesh.height = 0.025
	ring_mesh.radial_segments = 16
	ring_mesh.material = _slot_material
	var ring := MeshInstance3D.new()
	ring.mesh = ring_mesh
	ring.position.y = -parent.position.y + 0.025
	parent.add_child(ring)


func _make_bench(parent: Node3D, position: Vector3) -> Node3D:
	var bench := Node3D.new()
	bench.position = position
	parent.add_child(bench)
	_add_visual_box(bench, "Seat", Vector3(0, 0.72, 0), Vector3(2.4, 0.25, 0.75), _bench_material)
	_add_visual_box(bench, "Back", Vector3(0, 1.25, 0.32), Vector3(2.4, 0.85, 0.18), _bench_material)
	_add_visual_box(bench, "LegLeft", Vector3(-0.85, 0.35, 0), Vector3(0.2, 0.7, 0.55), _wood_material)
	_add_visual_box(bench, "LegRight", Vector3(0.85, 0.35, 0), Vector3(0.2, 0.7, 0.55), _wood_material)
	return bench


func _make_display(parent: Node3D, position: Vector3) -> Node3D:
	var display := Node3D.new()
	display.position = position
	parent.add_child(display)
	_add_visual_box(display, "Plinth", Vector3(0, 0.45, 0), Vector3(0.9, 0.9, 0.9), _ruin_material)
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.10
	mesh.bottom_radius = 0.34
	mesh.height = 0.72
	mesh.radial_segments = 6
	mesh.material = _souvenir_material
	var souvenir := MeshInstance3D.new()
	souvenir.mesh = mesh
	souvenir.position.y = 1.15
	display.add_child(souvenir)
	return display


func _horizontal_distance(from: Vector3, to: Vector3) -> float:
	var offset := to - from
	offset.y = 0.0
	return offset.length()
