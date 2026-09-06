extends "res://scripts/prototype/p1_player.gd"

signal combat_health_changed
signal combat_died

const HEALTH_SCRIPT := preload("res://scripts/prototype/m03_health.gd")
const CHARACTER_CLOTH := preload("res://assets/art/green_coast_v01/materials/character_cloth.tres")
const CHARACTER_LEATHER := preload("res://assets/art/green_coast_v01/materials/character_leather.tres")
const CHARACTER_OUTER_CLOTH := preload("res://assets/art/green_coast_v01/materials/character_outer_cloth.tres")
const CHARACTER_SKIN := preload("res://assets/art/green_coast_v01/materials/character_skin.tres")
const DODGE_DURATION := 0.18
const DODGE_DISTANCE := 1.5
const DODGE_INVULNERABLE_TIME := 0.16
const DODGE_COOLDOWN := 0.8

var _combat_health: Node
var _combat_enabled := false
var _combat_dead := false
var _dodge_time_left := 0.0
var _dodge_cooldown_left := 0.0
var _invulnerable_time_left := 0.0
var _dodge_direction := Vector3.ZERO
var _recent_combat_direction := Vector3(0.0, 0.0, -1.0)
var _body_material: StandardMaterial3D
var _body_base_color := Color.WHITE
var _hit_flash_left := 0.0
var _click_bounds_enabled := false
var _click_bounds := Rect2()
var _visual_root: Node3D
var _tunic_visual: MeshInstance3D
var _cape_visual: MeshInstance3D
var _left_boot_visual: MeshInstance3D
var _right_boot_visual: MeshInstance3D
var _left_arm_pivot: Node3D
var _right_arm_pivot: Node3D
var _walk_phase := 0.0
var _walk_blend := 0.0
var _attack_visual_active := false
var _visual_facing_index := 0


func _ready() -> void:
	super._ready()
	_combat_health = HEALTH_SCRIPT.new()
	_combat_health.name = "Health"
	add_child(_combat_health)
	_combat_health.configure(100.0)
	_combat_health.health_changed.connect(_on_health_changed)
	_combat_health.died.connect(_on_died)
	_build_visual_baseline_character()


func _physics_process(delta: float) -> void:
	_dodge_cooldown_left = maxf(_dodge_cooldown_left - delta, 0.0)
	_invulnerable_time_left = maxf(_invulnerable_time_left - delta, 0.0)
	_update_hit_flash(delta)
	if _combat_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if _combat_enabled and _dodge_time_left > 0.0:
		_dodge_time_left = maxf(_dodge_time_left - delta, 0.0)
		var dodge_speed := DODGE_DISTANCE / DODGE_DURATION
		velocity.x = _dodge_direction.x * dodge_speed
		velocity.z = _dodge_direction.z * dodge_speed
		if is_on_floor():
			velocity.y = 0.0
		else:
			velocity += get_gravity() * delta
		move_and_slide()
		if _dodge_time_left <= 0.0:
			velocity.x = 0.0
			velocity.z = 0.0
		return
	super._physics_process(delta)


func _process(delta: float) -> void:
	_update_visual_motion(delta)


func _try_accept_destination(clicked_position: Vector3, allow_distant_snap := false) -> bool:
	if _click_bounds_enabled and not _click_bounds.has_point(Vector2(clicked_position.x, clicked_position.z)):
		return false
	return super._try_accept_destination(clicked_position, allow_distant_snap)


func set_combat_enabled(enabled: bool) -> void:
	_combat_enabled = enabled
	if not enabled:
		_dodge_time_left = 0.0


func start_combat_dodge() -> bool:
	if not _combat_enabled or _combat_dead or _dodge_time_left > 0.0 or _dodge_cooldown_left > 0.0:
		return false
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := _camera_relative_direction(input_vector)
	if direction.length_squared() <= 0.0001:
		direction = Vector3(velocity.x, 0.0, velocity.z).normalized()
	if direction.length_squared() <= 0.0001:
		direction = _recent_combat_direction
	if direction.length_squared() <= 0.0001:
		direction = Vector3(0.0, 0.0, -1.0)
	_dodge_direction = direction.normalized()
	_recent_combat_direction = _dodge_direction
	cancel_active_movement()
	_dodge_time_left = DODGE_DURATION
	_dodge_cooldown_left = DODGE_COOLDOWN
	_invulnerable_time_left = DODGE_INVULNERABLE_TIME
	return true


