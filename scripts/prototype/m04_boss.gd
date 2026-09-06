extends CharacterBody3D

signal defeated
signal health_changed

enum State { DORMANT, INTRO, CHOOSE, MOVE, WINDUP, RECOVER, PHASE_TRANSITION, DEAD }

const MAX_HEALTH := 300.0
const MOVE_SPEED := 2.15
const SWEEP_RANGE := 2.2
const SWEEP_DAMAGE := 20.0
const SWEEP_WINDUP := 0.65
const SWEEP_RECOVER := 0.65
const SLAM_RADIUS := 2.5
const SLAM_DAMAGE := 24.0
const SLAM_WINDUP := 0.9
const SLAM_RECOVER := 0.8
const BURST_DAMAGE := 10.0
const BURST_SPEED := 7.5
const BURST_WINDUP := 0.7
const BURST_RECOVER := 0.72

var _controller: Node
var _player: CharacterBody3D
var _health: Node
var _visual_root: Node3D
var _body_material: StandardMaterial3D
var _warning_circle: MeshInstance3D
var _spawn_position := Vector3.ZERO
var _arena_bounds := Rect2(Vector2(17.35, -9.3), Vector2(10.4, 11.1))
var _state := State.DORMANT
var _state_time_left := 0.0
var _phase := 1
var _attack_name := ""
var _last_attack := ""
var _attack_serial := 0
var _configured := false
var _encounter_active := false
var _base_scale := Vector3.ONE
var _base_color := Color(0.13, 0.42, 0.52)
var _flash_left := 0.0


func _ready() -> void:
	_health = get_node("Health")
	_visual_root = get_node("VisualRoot") as Node3D
	_warning_circle = get_node("WarningCircle") as MeshInstance3D
	_base_scale = _visual_root.scale
	var body := get_node("VisualRoot/Body") as MeshInstance3D
	_body_material = body.material_override as StandardMaterial3D
	if _body_material != null:
		_base_color = _body_material.albedo_color
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	_warning_circle.visible = false


func configure(controller: Node, player: CharacterBody3D, arena_bounds: Rect2) -> void:
	_controller = controller
	_player = player
	_arena_bounds = arena_bounds
	_spawn_position = global_position
	_health.configure(MAX_HEALTH)
	_configured = true


func _physics_process(delta: float) -> void:
	if not _configured:
		return
	_update_hit_flash(delta)
	if _state == State.DEAD or _state == State.DORMANT:
		_stop_horizontal()
		return
	if not _encounter_active or _controller == null or not bool(_controller.call("is_boss_encounter_active")):
		_stop_horizontal()
		return

	_state_time_left = maxf(_state_time_left - delta, 0.0)
	match _state:
		State.INTRO:
			_stop_horizontal()
			_face_player()
			if _state_time_left <= 0.0:
				_state = State.CHOOSE
		State.CHOOSE:
			_choose_next_action()
		State.MOVE:
			_update_move(delta)
		State.WINDUP:
			_stop_horizontal()
			if _state_time_left <= 0.0:
				_perform_attack()
		State.RECOVER:
			_stop_horizontal()
			if _state_time_left <= 0.0:
				_state = State.CHOOSE
		State.PHASE_TRANSITION:
			_stop_horizontal()
			if _state_time_left <= 0.0:
				_clear_telegraph()
				_state = State.CHOOSE

	_apply_gravity(delta)
	move_and_slide()
	_clamp_to_arena()


func activate_encounter() -> void:
	if _state == State.DEAD:
		return
	_encounter_active = true
	_health.restore_full()
	_phase = 1
	_attack_name = ""
	_last_attack = ""
	_attack_serial = 0
	global_position = _spawn_position
	visible = true
	(get_node("CollisionShape3D") as CollisionShape3D).set_deferred("disabled", false)
	_set_state(State.INTRO, 0.8)
	_set_telegraph(Color(0.18, 0.76, 0.92), 1.12)


func reset_for_retry() -> void:
	_encounter_active = false
	global_position = _spawn_position
	velocity = Vector3.ZERO
	_phase = 1
	_attack_name = ""
	_last_attack = ""
	_attack_serial = 0
	_health.restore_full()
	_state = State.DORMANT
	_clear_telegraph()
	visible = true
	(get_node("CollisionShape3D") as CollisionShape3D).set_deferred("disabled", false)


func set_defeated_world_state() -> void:
	_encounter_active = false
	_state = State.DEAD
	velocity = Vector3.ZERO
	_clear_telegraph()
	visible = false
	(get_node("CollisionShape3D") as CollisionShape3D).set_deferred("disabled", true)


func take_melee_hit(amount: float, _direction: Vector3) -> bool:
	if not _encounter_active or _state == State.DEAD:
		return false
	var applied := float(_health.damage(amount))
	if applied <= 0.0:
		return false
	_flash_left = 0.13
	if _health.current_health > 0.0 and _phase == 1 and _health.current_health <= MAX_HEALTH * 0.5:
		_begin_phase_two()
	return true


func _choose_next_action() -> void:
	var distance := _horizontal_distance(global_position, _player.global_position)
	var candidates: Array[String] = ["sweep", "slam"]
	if _phase == 2:
		candidates.append("burst")
	if candidates.size() > 1:
		candidates.erase(_last_attack)
	var choice := candidates[_attack_serial % candidates.size()]
	_attack_serial += 1
	if choice != "burst" and distance > SWEEP_RANGE - 0.2:
		_attack_name = choice
		_state = State.MOVE
		return
	_begin_attack(choice)


func _update_move(_delta: float) -> void:
	var offset := _player.global_position - global_position
	offset.y = 0.0
	if offset.length() <= SWEEP_RANGE - 0.2 or offset.length_squared() <= 0.0001:
		_begin_attack(_attack_name)
		return
	var direction := offset.normalized()
	_face_direction(direction)
	velocity.x = direction.x * MOVE_SPEED
	velocity.z = direction.z * MOVE_SPEED


