extends "res://scripts/prototype/m02_green_coast.gd"

const HEALTH_SCRIPT := preload("res://scripts/prototype/m03_health.gd")
const ENEMY_SCRIPT := preload("res://scripts/prototype/m03_enemy.gd")
const PROJECTILE_SCRIPT := preload("res://scripts/prototype/m03_projectile.gd")
const CHARACTER_LEATHER := preload("res://assets/art/green_coast_v01/materials/character_leather.tres")
const CHARACTER_METAL := preload("res://assets/art/green_coast_v01/materials/character_metal.tres")

const PLAYER_MAX_HEALTH := 100.0
const BASE_WEAPON_DAMAGE := 16.0
const UPGRADED_WEAPON_DAMAGE := 24.0
const ATTACK_RANGE := 1.6
const ATTACK_COOLDOWN := 0.45
const ATTACK_HIT_TIME := 0.09
const ATTACK_VISUAL_TIME := 0.28
const WEAPON_UPGRADE_CORE_COST := 4
const SAFE_ZONE_CENTER := Vector3(0.0, 0.0, 7.0)
const SAFE_ZONE_RADIUS := 5.25

var _monster_core_count := 0
var _weapon_level := 0
var _first_combat_loop_completed := false
var _combat_ready := false
var _death_sequence_running := false
var _player_health: Node
var _combat_world: Node3D
var _projectile_root: Node3D
var _enemies: Array[CharacterBody3D] = []
var _combat_pivot: Node3D
var _blade_visual: MeshInstance3D
var _blade_hitbox: Area3D
var _blade_hit_targets: Dictionary = {}
var _attack_direction := Vector3(0.0, 0.0, -1.0)
var _attack_cooldown_left := 0.0
var _attack_time_left := 0.0
var _attack_hit_pending := false
var _death_overlay: Control
var _core_serial := 0


func _ready() -> void:
	super._ready()
	_setup_m03_combat()


func _process(delta: float) -> void:
	super._process(delta)
	if not _combat_ready:
		return
	if _flow_mode == FlowMode.PLAY and _vista_state == VistaState.PLAY and not _death_sequence_running:
		var mouse_position := get_viewport().get_mouse_position()
		if get_viewport().get_visible_rect().has_point(mouse_position):
			_player.call("face_visual_direction", _attack_direction_from_screen(mouse_position))
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)
	if _attack_time_left > 0.0:
		_attack_time_left = maxf(_attack_time_left - delta, 0.0)
		for overlapping_body in _blade_hitbox.get_overlapping_bodies():
			_on_blade_body_entered(overlapping_body)
		if _attack_time_left <= 0.0:
			_end_attack_visual()


func _unhandled_input(event: InputEvent) -> void:
	if not _combat_ready or _flow_mode != FlowMode.PLAY or _vista_state != VistaState.PLAY:
		super._unhandled_input(event)
		return
	if _death_sequence_running or bool(_player.call("is_combat_dead")):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("combat_dodge"):
		if _attack_time_left <= 0.0:
			_player.call("start_combat_dodge")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("combat_attack"):
		var mouse_event := event as InputEventMouseButton
		if mouse_event != null:
			begin_player_attack(_attack_direction_from_screen(mouse_event.position))
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)


func _enter_play_mode() -> void:
	super._enter_play_mode()
	if _combat_ready:
		_player.call("set_combat_enabled", true)
		_player.call("heal_to_full")
		_refresh_hud()


func _setup_m03_combat() -> void:
	_player_health = _player.call("get_health_component")
	_player.connect("combat_health_changed", _refresh_hud)
	_player.connect("combat_died", _on_player_died)
	_combat_world = Node3D.new()
	_combat_world.name = "M03CombatWorld"
	add_child(_combat_world)
	_projectile_root = Node3D.new()
	_projectile_root.name = "Projectiles"
	_combat_world.add_child(_projectile_root)
	_create_weapon_visual()
	_create_home_combat_interactables()
	_create_fixed_enemies()
	_create_death_overlay()
	_combat_ready = true
	_player.call("set_combat_enabled", _flow_mode == FlowMode.PLAY)
	_refresh_hud()


func is_combat_active() -> bool:
	return _combat_ready and _flow_mode == FlowMode.PLAY and _vista_state == VistaState.PLAY and not _death_sequence_running and not bool(_player.call("is_combat_dead"))