func remember_combat_direction(direction: Vector3) -> void:
	direction.y = 0.0
	if direction.length_squared() > 0.0001:
		_recent_combat_direction = direction.normalized()


func face_visual_direction(direction: Vector3) -> Vector3:
	direction.y = 0.0
	if direction.length_squared() <= 0.0001:
		return _recent_combat_direction
	var normalized := direction.normalized()
	var step := TAU / 8.0
	var angle := atan2(-normalized.x, -normalized.z)
	var snapped_angle := roundf(angle / step) * step
	rotation.y = snapped_angle
	_visual_facing_index = (int(roundf(snapped_angle / step)) % 8 + 8) % 8
	var snapped_direction := -Basis(Vector3.UP, snapped_angle).z
	_recent_combat_direction = snapped_direction.normalized()
	return _recent_combat_direction


func get_visual_facing_index() -> int:
	return _visual_facing_index


func set_attack_visual_active(active: bool) -> void:
	_attack_visual_active = active
	if _right_arm_pivot != null:
		_right_arm_pivot.visible = not active


func apply_combat_damage(amount: float) -> bool:
	if not _combat_enabled or _combat_dead or _invulnerable_time_left > 0.0:
		return false
	var applied: float = _combat_health.damage(amount)
	if applied <= 0.0:
		return false
	_hit_flash_left = 0.16
	if _body_material != null:
		_body_material.albedo_color = Color(1.0, 0.18, 0.14)
	return true


func heal_to_full() -> void:
	_combat_health.restore_full()


func prepare_respawn() -> void:
	_combat_dead = false
	_dodge_time_left = 0.0
	_invulnerable_time_left = 0.0
	velocity = Vector3.ZERO
	heal_to_full()


func get_health_component() -> Node:
	return _combat_health


func is_combat_dead() -> bool:
	return _combat_dead


func is_dodging() -> bool:
	return _dodge_time_left > 0.0


func is_combat_invulnerable() -> bool:
	return _invulnerable_time_left > 0.0


func get_dodge_cooldown_left() -> float:
	return _dodge_cooldown_left


func set_click_destination_bounds(enabled: bool, bounds := Rect2()) -> void:
	_click_bounds_enabled = enabled
	_click_bounds = bounds
	if enabled:
		cancel_active_movement()


func _on_health_changed(_current: float, _maximum: float) -> void:
	combat_health_changed.emit()


func _on_died() -> void:
	_combat_dead = true
	cancel_active_movement()
	set_movement_locked(true)
	combat_died.emit()


func _update_hit_flash(delta: float) -> void:
	if _hit_flash_left <= 0.0:
		return
	_hit_flash_left = maxf(_hit_flash_left - delta, 0.0)
	if _hit_flash_left <= 0.0 and _body_material != null:
		_body_material.albedo_color = _body_base_color