func _begin_attack(next_attack: String) -> void:
	_attack_name = next_attack
	_last_attack = next_attack
	_face_player()
	match next_attack:
		"sweep":
			_set_state(State.WINDUP, SWEEP_WINDUP)
			_set_telegraph(Color(1.0, 0.34, 0.12), 1.20)
		"slam":
			_set_state(State.WINDUP, SLAM_WINDUP)
			_set_telegraph(Color(0.95, 0.20, 0.46), 1.16)
			_warning_circle.visible = true
			_warning_circle.scale = Vector3(SLAM_RADIUS, 1.0, SLAM_RADIUS)
		"burst":
			_set_state(State.WINDUP, BURST_WINDUP)
			_set_telegraph(Color(0.08, 0.78, 1.0), 1.24)


func _perform_attack() -> void:
	_clear_telegraph()
	match _attack_name:
		"sweep":
			_perform_sweep()
			_set_state(State.RECOVER, SWEEP_RECOVER)
		"slam":
			_perform_slam()
			_set_state(State.RECOVER, SLAM_RECOVER)
		"burst":
			_perform_burst()
			_set_state(State.RECOVER, BURST_RECOVER)


func _perform_sweep() -> void:
	var offset := _player.global_position - global_position
	offset.y = 0.0
	if offset.length() > SWEEP_RANGE + 0.25 or offset.length_squared() <= 0.0001:
		return
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.normalized().dot(offset.normalized()) < 0.2:
		return
	if _has_line_of_sight_to_player():
		_controller.call("damage_player", SWEEP_DAMAGE, global_position)


func _perform_slam() -> void:
	if _horizontal_distance(global_position, _player.global_position) <= SLAM_RADIUS and _has_line_of_sight_to_player():
		_controller.call("damage_player", SLAM_DAMAGE, global_position)


func _perform_burst() -> void:
	var forward := _player.global_position - global_position
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		forward = -global_transform.basis.z
	forward = forward.normalized()
	for degrees in [-18.0, 0.0, 18.0]:
		var direction := forward.rotated(Vector3.UP, deg_to_rad(degrees))
		var start := global_position + Vector3(0, 0.55, 0) + direction * 0.85
		_controller.call("spawn_enemy_projectile", self, start, start + direction * 10.0, BURST_DAMAGE, BURST_SPEED)


func _begin_phase_two() -> void:
	_phase = 2
	_attack_name = ""
	_clear_telegraph()
	_set_state(State.PHASE_TRANSITION, 0.9)
	_set_telegraph(Color(0.12, 0.92, 1.0), 1.34)


func _on_health_changed(_current: float, _maximum: float) -> void:
	health_changed.emit()


func _on_died() -> void:
	if _state == State.DEAD:
		return
	_encounter_active = false
	_state = State.DEAD
	velocity = Vector3.ZERO
	_clear_telegraph()
	(get_node("CollisionShape3D") as CollisionShape3D).set_deferred("disabled", true)
	defeated.emit()
	var tween := create_tween()
	tween.tween_property(_visual_root, "scale", Vector3(1.45, 0.08, 1.45), 0.28)
	tween.tween_callback(func() -> void: visible = false)


func get_health_snapshot() -> Dictionary:
	return {
		"name": "Tidebound Guardian",
		"current": float(_health.current_health),
		"maximum": float(_health.max_health),
		"state": State.keys()[_state],
		"phase": _phase,
		"attack": _attack_name,
		"encounter_active": _encounter_active,
		"warning_visible": _warning_circle.visible,
	}


func _has_line_of_sight_to_player() -> bool:
	var ray_from := global_position + Vector3(0, 0.45, 0)
	var ray_to := _player.global_position + Vector3(0, 0.45, 0)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == _player


func _face_player() -> void:
	var direction := _player.global_position - global_position
	direction.y = 0.0
	_face_direction(direction)


func _face_direction(direction: Vector3) -> void:
	if direction.length_squared() > 0.0001:
		look_at(global_position + direction.normalized(), Vector3.UP)


func _set_state(next_state: int, duration: float) -> void:
	_state = next_state
	_state_time_left = duration


func _set_telegraph(color: Color, scale_factor: float) -> void:
	if _body_material != null:
		_body_material.albedo_color = color
		_body_material.emission_enabled = true
		_body_material.emission = color
		_body_material.emission_energy_multiplier = 2.1
	if _visual_root != null:
		create_tween().tween_property(_visual_root, "scale", _base_scale * scale_factor, maxf(_state_time_left * 0.7, 0.1))


func _clear_telegraph() -> void:
	if _warning_circle != null:
		_warning_circle.visible = false
	if _body_material != null:
		_body_material.emission_enabled = false
		_body_material.albedo_color = _base_color
	if _visual_root != null:
		_visual_root.scale = _base_scale


func _update_hit_flash(delta: float) -> void:
	if _flash_left <= 0.0:
		return
	_flash_left = maxf(_flash_left - delta, 0.0)
	if _body_material != null:
		_body_material.albedo_color = Color.WHITE if _flash_left > 0.0 else _base_color


func _clamp_to_arena() -> void:
	global_position.x = clampf(global_position.x, _arena_bounds.position.x + 0.8, _arena_bounds.end.x - 0.8)
	global_position.z = clampf(global_position.z, _arena_bounds.position.y + 0.8, _arena_bounds.end.y - 0.8)


func _stop_horizontal() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity += get_gravity() * delta


func _horizontal_distance(from: Vector3, to: Vector3) -> float:
	var offset := to - from
	offset.y = 0.0
	return offset.length()
