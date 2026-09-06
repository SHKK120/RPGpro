extends Node3D

enum VistaState { PLAY, ENTERING, VISTA, RETURNING }

@export_node_path("CharacterBody3D") var player_path: NodePath
@export_node_path("Camera3D") var camera_path: NodePath
@export_node_path("Node3D") var vista_point_path: NodePath
@export_node_path("Node3D") var vista_camera_anchor_path: NodePath
@export_node_path("Node3D") var vista_look_target_path: NodePath
@export_node_path("Control") var vista_prompt_path: NodePath
@export_node_path("Label") var vista_prompt_label_path: NodePath
@export var vista_activation_distance := 2.4
@export var camera_transition_time := 0.9
@export var vista_fov := 45.0

var _player: CharacterBody3D
var _camera: Camera3D
var _vista_point: Node3D
var _vista_camera_anchor: Node3D
var _vista_look_target: Node3D
var _vista_prompt: Control
var _vista_prompt_label: Label
var _normal_horizontal_offset := Vector2.ZERO
var _normal_fixed_height := 0.0
var _normal_camera_basis := Basis.IDENTITY
var _normal_camera_fov := 75.0
var _vista_state := VistaState.PLAY
var _camera_transition: Tween

const DIRECT_MOVE_ACTIONS := [&"move_left", &"move_right", &"move_forward", &"move_back"]


func _ready() -> void:
	_player = get_node_or_null(player_path) as CharacterBody3D
	_camera = get_node_or_null(camera_path) as Camera3D
	_vista_point = get_node_or_null(vista_point_path) as Node3D
	_vista_camera_anchor = get_node_or_null(vista_camera_anchor_path) as Node3D
	_vista_look_target = get_node_or_null(vista_look_target_path) as Node3D
	_vista_prompt = get_node_or_null(vista_prompt_path) as Control
	_vista_prompt_label = get_node_or_null(vista_prompt_label_path) as Label

	if _player == null or _camera == null or _vista_point == null or _vista_camera_anchor == null or _vista_look_target == null:
		push_error("M01 coast preview is missing a required player, camera, or vista node.")
		set_process(false)
		set_process_unhandled_input(false)
		return

	_normal_horizontal_offset = Vector2(
		_camera.global_position.x - _player.global_position.x,
		_camera.global_position.z - _player.global_position.z,
	)
	_normal_fixed_height = _camera.global_position.y
	_normal_camera_basis = _camera.global_transform.basis
	_normal_camera_fov = _camera.fov
	_update_vista_prompt()


func _process(_delta: float) -> void:
	_update_vista_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("view_vista"):
		if _vista_state == VistaState.PLAY and is_player_near_vista():
			enter_vista()
		elif _vista_state == VistaState.ENTERING or _vista_state == VistaState.VISTA:
			exit_vista()
		get_viewport().set_input_as_handled()
		return

	if _vista_state == VistaState.PLAY:
		return

	if event.is_action_pressed("ui_cancel") or _event_is_direct_move(event):
		exit_vista()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_to_point"):
		get_viewport().set_input_as_handled()


func enter_vista() -> bool:
	if _vista_state != VistaState.PLAY or not is_player_near_vista():
		return false

	_player.call("set_movement_locked", true)
	_player.call("cancel_active_movement")
	_camera.set_process(false)
	_vista_state = VistaState.ENTERING
	_start_camera_transition(_vista_transform(), vista_fov, camera_transition_time, _finish_vista_entry)
	_update_vista_prompt()
	return true


func exit_vista() -> bool:
	if _vista_state == VistaState.PLAY or _vista_state == VistaState.RETURNING:
		return false

	_vista_state = VistaState.RETURNING
	_start_camera_transition(_normal_camera_transform(), _normal_camera_fov, camera_transition_time, _finish_vista_return)
	_update_vista_prompt()
	return true


func is_player_near_vista() -> bool:
	if _player == null or _vista_point == null:
		return false
	var offset := _player.global_position - _vista_point.global_position
	offset.y = 0.0
	return offset.length() <= vista_activation_distance


func get_vista_state_name() -> String:
	return VistaState.keys()[_vista_state]


func _event_is_direct_move(event: InputEvent) -> bool:
	for action in DIRECT_MOVE_ACTIONS:
		if event.is_action_pressed(action):
			return true
	return false


func _vista_transform() -> Transform3D:
	var player_offset := _player.global_position - _vista_point.global_position
	player_offset.y = 0.0
	return Transform3D(Basis.IDENTITY, _vista_camera_anchor.global_position + player_offset).looking_at(
		_vista_look_target.global_position + player_offset,
		Vector3.UP,
	)


func _normal_camera_transform() -> Transform3D:
	var return_position := Vector3(
		_player.global_position.x + _normal_horizontal_offset.x,
		_normal_fixed_height,
		_player.global_position.z + _normal_horizontal_offset.y,
	)
	return Transform3D(_normal_camera_basis, return_position)


func _start_camera_transition(target_transform: Transform3D, target_fov: float, duration: float, finished_callback: Callable) -> void:
	if _camera_transition != null and _camera_transition.is_valid():
		_camera_transition.kill()
	_camera_transition = create_tween()
	_camera_transition.set_trans(Tween.TRANS_CUBIC)
	_camera_transition.set_ease(Tween.EASE_IN_OUT)
	_camera_transition.set_parallel(true)
	_camera_transition.tween_property(_camera, "global_transform", target_transform, maxf(duration, 0.01))
	_camera_transition.tween_property(_camera, "fov", target_fov, maxf(duration, 0.01))
	_camera_transition.finished.connect(finished_callback)


func _finish_vista_entry() -> void:
	if _vista_state == VistaState.ENTERING:
		_vista_state = VistaState.VISTA
		_update_vista_prompt()


func _finish_vista_return() -> void:
	if _vista_state != VistaState.RETURNING:
		return
	_camera.global_transform = _normal_camera_transform()
	_camera.fov = _normal_camera_fov
	_camera.set_process(true)
	_player.call("set_movement_locked", false)
	_vista_state = VistaState.PLAY
	_update_vista_prompt()


func _update_vista_prompt() -> void:
	if _vista_prompt == null or _vista_prompt_label == null:
		return
	if _vista_state == VistaState.PLAY:
		_vista_prompt.visible = is_player_near_vista()
		_vista_prompt_label.text = "E: 전망 보기"
	elif _vista_state == VistaState.RETURNING:
		_vista_prompt.visible = true
		_vista_prompt_label.text = "평상 시점으로 돌아가는 중"
	else:
		_vista_prompt.visible = true
		_vista_prompt_label.text = "E / Esc / WASD: 돌아가기"