func _build_visual_baseline_character() -> void:
	var prototype_mesh := get_node_or_null("Mesh") as MeshInstance3D
	if prototype_mesh != null:
		prototype_mesh.visible = false
	_visual_root = Node3D.new()
	_visual_root.name = "M05VisualRoot"
	add_child(_visual_root)

	_body_material = CHARACTER_CLOTH.duplicate() as StandardMaterial3D
	_body_base_color = _body_material.albedo_color
	var leather := CHARACTER_LEATHER
	var cloth := CHARACTER_OUTER_CLOTH
	var skin := CHARACTER_SKIN
	var accent := _visual_material(Color(0.30, 0.70, 0.66), 0.72)

	var tunic_mesh := CylinderMesh.new()
	tunic_mesh.top_radius = 0.31
	tunic_mesh.bottom_radius = 0.43
	tunic_mesh.height = 0.88
	tunic_mesh.radial_segments = 6
	tunic_mesh.material = _body_material
	_tunic_visual = MeshInstance3D.new()
	_tunic_visual.name = "Tunic"
	_tunic_visual.position.y = -0.10
	_tunic_visual.mesh = tunic_mesh
	_tunic_visual.material_override = _body_material
	_visual_root.add_child(_tunic_visual)

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.29
	head_mesh.height = 0.56
	head_mesh.radial_segments = 8
	head_mesh.rings = 4
	head_mesh.material = skin
	var head := MeshInstance3D.new()
	head.name = "Head"
	head.position.y = 0.57
	head.mesh = head_mesh
	_visual_root.add_child(head)

	var hood_mesh := CylinderMesh.new()
	hood_mesh.top_radius = 0.23
	hood_mesh.bottom_radius = 0.31
	hood_mesh.height = 0.20
	hood_mesh.radial_segments = 6
	hood_mesh.material = cloth
	var hood := MeshInstance3D.new()
	hood.name = "Hood"
	hood.position.y = 0.80
	hood.mesh = hood_mesh
	_visual_root.add_child(hood)

	_add_visual_box(_visual_root, "Belt", Vector3(0, 0.04, 0), Vector3(0.78, 0.10, 0.68), leather)
	_cape_visual = _add_visual_box(_visual_root, "Cape", Vector3(0, -0.02, 0.31), Vector3(0.62, 0.72, 0.10), cloth)
	_add_visual_box(_visual_root, "AccentClasp", Vector3(0, 0.32, -0.33), Vector3(0.18, 0.12, 0.08), accent)
	_left_boot_visual = _add_visual_box(_visual_root, "BootLeft", Vector3(-0.18, -0.68, -0.04), Vector3(0.24, 0.36, 0.34), leather)
	_right_boot_visual = _add_visual_box(_visual_root, "BootRight", Vector3(0.18, -0.68, -0.04), Vector3(0.24, 0.36, 0.34), leather)
	_left_arm_pivot = _add_arm(_visual_root, "LeftArmPivot", -0.38, cloth, skin)
	_right_arm_pivot = _add_arm(_visual_root, "RightArmPivot", 0.38, cloth, skin)


func _add_arm(parent: Node3D, node_name: String, x_position: float, cloth: Material, skin: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = Vector3(x_position, 0.26, -0.02)
	parent.add_child(pivot)
	_add_visual_box(pivot, "Sleeve", Vector3(0.0, -0.18, 0.0), Vector3(0.18, 0.38, 0.22), cloth)
	_add_visual_box(pivot, "Hand", Vector3(0.0, -0.42, -0.02), Vector3(0.16, 0.18, 0.17), skin)
	return pivot


func _update_visual_motion(delta: float) -> void:
	if _visual_root == null:
		return
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var moving := horizontal_speed > 0.12 and not _combat_dead
	_walk_blend = move_toward(_walk_blend, 1.0 if moving else 0.0, delta * 7.0)
	if moving:
		_walk_phase = fmod(_walk_phase + delta * (7.0 + horizontal_speed * 0.55), TAU)
	var stride := sin(_walk_phase) * _walk_blend
	var bounce := absf(sin(_walk_phase * 2.0)) * 0.035 * _walk_blend
	_visual_root.position.y = bounce
	if _tunic_visual != null:
		_tunic_visual.rotation.z = stride * 0.035
	if _cape_visual != null:
		_cape_visual.rotation.x = -0.08 - absf(stride) * 0.12
	if _left_boot_visual != null:
		_left_boot_visual.rotation.x = stride * 0.52
	if _right_boot_visual != null:
		_right_boot_visual.rotation.x = -stride * 0.52
	if _left_arm_pivot != null:
		_left_arm_pivot.rotation.x = -stride * 0.42
	if _right_arm_pivot != null and not _attack_visual_active:
		_right_arm_pivot.rotation.x = stride * 0.42


func _add_visual_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.position = position
	visual.mesh = mesh
	parent.add_child(visual)
	return visual


func _visual_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
