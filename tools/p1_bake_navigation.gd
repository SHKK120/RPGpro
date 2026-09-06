extends SceneTree

const SCENE_PATH := "res://scenes/prototype/p1_movement.tscn"
const NAVIGATION_MESH_PATH := "res://scenes/prototype/p1_navigation_mesh.tres"


func _initialize() -> void:
	call_deferred("_bake")


func _bake() -> void:
	var packed_scene := load(SCENE_PATH) as PackedScene
	if packed_scene == null:
		push_error("Could not load P1 movement scene.")
		quit(1)
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame

	var region := scene.get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	if region == null or region.navigation_mesh == null:
		push_error("P1 movement scene requires NavigationRegion3D with a NavigationMesh.")
		quit(1)
		return

	region.bake_navigation_mesh(false)
	var navigation_mesh := region.navigation_mesh
	if navigation_mesh.get_polygon_count() == 0:
		push_error("Navigation bake produced no polygons.")
		quit(1)
		return

	var save_error := ResourceSaver.save(navigation_mesh, NAVIGATION_MESH_PATH)
	if save_error != OK:
		push_error("Could not save baked NavigationMesh: %s" % error_string(save_error))
		quit(1)
		return

	var navigation_map := NavigationServer3D.map_create()
	NavigationServer3D.map_set_cell_size(navigation_map, navigation_mesh.cell_size)
	NavigationServer3D.map_set_cell_height(navigation_map, navigation_mesh.cell_height)
	NavigationServer3D.map_set_active(navigation_map, true)
	var navigation_region := NavigationServer3D.region_create()
	NavigationServer3D.region_set_map(navigation_region, navigation_map)
	NavigationServer3D.region_set_transform(navigation_region, Transform3D.IDENTITY)
	NavigationServer3D.region_set_enabled(navigation_region, true)
	NavigationServer3D.region_set_navigation_mesh(navigation_region, navigation_mesh)
	var synchronized_frames := 0
	for frame in range(60):
		NavigationServer3D.map_force_update(navigation_map)
		if NavigationServer3D.map_get_iteration_id(navigation_map) > 0:
			synchronized_frames += 1
			if synchronized_frames >= 3:
				break
		await process_frame
	if NavigationServer3D.map_get_iteration_id(navigation_map) == 0:
		NavigationServer3D.free_rid(navigation_region)
		NavigationServer3D.free_rid(navigation_map)
		push_error("Navigation test map did not finish its first synchronization.")
		quit(1)
		return

	var path_start := NavigationServer3D.map_get_closest_point(navigation_map, Vector3(-3.0, 0.0, 3.5))
	var path_target := NavigationServer3D.map_get_closest_point(navigation_map, Vector3(-3.0, 0.0, -4.0))
	var obstacle_path := NavigationServer3D.map_get_path(navigation_map, path_start, path_target, true)
	print("P1_NAV_PATH_PROBE iteration=%d start=%s target=%s points=%s" % [
		NavigationServer3D.map_get_iteration_id(navigation_map),
		path_start,
		path_target,
		obstacle_path,
	])
	if obstacle_path.size() < 3 or _horizontal_distance(obstacle_path[-1], path_target) > 0.75:
		NavigationServer3D.free_rid(navigation_region)
		NavigationServer3D.free_rid(navigation_map)
		push_error("Navigation bake did not produce a usable route around the fixed box.")
		quit(1)
		return

	NavigationServer3D.free_rid(navigation_region)
	NavigationServer3D.free_rid(navigation_map)
	print("P1_NAV_BAKE_OK vertices=%d polygons=%d obstacle_path_points=%d" % [
		navigation_mesh.get_vertices().size(),
		navigation_mesh.get_polygon_count(),
		obstacle_path.size(),
	])
	quit()


func _horizontal_distance(from: Vector3, to: Vector3) -> float:
	var offset := to - from
	offset.y = 0.0
	return offset.length()
