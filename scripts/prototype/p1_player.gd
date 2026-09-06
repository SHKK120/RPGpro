extends CharacterBody3D

@export var move_speed: float = 4.0
@export var destination_snap_tolerance: float = 0.75
@export var arrival_distance: float = 0.35
@export var stuck_timeout: float = 1.5
@export_node_path("Camera3D") var camera_path: NodePath
@export_node_path("NavigationAgent3D") var navigation_agent_path: NodePath
@export_node_path("StaticBody3D") var movement_floor_path: NodePath
@export_node_path("MeshInstance3D") var destination_marker_path: NodePath

var _movement_camera: Camera3D
var _navigation_agent: NavigationAgent3D
var _movement_floor: StaticBody3D
var _destination_marker: MeshInstance3D
var _automatic_move := false
var _destination := Vector3.ZERO
var _pending_click_position := Vector2.ZERO
var _has_pending_click := false
var _last_progress_position := Vector3.ZERO
var _stuck_elapsed := 0.0

const DIRECT_MOVE_ACTIONS := [&"move_left", &"move_right", &"move_forward", &"move_back"]


func _ready() -> void:
	_movement_camera = get_node_or_null(camera_path) as Camera3D
	_navigation_agent = get_node_or_null(navigation_agent_path) as NavigationAgent3D
	_movement_floor = get_node_or_null(movement_floor_path) as StaticBody3D
	_destination_marker = get_node_or_null(destination_marker_path) as MeshInstance3D

	if _movement_camera == null:
		push_error("P1 player requires a Camera3D assigned to camera_path; horizontal movement is disabled.")
	if _navigation_agent == null:
		push_error("P1-2 click movement requires a NavigationAgent3D; click movement is disabled.")
	if _movement_floor == null:
		push_error("P1-2 click movement requires the explicit movement floor; click movement is disabled.")
	if _destination_marker == null:
		push_error("P1-2 click movement requires a destination marker; click movement is disabled.")
	else:
		_destination_marker.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("move_to_point"):
		return
	if _has_direct_move_key_pressed() or not _navigation_is_ready():
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event == null:
		return
	_pending_click_position = mouse_event.position
	_has_pending_click = true


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_direction := Vector3.ZERO
	var direct_move_pressed := _has_direct_move_key_pressed()

	if direct_move_pressed:
		_cancel_click_movement()
		_has_pending_click = false
		move_direction = _camera_relative_direction(input_vector)
	else:
		if _has_pending_click:
			_consume_pending_click()
		if _automatic_move:
			move_direction = _automatic_move_direction()

	velocity.x = move_direction.x * move_speed
	velocity.z = move_direction.z * move_speed

	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity += get_gravity() * delta

	move_and_slide()

	if _automatic_move:
		_update_automatic_progress(delta)


func _camera_relative_direction(input_vector: Vector2) -> Vector3:
	if _movement_camera == null:
		return Vector3.ZERO

	var camera_right := _movement_camera.global_transform.basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()

	var camera_forward := -_movement_camera.global_transform.basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()

	var direction := camera_right * input_vector.x + camera_forward * -input_vector.y
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	return direction


func _has_direct_move_key_pressed() -> bool:
	for action in DIRECT_MOVE_ACTIONS:
		if Input.is_action_pressed(action):
			return true
	return false


func _navigation_is_ready() -> bool:
	if _navigation_agent == null:
		return false
	var navigation_map := _navigation_agent.get_navigation_map()
	return navigation_map.is_valid() and NavigationServer3D.map_get_iteration_id(navigation_map) > 0


func _consume_pending_click() -> void:
	_has_pending_click = false
	if _movement_camera == null or _movement_floor == null or _navigation_agent == null or _destination_marker == null:
		return
	if not _navigation_is_ready():
		return

	var ray_origin := _movement_camera.project_ray_origin(_pending_click_position)
	var ray_end := ray_origin + _movement_camera.project_ray_normal(_pending_click_position) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.get("collider") != _movement_floor:
		return

	var hit_normal: Vector3 = hit["normal"]
	if hit_normal.dot(Vector3.UP) < 0.9:
		return
	_try_accept_destination(hit["position"])


func _try_accept_destination(clicked_position: Vector3) -> void:
	var navigation_map := _navigation_agent.get_navigation_map()
	var navigation_target := NavigationServer3D.map_get_closest_point(navigation_map, clicked_position)
	if _horizontal_distance(clicked_position, navigation_target) > destination_snap_tolerance:
		return

	if _horizontal_distance(global_position, navigation_target) <= arrival_distance:
		_finish_click_movement()
		return

	var navigation_start := NavigationServer3D.map_get_closest_point(navigation_map, global_position)
	var proposed_path := NavigationServer3D.map_get_path(navigation_map, navigation_start, navigation_target, true)
	if proposed_path.is_empty():
		return
	if _horizontal_distance(proposed_path[proposed_path.size() - 1], navigation_target) > destination_snap_tolerance:
		return

	_destination = navigation_target
	_navigation_agent.target_position = navigation_target
	_automatic_move = true
	_last_progress_position = global_position
	_stuck_elapsed = 0.0
	_destination_marker.global_position = Vector3(
		navigation_target.x,
		clicked_position.y + 0.04,
		navigation_target.z,
	)
	_destination_marker.visible = true


func _automatic_move_direction() -> Vector3:
	if _navigation_agent == null or not _navigation_is_ready():
		_finish_click_movement()
		return Vector3.ZERO
	if _horizontal_distance(global_position, _destination) <= arrival_distance:
		_finish_click_movement()
		return Vector3.ZERO

	var next_path_position := _navigation_agent.get_next_path_position()
	if _navigation_agent.is_navigation_finished():
		push_warning("P1-2 navigation ended before the accepted destination was reached.")
		_finish_click_movement()
		return Vector3.ZERO

	var direction := next_path_position - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.000001:
		return Vector3.ZERO
	return direction.normalized()


func _update_automatic_progress(delta: float) -> void:
	var moved := global_position - _last_progress_position
	moved.y = 0.0
	if moved.length() < 0.005:
		_stuck_elapsed += delta
	else:
		_stuck_elapsed = 0.0
	_last_progress_position = global_position

	if _horizontal_distance(global_position, _destination) <= arrival_distance:
		_finish_click_movement()
	elif _stuck_elapsed >= stuck_timeout:
		push_warning("P1-2 click movement stopped after making no progress.")
		_finish_click_movement()


func _cancel_click_movement() -> void:
	_automatic_move = false
	_stuck_elapsed = 0.0
	if _destination_marker != null:
		_destination_marker.visible = false


func _finish_click_movement() -> void:
	_cancel_click_movement()
	velocity.x = 0.0
	velocity.z = 0.0


func _horizontal_distance(from: Vector3, to: Vector3) -> float:
	var offset := to - from
	offset.y = 0.0
	return offset.length()