func is_player_in_safe_zone() -> bool:
	return _horizontal_distance(_player.global_position, SAFE_ZONE_CENTER) <= SAFE_ZONE_RADIUS


func begin_player_attack(direction: Vector3) -> bool:
	if not is_combat_active() or _attack_cooldown_left > 0.0 or _attack_time_left > 0.0 or bool(_player.call("is_dodging")):
		return false
	direction.y = 0.0
	if direction.length_squared() <= 0.0001:
		return false
	_attack_direction = _player.call("face_visual_direction", direction)
	_player.call("remember_combat_direction", _attack_direction)
	_player.call("cancel_active_movement")
	_attack_cooldown_left = ATTACK_COOLDOWN
	_attack_time_left = ATTACK_VISUAL_TIME
	_attack_hit_pending = false
	_blade_hit_targets.clear()
	_player.call("set_attack_visual_active", true)
	_blade_visual.visible = true
	_blade_hitbox.set_deferred("monitoring", true)
	_combat_pivot.rotation = Vector3(0.0, -1.05, -0.16)
	var tween := create_tween()
	tween.tween_property(_combat_pivot, "rotation:y", 0.88, ATTACK_VISUAL_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return true


func _attack_direction_from_screen(screen_position: Vector2) -> Vector3:
	var ray_origin := _camera.project_ray_origin(screen_position)
	var ray_direction := _camera.project_ray_normal(screen_position)
	var plane_hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(ray_origin, ray_direction)
	if plane_hit != null:
		var direction: Vector3 = plane_hit - _player.global_position
		direction.y = 0.0
		if direction.length_squared() > 0.0001:
			return direction.normalized()
	var fallback := -_camera.global_transform.basis.z
	fallback.y = 0.0
	return fallback.normalized()


func _on_blade_body_entered(body: Node3D) -> void:
	if _attack_time_left <= 0.0 or not is_combat_active():
		return
	var target := body as CharacterBody3D
	if target == null or not target.has_method("take_melee_hit") or not target.has_method("get_health_snapshot"):
		return
	var valid_target := _enemies.has(target)
	if not valid_target:
		valid_target = _additional_melee_targets().has(target)
	if not valid_target:
		return
	var target_id := target.get_instance_id()
	if _blade_hit_targets.has(target_id):
		return
	var snapshot: Dictionary = target.call("get_health_snapshot")
	if snapshot.get("state", "") == "DEAD":
		return
	_blade_hit_targets[target_id] = true
	var knockback := target.global_position - _player.global_position
	target.call("take_melee_hit", _current_weapon_damage(), knockback)


func _additional_melee_targets() -> Array[CharacterBody3D]:
	return []


func _melee_line_of_sight(enemy: CharacterBody3D) -> bool:
	var ray_from := _player.global_position + Vector3(0.0, 0.45, 0.0)
	var ray_to := enemy.global_position + Vector3(0.0, 0.25, 0.0)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to, 1, [_player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == enemy


func _current_weapon_damage() -> float:
	return UPGRADED_WEAPON_DAMAGE if _weapon_level > 0 else BASE_WEAPON_DAMAGE


func _end_attack_visual() -> void:
	_attack_time_left = 0.0
	_attack_hit_pending = false
	_blade_hit_targets.clear()
	if _blade_hitbox != null:
		_blade_hitbox.set_deferred("monitoring", false)
	if _blade_visual != null:
		_blade_visual.visible = false
	if _combat_pivot != null:
		_combat_pivot.rotation = Vector3.ZERO
	if _player != null:
		_player.call("set_attack_visual_active", false)


func damage_player(amount: float, _source_position: Vector3) -> bool:
	if not is_combat_active():
		return false
	var applied := bool(_player.call("apply_combat_damage", amount))
	if applied:
		_refresh_hud()
	return applied


func spawn_enemy_projectile(source: CharacterBody3D, start: Vector3, target: Vector3, damage: float, speed: float) -> CharacterBody3D:
	if not is_combat_active():
		return null
	var projectile := CharacterBody3D.new()
	projectile.name = "RuinWispProjectile"
	projectile.set_script(PROJECTILE_SCRIPT)
	projectile.collision_layer = 4
	projectile.collision_mask = 1
	var shape := SphereShape3D.new()
	shape.radius = 0.18
	var collision := CollisionShape3D.new()
	collision.shape = shape
	projectile.add_child(collision)
	var mesh := SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
	mesh.radial_segments = 8
	mesh.rings = 4
	var material := _combat_material(Color(0.2, 0.72, 1.0), Color(0.08, 0.52, 1.0))
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	projectile.add_child(visual)
	_projectile_root.add_child(projectile)
	var exceptions: Array = _enemies.duplicate()
	exceptions.append(source)
	projectile.call("configure", self, _player, start, target, damage, speed, exceptions)
	return projectile


func _on_player_died() -> void:
	if _death_sequence_running:
		return
	_death_sequence_running = true
	_before_player_death_recovery()
	_end_attack_visual()
	_player.call("set_combat_enabled", false)
	_player.call("cancel_active_movement")
	_death_overlay.visible = true
	_show_message("쓰러졌습니다. 거점으로 돌아갑니다.", true)
	await get_tree().create_timer(1.15).timeout
	_clear_uncollected_core_pickups()
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.call("reset_to_spawn")
	for projectile in _projectile_root.get_children():
		projectile.queue_free()
	await _place_player_on_navigation(SAFE_START)
	_player.call("prepare_respawn")
	_player.call("set_movement_locked", false)
	_player.call("set_combat_enabled", true)
	_death_overlay.visible = false
	_death_sequence_running = false
	_refresh_hud()
	if _save_game():
		_show_message("거점에서 회복했습니다. 진행 상태는 잃지 않았습니다.", false)


func _before_player_death_recovery() -> void:
	pass


func _create_weapon_visual() -> void:
	_combat_pivot = Node3D.new()
	_combat_pivot.name = "CombatPivot"
	_combat_pivot.position = Vector3(0.38, 0.26, -0.02)
	_player.add_child(_combat_pivot)
	_add_visual_box(_combat_pivot, "AttackSleeve", Vector3(0.0, -0.04, -0.18), Vector3(0.18, 0.20, 0.42), CHARACTER_LEATHER)
	_add_visual_box(_combat_pivot, "AttackHand", Vector3(0.0, -0.05, -0.43), Vector3(0.16, 0.17, 0.16), CHARACTER_LEATHER)
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.18, 0.12, 1.45)
	blade_mesh.material = CHARACTER_METAL
	_blade_visual = MeshInstance3D.new()
	_blade_visual.name = "PrototypeBlade"
	_blade_visual.mesh = blade_mesh
	_blade_visual.position = Vector3(0.0, -0.05, -1.12)
	_blade_visual.visible = false
	_combat_pivot.add_child(_blade_visual)
	_blade_hitbox = Area3D.new()
	_blade_hitbox.name = "BladeHitbox"
	_blade_hitbox.position = _blade_visual.position
	_blade_hitbox.collision_layer = 0
	_blade_hitbox.collision_mask = 1
	_blade_hitbox.monitoring = false
	var blade_shape := BoxShape3D.new()
	blade_shape.size = Vector3(0.28, 0.42, 1.46)
	var blade_collision := CollisionShape3D.new()
	blade_collision.shape = blade_shape
	_blade_hitbox.add_child(blade_collision)
	_combat_pivot.add_child(_blade_hitbox)
	_blade_hitbox.body_entered.connect(_on_blade_body_entered)
	var hilt_mesh := BoxMesh.new()
	hilt_mesh.size = Vector3(0.38, 0.12, 0.12)
	hilt_mesh.material = CHARACTER_LEATHER
	var hilt := MeshInstance3D.new()
	hilt.mesh = hilt_mesh
	hilt.position = Vector3(0.0, 0.0, 0.66)
	_blade_visual.add_child(hilt)


func _create_home_combat_interactables() -> void:
	var workbench := Node3D.new()
	workbench.name = "WeaponWorkbench"
	workbench.position = Vector3(-1.2, 0.05, 8.4)
	workbench.set_meta("kind", "weapon_workbench")
	workbench.set_meta("active", true)
	_interactables.add_child(workbench)
	_add_box_visual(workbench, "Top", Vector3(0, 0.85, 0), Vector3(1.55, 0.18, 0.7), ART_WOOD_MATERIAL)
	_add_box_visual(workbench, "LegLeft", Vector3(-0.58, 0.42, 0), Vector3(0.16, 0.84, 0.52), ART_WOOD_MATERIAL)
	_add_box_visual(workbench, "LegRight", Vector3(0.58, 0.42, 0), Vector3(0.16, 0.84, 0.52), ART_WOOD_MATERIAL)
	_add_box_visual(workbench, "ToolBoard", Vector3(0, 1.12, 0.30), Vector3(1.36, 0.42, 0.10), _combat_material(Color(0.34, 0.22, 0.14)))
	_add_box_visual(workbench, "BladeBlank", Vector3(0, 1.08, -0.08), Vector3(0.12, 0.08, 1.0), _combat_material(Color(0.56, 0.66, 0.68)))

	var rest := Node3D.new()
	rest.name = "RestPoint"
	rest.position = Vector3(3.7, 0.04, 8.25)
	rest.set_meta("kind", "rest")
	rest.set_meta("active", true)
	_interactables.add_child(rest)
	for index in range(6):
		var angle := TAU * float(index) / 6.0
		_add_box_visual(rest, "Stone%d" % index, Vector3(cos(angle) * 0.48, 0.14, sin(angle) * 0.48), Vector3(0.35, 0.24, 0.28), _combat_material(Color(0.30, 0.33, 0.34)))
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.28
	flame_mesh.height = 0.72
	flame_mesh.radial_segments = 7
	flame_mesh.rings = 4
	flame_mesh.material = _combat_material(Color(1.0, 0.42, 0.08), Color(1.0, 0.18, 0.02))
	var flame := MeshInstance3D.new()
	flame.name = "Flame"
	flame.position.y = 0.48
	flame.mesh = flame_mesh
	rest.add_child(flame)
	var home_light := OmniLight3D.new()
	home_light.name = "WarmHomeLight"
	home_light.position = Vector3(0, 1.15, 0)
	home_light.light_color = Color(1.0, 0.58, 0.30)
	home_light.light_energy = 0.62
	home_light.omni_range = 4.6
	home_light.shadow_enabled = false
	rest.add_child(home_light)


func _create_fixed_enemies() -> void:
	_add_enemy("CrawlerForestA", Vector3(-10.4, 0.7, 0.8), {
		"display_name": "Coast Crawler", "health": 40.0, "move_speed": 2.6, "damage": 12.0,
		"aggro_range": 7.0, "attack_range": 1.4, "windup": 0.45, "cooldown": 1.0,
		"leash": 10.0, "core_drop": 1,
	})
	_add_enemy("CrawlerForestB", Vector3(-9.2, 0.7, -5.8), {
		"display_name": "Coast Crawler", "health": 40.0, "move_speed": 2.6, "damage": 12.0,
		"aggro_range": 7.0, "attack_range": 1.4, "windup": 0.45, "cooldown": 1.0,
		"leash": 10.0, "core_drop": 1,
	})
	_add_enemy("WispRuinA", Vector3(7.2, 0.75, 0.1), {
		"display_name": "Ruin Wisp", "health": 50.0, "move_speed": 2.2, "damage": 10.0,
		"aggro_range": 9.0, "attack_range": 7.0, "windup": 0.65, "cooldown": 1.8,
		"leash": 10.0, "core_drop": 1, "ranged": true, "preferred_min": 4.0,
		"preferred_max": 7.0, "projectile_speed": 7.0,
	})
	_add_enemy("WispRuinB", Vector3(11.6, 0.75, -0.5), {
		"display_name": "Ruin Wisp", "health": 50.0, "move_speed": 2.2, "damage": 10.0,
		"aggro_range": 9.0, "attack_range": 7.0, "windup": 0.65, "cooldown": 1.8,
		"leash": 10.0, "core_drop": 1, "ranged": true, "preferred_min": 4.0,
		"preferred_max": 7.0, "projectile_speed": 7.0,
	})
	_add_enemy("RuinGuard", Vector3(8.5, 0.9, -3.65), {
		"display_name": "Ruin Guard", "health": 110.0, "move_speed": 2.3, "damage": 18.0,
		"aggro_range": 7.5, "attack_range": 1.7, "windup": 0.65, "cooldown": 1.15,
		"leash": 9.0, "core_drop": 3, "elite": true,
	})


func _add_enemy(node_name: String, position: Vector3, settings: Dictionary) -> CharacterBody3D:
	var enemy := CharacterBody3D.new()
	enemy.name = node_name
	enemy.set_script(ENEMY_SCRIPT)
	enemy.position = position
	enemy.add_to_group("m03_enemy")
	var collision_shape := CapsuleShape3D.new()
	collision_shape.radius = 0.48 if not bool(settings.get("elite", false)) else 0.62
	collision_shape.height = 1.2 if not bool(settings.get("elite", false)) else 1.55
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = collision_shape
	enemy.add_child(collision)
	var agent := NavigationAgent3D.new()
	agent.name = "NavigationAgent3D"
	agent.path_height_offset = -position.y
	agent.path_desired_distance = 0.35
	agent.target_desired_distance = 0.4
	agent.radius = collision_shape.radius
	agent.height = collision_shape.height
	agent.avoidance_enabled = false
	enemy.add_child(agent)
	var health := HEALTH_SCRIPT.new()
	health.name = "Health"
	enemy.add_child(health)
	var visual_root := Node3D.new()
	visual_root.name = "VisualRoot"
	enemy.add_child(visual_root)
	var body := MeshInstance3D.new()
	body.name = "Body"
	var material: StandardMaterial3D
	var is_ranged := bool(settings.get("ranged", false))
	var is_elite := bool(settings.get("elite", false))
	if is_ranged:
		var sphere := SphereMesh.new()
		sphere.radius = 0.40
		sphere.height = 0.76
		sphere.radial_segments = 8
		sphere.rings = 4
		material = _combat_material(Color(0.20, 0.43, 0.58), Color(0.03, 0.15, 0.26))
		body.mesh = sphere
		body.position.y = 0.14
		var tail_material := _combat_material(Color(0.34, 0.56, 0.62))
		var tail_mesh := PrismMesh.new()
		tail_mesh.size = Vector3(0.48, 0.72, 0.48)
		tail_mesh.material = tail_material
		var tail := MeshInstance3D.new()
		tail.name = "TaperedTail"
		tail.position.y = -0.45
		tail.rotation_degrees.x = 180.0
		tail.mesh = tail_mesh
		visual_root.add_child(tail)
		var mote_material := _combat_material(Color(0.38, 0.72, 0.72), Color(0.03, 0.20, 0.22))
		for orbit_index in range(3):
			var mote_mesh := SphereMesh.new()
			mote_mesh.radius = 0.09
			mote_mesh.height = 0.18
			mote_mesh.radial_segments = 6
			mote_mesh.rings = 3
			mote_mesh.material = mote_material
			var mote := MeshInstance3D.new()
			mote.mesh = mote_mesh
			var angle := TAU * float(orbit_index) / 3.0
			mote.position = Vector3(cos(angle) * 0.62, 0.12 * orbit_index - 0.04, sin(angle) * 0.62)
			visual_root.add_child(mote)
	elif is_elite:
		var guard_mesh := CylinderMesh.new()
		guard_mesh.top_radius = 0.43
		guard_mesh.bottom_radius = 0.58
		guard_mesh.height = 1.18
		guard_mesh.radial_segments = 6
		material = _combat_material(Color(0.34, 0.17, 0.13))
		guard_mesh.material = material
		body.mesh = guard_mesh
		var armor := _combat_material(Color(0.40, 0.46, 0.43))
		_add_box_visual(visual_root, "ShoulderLeft", Vector3(-0.48, 0.34, 0), Vector3(0.44, 0.26, 0.56), armor)
		_add_box_visual(visual_root, "ShoulderRight", Vector3(0.48, 0.34, 0), Vector3(0.44, 0.26, 0.56), armor)
		_add_box_visual(visual_root, "StoneMask", Vector3(0, 0.62, -0.34), Vector3(0.48, 0.38, 0.16), armor)
		_add_box_visual(visual_root, "Shield", Vector3(-0.64, -0.04, -0.08), Vector3(0.18, 0.88, 0.72), armor)
	else:
		var crawler_mesh := SphereMesh.new()
		crawler_mesh.radius = 0.46
		crawler_mesh.height = 0.70
		crawler_mesh.radial_segments = 8
		crawler_mesh.rings = 3
		material = _combat_material(Color(0.50, 0.27, 0.17))
		crawler_mesh.material = material
		body.mesh = crawler_mesh
		body.position.y = -0.04
		var shell_material := _combat_material(Color(0.27, 0.19, 0.15))
		var shell_mesh := SphereMesh.new()
		shell_mesh.radius = 0.48
		shell_mesh.height = 0.48
		shell_mesh.radial_segments = 7
		shell_mesh.rings = 3
		shell_mesh.material = shell_material
		var shell := MeshInstance3D.new()
		shell.name = "Shell"
		shell.position = Vector3(0, 0.22, 0.08)
		shell.scale = Vector3(1.0, 0.72, 1.12)
		shell.mesh = shell_mesh
		visual_root.add_child(shell)
		_add_box_visual(visual_root, "Snout", Vector3(0, -0.03, -0.43), Vector3(0.42, 0.26, 0.34), material)
		for leg_index in range(4):
			var side := -1.0 if leg_index % 2 == 0 else 1.0
			var front := -1.0 if leg_index < 2 else 1.0
			_add_box_visual(visual_root, "Leg%d" % leg_index, Vector3(side * 0.43, -0.24, front * 0.26), Vector3(0.34, 0.16, 0.18), material)
	body.material_override = material
	visual_root.add_child(body)
	_combat_world.add_child(enemy)
	enemy.call("configure", self, _player, settings)
	enemy.connect("defeated", _on_enemy_defeated)
	_enemies.append(enemy)
	return enemy


func _on_enemy_defeated(enemy: CharacterBody3D, core_amount: int, was_elite: bool) -> void:
	_spawn_core_pickup(enemy.global_position, core_amount)
	if was_elite and not _first_combat_loop_completed:
		_first_combat_loop_completed = true
		_save_after_change("Ruin Guard를 쓰러뜨렸습니다. 첫 전투 루프 완료.")
	else:
		_show_message("%s 처치 · Monster Core가 떨어졌습니다." % String(enemy.get("display_name")), false)
	_refresh_hud()


func _spawn_core_pickup(position: Vector3, amount: int) -> Node3D:
	_core_serial += 1
	var pickup := Node3D.new()
	pickup.name = "MonsterCoreDrop_%d" % _core_serial
	pickup.position = Vector3(position.x, 0.34, position.z)
	pickup.set_meta("kind", "monster_core")
	pickup.set_meta("amount", amount)
	pickup.set_meta("active", true)
	_interactables.add_child(pickup)
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.34, 0.62, 0.34)
	mesh.material = _combat_material(Color(0.32, 0.73, 0.66), Color(0.04, 0.24, 0.22))
	var visual := MeshInstance3D.new()
	visual.name = "CoreVisual"
	visual.mesh = mesh
	pickup.add_child(visual)
	_add_pickup_ring(pickup)
	return pickup


