extends SceneTree

const SCENE_PATH := "res://scenes/prototype/green_coast_m02.tscn"
const NAVIGATION_MESH_PATH := "res://scenes/prototype/m02_navigation_mesh.tres"


func _initialize() -> void:
	call_deferred("_bake")


func _bake() -> void:
	var packed_scene := load(SCENE_PATH) as PackedScene
	if packed_scene == null:
		push_error("Could not load M02 Green Coast scene.")
		quit(1)
		return
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	var region := scene.get_node("NavigationRegion3D") as NavigationRegion3D
	region.bake_navigation_mesh(false)
	var navigation_mesh := region.navigation_mesh
	if navigation_mesh.get_polygon_count() == 0:
		push_error("M02 navigation bake produced no polygons.")
		quit(1)
		return
	var save_error := ResourceSaver.save(navigation_mesh, NAVIGATION_MESH_PATH)
	if save_error != OK:
		push_error("Could not save M02 NavigationMesh: %s" % error_string(save_error))
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
	var points := [Vector3(0, 0, 5.5), Vector3(-8, 0, 1.8), Vector3(8.5, 0, -1.5), Vector3(0, 0, -9), Vector3(0, 0, 5.5)]
	var route_points := 0
	for index in range(points.size() - 1):
		var start := NavigationServer3D.map_get_closest_point(navigation_map, points[index])
		var target := NavigationServer3D.map_get_closest_point(navigation_map, points[index + 1])
		var path := NavigationServer3D.map_get_path(navigation_map, start, target, true)
		print("M02_ROUTE_SEGMENT %d start=%s target=%s path_points=%d" % [index, str(start), str(target), path.size()])
		if path.size() < 2:
			push_error("M02 route segment %d is disconnected." % index)
			NavigationServer3D.free_rid(navigation_region)
			NavigationServer3D.free_rid(navigation_map)
			quit(1)
			return
		route_points += path.size()
	NavigationServer3D.free_rid(navigation_region)
	NavigationServer3D.free_rid(navigation_map)
	print("M02_NAV_BAKE_OK vertices=%d polygons=%d route_points=%d" % [navigation_mesh.get_vertices().size(), navigation_mesh.get_polygon_count(), route_points])
	quit(0)
