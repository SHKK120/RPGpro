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
var _movement_floor_height := NAN
var _automatic_move := false
var _destination := Vector3.ZERO
var _pending_ray_origin := Vector3.ZERO
var _pending_ray_direction := Vector3.ZERO
var _has_pending_click := false
var _last_progress_position := Vector3.ZERO
var _stuck_elapsed := 0.0

const DIRECT_MOVE_ACTIONS := [&"move_left", &"move_right", &"move_forward", &"move_back"]
const CLICK_RAY_LENGTH := 1000.0


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
	else:
		_resolve_movement_floor_height()
	if _destination_marker == null:
		push_error("P1-2 click movement requires a destination marker; click movement is disabled.")
	else:
		_destination_marker.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("move_to_point"):
		return
	if _has_direct_move_key_pressed() or _movement_camera == null or not _navigation_is_ready():
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event == null:
		return
	if not get_viewport().get_visible_rect().has_point(mouse_event.position):
		return
	_pending_ray_origin = _movement_camera.project_ray_origin(mouse_event.position)
	_pending_ray_direction = _movement_camera.project_ray_normal(mouse_event.position)
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
	if not _navigation_is_ready() or not is_finite(_movement_floor_height):
		return

	var ray_origin := _pending_ray_origin
	var ray_direction := _pending_ray_direction
	if not _is_finite_vector(ray_origin) or not _is_finite_vector(ray_direction) or ray_direction.length_squared() <= 0.000001:
		return
	ray_direction = ray_direction.normalized()
	var ray_end := ray_origin + ray_direction * CLICK_RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var intent_position: Variant = null

	if hit.is_empty():
		intent_position = _intersect_movement_plane(ray_origin, ray_direction)
	else:
		var collider := hit.get("collider") as CollisionObject3D
		if collider == _movement_floor:
			var hit_normal: Vector3 = hit["normal"]
			if hit_normal.dot(Vector3.UP) < 0.9:
				return
			intent_position = hit["position"]
		elif _is_supported_click_obstacle(collider):
			var hit_position: Vector3 = hit["position"]
			intent_position = Vector3(hit_position.x, _movement_floor_height, hit_position.z)
		else:
			return

	if intent_position == null:
		return
	_try_accept_destination(intent_position, true)


func _try_accept_destination(clicked_position: Vector3, allow_distant_snap := false) -> bool:
	var navigation_map := _navigation_agent.get_navigation_map()
	var navigation_target := NavigationServer3D.map_get_closest_point(navigation_map, clicked_position)
	if not _is_finite_vector(navigation_target):
		return false
	if not allow_distant_snap and _horizontal_distance(clicked_position, navigation_target) > destination_snap_tolerance:
		return false

	var navigation_start := NavigationServer3D.map_get_closest_point(navigation_map, global_position)
	var proposed_path := NavigationServer3D.map_get_path(
		navigation_map,
		navigation_start,
		navigation_target,
		true,
		_navigation_agent.navigation_layers,
	)
	if proposed_path.is_empty():
		return false
	var reachable_target: Vector3 = proposed_path[proposed_path.size() - 1]
	if not _is_finite_vector(reachable_target):
		return false
	if not allow_distant_snap and _horizontal_distance(reachable_target, navigation_target) > destination_snap_tolerance:
		return false

	if _horizontal_distance(global_position, reachable_target) <= arrival_distance:
		_finish_click_movement()
		return true

	_destination = reachable_target
	_navigation_agent.target_position = reachable_target
	_automatic_move = true
	_last_progress_position = global_position
	_stuck_elapsed = 0.0
	_destination_marker.global_position = Vector3(
		reachable_target.x,
		_movement_floor_height + 0.04,
		reachable_target.z,
	)
	_destination_marker.visible = true
	return true


func _resolve_movement_floor_height() -> void:
	var floor_collision := _movement_floor.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if floor_collision == null:
		push_error("P1-4 destination correction requires the movement floor CollisionShape3D.")
		return
	var floor_box := floor_collision.shape as BoxShape3D
	if floor_box == null:
		push_error("P1-4 destination correction requires the current box-shaped movement floor.")
		return
	var floor_top := floor_collision.global_transform * Vector3(0.0, floor_box.size.y * 0.5, 0.0)
	_movement_floor_height = floor_top.y


func _is_supported_click_obstacle(collider: CollisionObject3D) -> bool:
	if collider == null or collider == _movement_floor:
		return false
	return collider is StaticBody3D and collider.get_parent() == _movement_floor.get_parent()


func _intersect_movement_plane(ray_origin: Vector3, ray_direction: Vector3) -> Variant:
	var plane_hit: Variant = Plane(Vector3.UP, _movement_floor_height).intersects_ray(ray_origin, ray_direction)
	if plane_hit == null:
		return null
	var intersection: Vector3 = plane_hit
	var ray_offset := intersection - ray_origin
	if not _is_finite_vector(intersection) or ray_offset.dot(ray_direction) <= 0.0:
		return null
	if ray_offset.length() > CLICK_RAY_LENGTH:
		return null
	return intersection


func _is_finite_vector(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)


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