func _interaction_label(target: Node3D) -> String:
	match String(target.get_meta("kind", "")):
		"monster_core":
			return "Monster Core 줍기"
		"weapon_workbench":
			return "Prototype Blade 확인" if _weapon_level > 0 else "Prototype Blade 강화 (Core 4)"
		"rest":
			return "거점에서 회복"
	return super._interaction_label(target)


func _interact_with_nearest() -> void:
	_update_nearest_interactable()
	if _nearest_interactable == null:
		return
	match String(_nearest_interactable.get_meta("kind", "")):
		"monster_core":
			_collect_monster_core(_nearest_interactable)
		"weapon_workbench":
			_upgrade_weapon()
		"rest":
			_rest_at_home()
		_:
			super._interact_with_nearest()


func _collect_monster_core(target: Node3D) -> void:
	if not target.get_meta("active", true):
		return
	var amount := int(target.get_meta("amount", 1))
	target.set_meta("active", false)
	target.visible = false
	_monster_core_count += amount
	_nearest_interactable = null
	target.queue_free()
	_refresh_hud()
	_save_after_change("Monster Core +%d" % amount)


func _upgrade_weapon() -> void:
	if _weapon_level > 0:
		_show_message("Prototype Blade는 이미 +1입니다.", false)
		return
	if _monster_core_count < WEAPON_UPGRADE_CORE_COST:
		_show_message("Monster Core가 부족합니다. %d / %d" % [_monster_core_count, WEAPON_UPGRADE_CORE_COST], true)
		return
	_monster_core_count -= WEAPON_UPGRADE_CORE_COST
	_weapon_level = 1
	_refresh_hud()
	_save_after_change("Prototype Blade +1 · 피해 16 → 24")


