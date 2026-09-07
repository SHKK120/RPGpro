extends SceneTree

const REQUIRED_PATHS := [
	"res://scripts/visual_2d5d/asset_config_2d5d.gd",
	"res://scripts/visual_2d5d/collision_proxy_3d.gd",
	"res://scripts/visual_2d5d/sprite_prop_3d.gd",
	"res://scripts/visual_2d5d/structure_visual_3d.gd",
	"res://scripts/visual_2d5d/directional_sprite_actor_3d.gd",
	"res://scenes/visual_2d5d/sprite_prop_3d.tscn",
	"res://scenes/visual_2d5d/structure_visual_3d.tscn",
	"res://scenes/visual_2d5d/directional_sprite_actor_3d.tscn",
	"res://scenes/reference/master_03r_assembly_validation.tscn",
	"res://scenes/reference/master_03r_gameplay_validation.tscn",
]

const CONFIG_PATHS := [
	"res://assets/art/green_coast_2d5d_v01/configs/cottage.tres",
	"res://assets/art/green_coast_2d5d_v01/configs/broadleaf_tree.tres",
	"res://assets/art/green_coast_2d5d_v01/configs/ruin_arch.tres",
	"res://assets/art/green_coast_2d5d_v01/configs/rock_flower_cluster.tres",
	"res://assets/art/green_coast_2d5d_v01/configs/directional_marker.tres",
]

const SURFACE_PATHS := [
	"res://assets/art/green_coast_2d5d_v01/surface_samples/grass.png",
	"res://assets/art/green_coast_2d5d_v01/surface_samples/soil_path.png",
	"res://assets/art/green_coast_2d5d_v01/surface_samples/rock_cliff.png",
	"res://assets/art/green_coast_2d5d_v01/surface_samples/sand.png",
	"res://assets/art/green_coast_2d5d_v01/surface_samples/shallow_water.png",
]

var failures := PackedStringArray()
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: %s" % message)
	else:
		failures.append(message)
		push_error("FAIL: %s" % message)


func _count_type(node: Node, script_class: StringName) -> int:
	var count := 0
	if node.is_class(script_class):
		count += 1
	for child in node.get_children():
		count += _count_type(child, script_class)
	return count


func _count_proxies(node: Node) -> int:
	var count := 1 if node is CollisionProxy3D else 0
	for child in node.get_children():
		count += _count_proxies(child)
	return count


func _run() -> void:
	root.size = Vector2i(1440, 900)
	for path in REQUIRED_PATHS:
		_check(ResourceLoader.exists(path), "required resource exists: %s" % path)
	for path in CONFIG_PATHS:
		var config := load(path) as AssetConfig2D5D
		_check(config != null, "config loads: %s" % path)
		if config != null:
			_check(config.validation_errors().is_empty(), "config validates: %s" % path)
			_check(config.visual_world_size().x > 0.0 and config.visual_world_size().y > 0.0, "config keeps a positive, uniform visual size: %s" % path)
	for path in SURFACE_PATHS:
		var texture := load(path) as Texture2D
		_check(texture != null, "surface sample loads: %s" % path)
		if texture != null:
			_check(texture.get_width() == 256 and texture.get_height() == 256, "surface sample is square without stretch: %s" % path)

	var assembly_packed := load("res://scenes/reference/master_03r_assembly_validation.tscn") as PackedScene
	var assembly := assembly_packed.instantiate()
	root.add_child(assembly)
	current_scene = assembly
	for _frame in range(4):
		await process_frame
	_check(_count_type(assembly, &"Sprite3D") >= 10, "assembly uses layered Sprite3D visuals")
	_check(_count_proxies(assembly) >= 10, "assembly keeps independent 3D collision proxies")
	_check(assembly.get_node_or_null("GroundVisual") != null, "assembly keeps a real 3D ground foundation")
	_check(assembly.get_node_or_null("CliffFoundationVisual") != null, "assembly keeps a real 3D cliff foundation")
	var ground_material := (assembly.get_node("GroundVisual") as MeshInstance3D).get_active_material(0) as StandardMaterial3D
	var cliff_material := (assembly.get_node("CliffFoundationVisual") as MeshInstance3D).get_active_material(0) as StandardMaterial3D
	_check(ground_material != null and ground_material.texture_repeat and ground_material.uv1_scale.x >= 9.0 and ground_material.uv1_scale.y >= 10.0, "ground expands by repeated world-scale tiles instead of stretching")
	_check(cliff_material != null and cliff_material.texture_repeat and cliff_material.uv1_scale.x >= 12.0 and cliff_material.uv1_scale.y >= 1.5, "cliff expands by repeated world-scale tiles instead of stretching")
	assembly.queue_free()
	await process_frame

	var gameplay_packed := load("res://scenes/reference/master_03r_gameplay_validation.tscn") as PackedScene
	var gameplay := gameplay_packed.instantiate()
	root.add_child(gameplay)
	current_scene = gameplay
	for _frame in range(6):
		await physics_frame
	var label := gameplay.get_node_or_null("ValidationUI/InfoPanel/KoreanTextValidation") as Label
	_check(label != null and label.text.contains("우클릭 이동") and not label.text.contains("�"), "Korean UI source text is intact")
	var player := gameplay.get("player") as CharacterBody3D
	var actor := player.get_node("DirectionalSpriteActor3D") as DirectionalSpriteActor3D
	_check(actor.set_facing(Vector3(0, 0, 1)) == &"s", "directional actor resolves south")
	_check(actor.set_facing(Vector3(1, 0, 0)) == &"e", "directional actor resolves east")
	_check(actor.set_facing(Vector3(0, 0, -1)) == &"n", "directional actor resolves north")
	_check(actor.set_facing(Vector3(-1, 0, 0)) == &"w", "directional actor resolves west")
	var start_z := player.global_position.z
	gameplay.call("set_move_target", Vector3(0.8, 0.92, -4.0))
	for _frame in range(55):
		await physics_frame
	_check(player.global_position.z > start_z + 1.0, "click-to-move compatible movement advances on 3D ground")
	player.global_position = Vector3(-5.0, 0.92, 6.4)
	player.velocity = Vector3.ZERO
	await physics_frame
	gameplay.call("set_move_target", Vector3(-5.0, 0.92, -4.0))
	for _frame in range(150):
		await physics_frame
	print("MASTER03R_COLLISION_FINAL position=%s" % player.global_position)
	var collision_target := Vector3(-5.0, 0.92, -4.0)
	_check(player.global_position.distance_to(collision_target) > 2.0 and absf(player.global_position.x + 5.0) > 1.0, "2.5D cottage visual uses a blocking/deflecting 3D proxy")

	print("MASTER03R_VERIFY_SUMMARY checks=%d failures=%d" % [checks, failures.size()])
	if not failures.is_empty():
		for failure in failures:
			print("MASTER03R_FAILURE: %s" % failure)
		quit(1)
		return
	quit()
