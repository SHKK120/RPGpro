extends CharacterBody3D

signal defeated(enemy: CharacterBody3D, core_drop: int, was_elite: bool)

enum State { IDLE, CHASE, WINDUP, RECOVER, RETURN, DEAD }

var display_name := "Enemy"
var max_health := 40.0
var move_speed := 2.6
var attack_damage := 12.0
var aggro_range := 7.0
var attack_range := 1.4
var windup_time := 0.45
var attack_cooldown := 1.0
var leash_distance := 10.0
var core_drop := 1
var ranged := false
var elite := false
var preferred_min_range := 4.0
var preferred_max_range := 7.0
var projectile_speed := 7.0

var _controller: Node
var _player: CharacterBody3D
var _health: Node
var _agent: NavigationAgent3D
var _visual_root: Node3D
var _base_visual_scale := Vector3.ONE
var _body_material: StandardMaterial3D
var _base_color := Color.WHITE
var _spawn_position := Vector3.ZERO
var _state := State.IDLE
var _state_time_left := 0.0
var _target_refresh_left := 0.0
var _knockback_velocity := Vector3.ZERO
var _knockback_left := 0.0
var _flash_left := 0.0
var _configured := false


func _ready() -> void:
	_agent = get_node("NavigationAgent3D") as NavigationAgent3D
	_health = get_node("Health")
	_visual_root = get_node("VisualRoot") as Node3D
	_base_visual_scale = _visual_root.scale
	var body := get_node_or_null("VisualRoot/Body") as MeshInstance3D
	if body != null:
		_body_material = body.material_override as StandardMaterial3D
		if _body_material != null:
			_base_color = _body_material.albedo_color
	_health.died.connect(_on_died)


func configure(controller: Node, player: CharacterBody3D, settings: Dictionary) -> void:
	_controller = controller
	_player = player
	display_name = String(settings.get("display_name", display_name))
	max_health = float(settings.get("health", max_health))
	move_speed = float(settings.get("move_speed", move_speed))
	attack_damage = float(settings.get("damage", attack_damage))
	aggro_range = float(settings.get("aggro_range", aggro_range))
	attack_range = float(settings.get("attack_range", attack_range))
	windup_time = float(settings.get("windup", windup_time))
	attack_cooldown = float(settings.get("cooldown", attack_cooldown))
	leash_distance = float(settings.get("leash", leash_distance))
	core_drop = int(settings.get("core_drop", core_drop))
	ranged = bool(settings.get("ranged", ranged))
	elite = bool(settings.get("elite", elite))
	preferred_min_range = float(settings.get("preferred_min", preferred_min_range))
	preferred_max_range = float(settings.get("preferred_max", preferred_max_range))
	projectile_speed = float(settings.get("projectile_speed", projectile_speed))
	_spawn_position = global_position
	_health.configure(max_health)
	_configured = true


func _physics_process(delta: float) -> void:
	if not _configured:
		return
	_update_visual_feedback(delta)
	if _state == State.DEAD:
		return
	if _knockback_left > 0.0:
		_knockback_left = maxf(_knockback_left - delta, 0.0)
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		_apply_gravity(delta)
		move_and_slide()
		return
	if not bool(_controller.call("is_combat_active")):
		velocity.x = 0.0
		velocity.z = 0.0
		return

	_state_time_left = maxf(_state_time_left - delta, 0.0)
	_target_refresh_left = maxf(_target_refresh_left - delta, 0.0)
	var player_distance := _horizontal_distance(global_position, _player.global_position)
	var beyond_leash := _horizontal_distance(global_position, _spawn_position) > leash_distance
	var player_in_safe_zone := bool(_controller.call("is_player_in_safe_zone"))

	if beyond_leash or player_in_safe_zone:
		_enter_return()

	match _state:
		State.IDLE:
			_stop_horizontal()
			if player_distance <= aggro_range and not player_in_safe_zone and _has_line_of_sight_to_player():
				_state = State.CHASE
		State.CHASE:
			_update_chase(player_distance)
		State.WINDUP:
			_stop_horizontal()
			if _state_time_left <= 0.0:
				_perform_attack(player_distance)
				_set_state(State.RECOVER, attack_cooldown)
		State.RECOVER:
			_stop_horizontal()
			if _state_time_left <= 0.0:
				_state = State.CHASE
		State.RETURN:
			_update_return()

	_apply_gravity(delta)
	move_and_slide()


func _update_chase(player_distance: float) -> void:
	if _horizontal_distance(global_position, _spawn_position) > leash_distance or bool(_controller.call("is_player_in_safe_zone")):
		_enter_return()
		return
	if ranged:
		if player_distance >= preferred_min_range and player_distance <= preferred_max_range and _has_line_of_sight_to_player():
			_begin_windup()
			return
		if player_distance < preferred_min_range:
			var away := global_position - _player.global_position
			away.y = 0.0
			if away.length_squared() > 0.0001:
				_move_toward_navigation(global_position + away.normalized() * 2.2)
			return
		_move_toward_navigation(_player.global_position)
		return
	if player_distance <= attack_range and _has_line_of_sight_to_player():
		_begin_windup()
		return
	_move_toward_navigation(_player.global_position)