func _rest_at_home() -> void:
	if _player_health == null:
		return
	var was_full := is_equal_approx(float(_player_health.current_health), float(_player_health.max_health))
	_player.call("heal_to_full")
	_refresh_hud()
	_show_message("이미 최대 HP입니다." if was_full else "거점에서 HP를 모두 회복했습니다.", false)


func _current_objective() -> String:
	if _first_combat_loop_completed:
		return "첫 전투 루프 완료"
	if _weapon_level == 0 and _monster_core_count < WEAPON_UPGRADE_CORE_COST:
		return "적을 처치해 Monster Core를 모으세요. %d / %d" % [_monster_core_count, WEAPON_UPGRADE_CORE_COST]
	if _weapon_level == 0:
		return "거점의 무기 작업대에서 무기를 강화하세요."
	return "폐허 깊은 곳의 Ruin Guard를 쓰러뜨리세요."


func _refresh_hud() -> void:
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
	(get_node("UI/HUD/Stats/VBox/ResourceLabel") as Label).text = "HP %d / %d   Core %d   Blade +%d   |   목재 %d  돌 %d  기념품 %s" % [int(ceil(hp_current)), int(hp_max), _monster_core_count, _weapon_level, _wood, _stone, souvenir_text]
	(get_node("UI/HUD/Stats/VBox/ObjectiveLabel") as Label).text = "현재 목표: " + _current_objective()


