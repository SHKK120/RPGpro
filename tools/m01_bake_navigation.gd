extends SceneTree

const SCENE_PATH := "res://scenes/prototype/coast_preview.tscn"
const NAVIGATION_MESH_PATH := "res://scenes/prototype/m01_navigation_mesh.tres"


func _initialize() -> void:
	call_deferred("_bake")


func _bake() -> void:
	var packed_scene := load(SCENE_PATH) as PackedScene
	if packed_scene == null:
		push_error("Could not load M01 coast preview scene.")
		quit(1)
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame

	var region := scene.get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	if region == null or region.navigation_mesh == null:
		push_error("M01 scene requires NavigationRegion3D with a NavigationMesh.")
		quit(1)
		return

	region.bake_navigation_mesh(false)
	var navigation_mesh := region.navigation_mesh
	if navigation_mesh.get_polygon_count() == 0:
		push_error("M01 navigation bake produced no polygons.")
		quit(1)
		return

	var save_error := ResourceSaver.save(navigation_mesh, NAVIGATION_MESH_PATH)
	if save_error != OK:
		push_error("Could not save M01 NavigationMesh: %s" % error_string(save_error))
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

	for frame in range(60):
		NavigationServer3D.map_force_update(navigation_map)
		if NavigationServer3D.map_get_iteration_id(navigation_map) > 0:
			break
		await process_frame

	var path_start := NavigationServer3D.map_get_closest_point(navigation_map, Vector3(0.0, 0.0, 4.0))
	var path_target := NavigationServer3D.map_get_closest_point(navigation_map, Vector3(0.0, 0.0, -3.8))
	var preview_path := NavigationServer3D.map_get_path(navigation_map, path_start, path_target, true)
	if preview_path.size() < 2 or _horizontal_distance(preview_path[-1], path_target) > 0.75:
		NavigationServer3D.free_rid(navigation_region)
		NavigationServer3D.free_rid(navigation_map)
		push_error("M01 NavigationMesh does not connect the start and vista points.")
		quit(1)
		return

	NavigationServer3D.free_rid(navigation_region)
	NavigationServer3D.free_rid(navigation_map)
	print("M01_NAV_BAKE_OK vertices=%d polygons=%d path_points=%d" % [
		navigation_mesh.get_vertices().size(),
		navigation_mesh.get_polygon_count(),
		preview_path.size(),
	])
	quit(0)


func _horizontal_distance(from: Vector3, to: Vector3) -> float:
	var offset := to - from
	offset.y = 0.0
	return offset.length()