func _begin_windup() -> void:
	_set_state(State.WINDUP, windup_time)
	if _body_material != null:
		_body_material.emission_enabled = true
		_body_material.emission = Color(1.0, 0.25, 0.08) if not ranged else Color(0.25, 0.75, 1.0)
		_body_material.emission_energy_multiplier = 2.4
	if _visual_root != null:
		var scale_target := _base_visual_scale * 1.12
		create_tween().tween_property(_visual_root, "scale", scale_target, windup_time * 0.7)


func _perform_attack(player_distance: float) -> void:
	_clear_telegraph()
	if ranged:
		if _has_line_of_sight_to_player():
			_controller.call("spawn_enemy_projectile", self, global_position + Vector3(0, 0.25, 0), _player.global_position + Vector3(0, 0.35, 0), attack_damage, projectile_speed)
		return
	if player_distance <= attack_range + 0.25 and _has_line_of_sight_to_player():
		_controller.call("damage_player", attack_damage, global_position)


func _move_toward_navigation(target: Vector3) -> void:
	if _target_refresh_left <= 0.0:
		_agent.target_position = target
		_target_refresh_left = 0.18
	if _agent.is_navigation_finished():
		_stop_horizontal()
		return
	var next := _agent.get_next_path_position()
	var direction := next - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.0001:
		_stop_horizontal()
		return
	direction = direction.normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed


func _enter_return() -> void:
	if _state == State.DEAD:
		return
	_clear_telegraph()
	_state = State.RETURN
	_target_refresh_left = 0.0


func _update_return() -> void:
	if _horizontal_distance(global_position, _spawn_position) <= 0.35:
		global_position = _spawn_position
		_health.restore_full()
		_stop_horizontal()
		_state = State.IDLE
		return
	_move_toward_navigation(_spawn_position)


func take_melee_hit(amount: float, direction: Vector3) -> bool:
	if _state == State.DEAD:
		return false
	var applied: float = _health.damage(amount)
	if applied <= 0.0:
		return false
	_flash_left = 0.13
	direction.y = 0.0
	if direction.length_squared() > 0.0001:
		_knockback_velocity = direction.normalized() * 3.0
		_knockback_left = 0.12
	return true


func reset_to_spawn() -> void:
	global_position = _spawn_position
	velocity = Vector3.ZERO
	_knockback_left = 0.0
	_flash_left = 0.0
	_clear_telegraph()
	_health.restore_full()
	_state = State.IDLE
	visible = true
	if _visual_root != null:
		_visual_root.visible = true
		_visual_root.scale = _base_visual_scale
	var shape := get_node("CollisionShape3D") as CollisionShape3D
	shape.set_deferred("disabled", false)


func get_health_snapshot() -> Dictionary:
	return {
		"name": display_name,
		"current": _health.current_health,
		"maximum": _health.max_health,
		"state": State.keys()[_state],
		"elite": elite,
		"ranged": ranged,
	}


func _on_died() -> void:
	_state = State.DEAD
	velocity = Vector3.ZERO
	_clear_telegraph()
	(get_node("CollisionShape3D") as CollisionShape3D).set_deferred("disabled", true)
	defeated.emit(self, core_drop, elite)
	if _visual_root != null:
		var tween := create_tween()
		tween.tween_property(_visual_root, "scale", Vector3(1.25, 0.08, 1.25), 0.2)
		tween.tween_callback(func() -> void: _visual_root.visible = false)


func _has_line_of_sight_to_player() -> bool:
	if _player == null:
		return false
	var ray_from := global_position + Vector3(0, 0.35, 0)
	var ray_to := _player.global_position + Vector3(0, 0.35, 0)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == _player


func _set_state(next_state: int, duration: float) -> void:
	_state = next_state
	_state_time_left = duration


func _clear_telegraph() -> void:
	if _body_material != null:
		_body_material.emission_enabled = false
		_body_material.albedo_color = _base_color
	if _visual_root != null and _flash_left <= 0.0:
		_visual_root.scale = _base_visual_scale


func _update_visual_feedback(delta: float) -> void:
	if _flash_left <= 0.0:
		return
	_flash_left = maxf(_flash_left - delta, 0.0)
	if _body_material != null:
		_body_material.albedo_color = Color(1.0, 1.0, 1.0) if _flash_left > 0.0 else _base_color
	if _flash_left <= 0.0 and _state != State.WINDUP:
		_clear_telegraph()


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