func _reset_progress() -> void:
	super._reset_progress()
	_monster_core_count = 0
	_weapon_level = 0
	_first_combat_loop_completed = false
	if _combat_ready:
		_clear_uncollected_core_pickups()
		for enemy in _enemies:
			if is_instance_valid(enemy):
				enemy.call("reset_to_spawn")
		_player.call("prepare_respawn")


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
		"monster_core_count": _monster_core_count,
		"weapon_level": _weapon_level,
		"first_combat_loop_completed": _first_combat_loop_completed,
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
	if data.has("monster_core_count") and ((typeof(data["monster_core_count"]) != TYPE_INT and typeof(data["monster_core_count"]) != TYPE_FLOAT) or int(data["monster_core_count"]) < 0):
		return false
	if data.has("weapon_level") and ((typeof(data["weapon_level"]) != TYPE_INT and typeof(data["weapon_level"]) != TYPE_FLOAT) or int(data["weapon_level"]) < 0 or int(data["weapon_level"]) > _maximum_weapon_level()):
		return false
	if data.has("first_combat_loop_completed") and typeof(data["first_combat_loop_completed"]) != TYPE_BOOL:
		return false
	return true


func _maximum_weapon_level() -> int:
	return 1


func _apply_loaded_data(data: Dictionary) -> void:
	super._apply_loaded_data(data)
	_monster_core_count = int(data.get("monster_core_count", 0))
	_weapon_level = int(data.get("weapon_level", 0))
	_first_combat_loop_completed = bool(data.get("first_combat_loop_completed", false))
	if _player_health != null:
		_player.call("prepare_respawn")
	_refresh_hud()


func get_combat_snapshot() -> Dictionary:
	var enemy_snapshots: Array = []
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy_snapshots.append(enemy.call("get_health_snapshot"))
	return {
		"hp": float(_player_health.current_health) if _player_health != null else PLAYER_MAX_HEALTH,
		"max_hp": float(_player_health.max_health) if _player_health != null else PLAYER_MAX_HEALTH,
		"monster_core_count": _monster_core_count,
		"weapon_level": _weapon_level,
		"weapon_damage": _current_weapon_damage(),
		"first_combat_loop_completed": _first_combat_loop_completed,
		"enemy_count": _enemies.size(),
		"enemies": enemy_snapshots,
		"objective": _current_objective(),
	}


func get_enemy_nodes() -> Array[CharacterBody3D]:
	return _enemies.duplicate()


func _clear_uncollected_core_pickups() -> void:
	if _interactables == null:
		return
	for child in _interactables.get_children():
		if String(child.get_meta("kind", "")) == "monster_core":
			child.queue_free()


func _create_death_overlay() -> void:
	var overlay := ColorRect.new()
	overlay.name = "DeathOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.18, 0.015, 0.02, 0.64)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	get_node("UI").add_child(overlay)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.position = Vector2(-250, -45)
	label.size = Vector2(500, 90)
	label.text = "쓰러졌습니다\n거점으로 귀환합니다"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	overlay.add_child(label)
	_death_overlay = overlay


func _add_box_visual(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.position = position
	visual.mesh = mesh
	parent.add_child(visual)
	return visual


func _combat_material(color: Color, emission := Color(0, 0, 0, 0)) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	if emission.a > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 1.5
	return material
