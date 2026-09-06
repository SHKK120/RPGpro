extends SceneTree

const ASSET_ROOT := "res://assets/art/green_coast_v01"
const SCENE_ROOT := "res://scenes/art/green_coast_v01"
const TEXTURE_SIZE := 64

var _materials: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_make_directories()
	_build_textures()
	if "--textures-only" in OS.get_cmdline_user_args():
		print("ART01_TEXTURES_READY textures=4 texture_size=%d" % TEXTURE_SIZE)
		quit(0)
		return
	_build_materials()
	_build_visual_scenes()
	print("ART01_BUILD_OK textures=4 materials=6 visual_scenes=9 texture_size=%d" % TEXTURE_SIZE)
	quit(0)


func _make_directories() -> void:
	for directory in [
		ASSET_ROOT.path_join("textures"),
		ASSET_ROOT.path_join("materials"),
		SCENE_ROOT,
	]:
		var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
		if error != OK:
			_fail("Could not create ART-01 directory: " + directory)


func _build_textures() -> void:
	_save_texture("stone_pixel", _stone_image())
	_save_texture("wood_pixel", _wood_image())
	_save_texture("leaf_pixel", _leaf_image())
	_save_texture("soil_pixel", _soil_image())


func _save_texture(file_name: String, image: Image) -> void:
	var path := ASSET_ROOT.path_join("textures").path_join(file_name + ".png")
	if image.save_png(ProjectSettings.globalize_path(path)) != OK:
		_fail("Could not save ART-01 texture: " + path)


func _stone_image() -> Image:
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var colors := [
		Color("#68716d"), Color("#77817a"), Color("#59645f"), Color("#899087"),
		Color("#53615a"),
	]
	for y in range(TEXTURE_SIZE):
		for x in range(TEXTURE_SIZE):
			var block := (x / 8 + (y / 8) * 3) % 4
			var color: Color = colors[block]
			if (y % 16 == 7 or y % 16 == 8) and x % 24 < 18:
				color = colors[2]
			if (x + y * 2) % 41 == 0:
				color = colors[4]
			image.set_pixel(x, y, color)
	return image


func _wood_image() -> Image:
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var colors := [Color("#674630"), Color("#795139"), Color("#8a6040"), Color("#543928"), Color("#9b704b")]
	for y in range(TEXTURE_SIZE):
		for x in range(TEXTURE_SIZE):
			var band := (y / 8 + x / 24) % 3
			var color: Color = colors[band]
			if y % 16 == 0 or y % 16 == 1:
				color = colors[3]
			if (x + y / 4) % 29 < 2:
				color = colors[4]
			image.set_pixel(x, y, color)
	return image


func _leaf_image() -> Image:
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var colors := [Color("#325b3d"), Color("#3f7047"), Color("#4d7d4d"), Color("#284c35"), Color("#628b55")]
	for y in range(TEXTURE_SIZE):
		for x in range(TEXTURE_SIZE):
			var cluster := ((x / 8) * 2 + y / 8) % 4
			var color: Color = colors[cluster]
			if (x / 4 + y / 4) % 11 == 0:
				color = colors[4]
			image.set_pixel(x, y, color)
	return image


func _soil_image() -> Image:
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var colors := [Color("#79684f"), Color("#827158"), Color("#6e614a"), Color("#89775b"), Color("#625741")]
	for y in range(TEXTURE_SIZE):
		for x in range(TEXTURE_SIZE):
			var patch := (x / 16 + (y / 16) * 2) % 4
			var color: Color = colors[patch]
			if x % 24 >= 18 and y % 24 >= 18:
				color = colors[4]
			image.set_pixel(x, y, color)
	return image


func _build_materials() -> void:
	_materials["stone"] = _save_material("stone", "stone_pixel", Color("#b3bfb8"), 0.93, 0.75, true)
	_materials["cliff"] = _save_material("cliff_stone", "stone_pixel", Color("#c2b394"), 0.96, 1.0, true)
	_materials["wood"] = _save_material("wood", "wood_pixel", Color("#c79c6e"), 0.92, 2.0)
	_materials["leaf"] = _save_material("leaf", "leaf_pixel", Color("#9eb885"), 0.96, 2.5)
	_materials["soil"] = _save_material("soil", "soil_pixel", Color("#b89e75"), 0.98, 2.5)
	_materials["ground"] = _save_material("ground", "soil_pixel", Color("#788c63"), 0.99, 4.0)


func _save_material(file_name: String, texture_name: String, tint: Color, roughness: float, uv_scale: float, triplanar := false) -> StandardMaterial3D:
	var texture_path := ASSET_ROOT.path_join("textures").path_join(texture_name + ".png")
	var material := StandardMaterial3D.new()
	material.resource_name = file_name
	material.albedo_texture = load(texture_path) as Texture2D
	material.albedo_color = tint
	material.roughness = roughness
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.uv1_scale = Vector3.ONE * uv_scale
	material.uv1_triplanar = triplanar
	var path := ASSET_ROOT.path_join("materials").path_join(file_name + ".tres")
	if ResourceSaver.save(material, path) != OK:
		_fail("Could not save ART-01 material: " + path)
	return load(path) as StandardMaterial3D


func _build_visual_scenes() -> void:
	_save_scene("cliff_chunk", _make_cliff_chunk())
	_save_scene("tree", _make_tree())
	_save_scene("shrub_cluster", _make_shrub_cluster())
	_save_scene("fence_section", _make_fence_section())
	_save_scene("ruin_rubble", _make_ruin_rubble())
	_save_scene("bench", _make_bench())
	_save_scene("display_pedestal", _make_display_pedestal())
	_save_scene("wood_pickup", _make_wood_pickup())
	_save_scene("stone_pickup", _make_stone_pickup())


func _new_visual_root(node_name: String) -> Node3D:
	var scene_root := Node3D.new()
	scene_root.name = node_name
	root.add_child(scene_root)
	return scene_root


func _save_scene(file_name: String, scene_root: Node3D) -> void:
	var packed := PackedScene.new()
	if packed.pack(scene_root) != OK:
		_fail("Could not pack ART-01 scene: " + file_name)
	var path := SCENE_ROOT.path_join(file_name + ".tscn")
	if ResourceSaver.save(packed, path) != OK:
		_fail("Could not save ART-01 scene: " + path)
	root.remove_child(scene_root)
	scene_root.free()


func _add_box(scene_root: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.rotation_degrees = rotation
	scene_root.add_child(instance)
	instance.owner = scene_root
	return instance


func _add_cylinder(scene_root: Node3D, node_name: String, position: Vector3, top_radius: float, bottom_radius: float, height: float, material: Material, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 6
	mesh.rings = 1
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.rotation_degrees = rotation
	scene_root.add_child(instance)
	instance.owner = scene_root
	return instance


func _make_cliff_chunk() -> Node3D:
	var scene_root := _new_visual_root("CliffChunk")
	_add_box(scene_root, "LowerLayer", Vector3(0, -0.72, 0), Vector3(4.9, 0.65, 1.35), _materials["cliff"], Vector3(0, 2, 0))
	_add_box(scene_root, "MiddleLayer", Vector3(-0.12, -0.18, -0.08), Vector3(4.65, 0.55, 1.05), _materials["cliff"], Vector3(0, -2, 0))
	_add_box(scene_root, "TopLayer", Vector3(0.08, 0.27, 0.02), Vector3(4.75, 0.42, 0.85), _materials["cliff"], Vector3(0, 1, 0))
	return scene_root


func _make_tree() -> Node3D:
	var scene_root := _new_visual_root("TreeVisual")
	_add_cylinder(scene_root, "Trunk", Vector3(0, 1.05, 0), 0.34, 0.48, 2.1, _materials["wood"])
	_add_box(scene_root, "CrownLow", Vector3(0, 2.35, 0), Vector3(2.0, 1.15, 1.75), _materials["leaf"], Vector3(0, 12, 6))
	_add_box(scene_root, "CrownHigh", Vector3(-0.18, 3.05, 0.05), Vector3(1.55, 1.0, 1.45), _materials["leaf"], Vector3(0, -16, -5))
	_add_box(scene_root, "CrownSide", Vector3(0.58, 2.68, -0.2), Vector3(1.0, 0.85, 1.05), _materials["leaf"], Vector3(0, 28, 9))
	return scene_root


func _make_shrub_cluster() -> Node3D:
	var scene_root := _new_visual_root("ShrubCluster")
	_add_box(scene_root, "LeafA", Vector3(-0.42, 0.32, 0), Vector3(0.8, 0.62, 0.72), _materials["leaf"], Vector3(0, 20, 8))
	_add_box(scene_root, "LeafB", Vector3(0.18, 0.42, -0.08), Vector3(0.95, 0.78, 0.82), _materials["leaf"], Vector3(0, -14, -7))
	_add_box(scene_root, "LeafC", Vector3(0.67, 0.27, 0.15), Vector3(0.62, 0.52, 0.7), _materials["leaf"], Vector3(0, 32, 6))
	return scene_root


func _make_fence_section() -> Node3D:
	var scene_root := _new_visual_root("FenceSection")
	for x in [-2.2, 0.0, 2.2]:
		_add_box(scene_root, "Post_%s" % str(x), Vector3(x, 0.62, 0), Vector3(0.28, 1.25, 0.3), _materials["wood"], Vector3(0, 0, -2 if x < 0 else 2))
	_add_box(scene_root, "RailLow", Vector3(0, 0.42, 0), Vector3(4.7, 0.22, 0.24), _materials["wood"], Vector3(0, 0, 2))
	_add_box(scene_root, "RailHigh", Vector3(0, 0.88, 0), Vector3(4.7, 0.2, 0.22), _materials["wood"], Vector3(0, 0, -2))
	return scene_root


func _make_ruin_rubble() -> Node3D:
	var scene_root := _new_visual_root("RuinRubble")
	_add_box(scene_root, "SlabA", Vector3(-0.55, 0.18, 0), Vector3(1.15, 0.36, 0.7), _materials["stone"], Vector3(0, 18, 7))
	_add_box(scene_root, "SlabB", Vector3(0.5, 0.24, 0.18), Vector3(0.85, 0.48, 0.62), _materials["stone"], Vector3(0, -22, -9))
	_add_box(scene_root, "Block", Vector3(0.05, 0.32, -0.48), Vector3(0.58, 0.64, 0.58), _materials["stone"], Vector3(7, 8, 4))
	_add_cylinder(scene_root, "BrokenColumn", Vector3(-0.2, 0.28, 0.5), 0.3, 0.38, 0.85, _materials["stone"], Vector3(0, 0, 78))
	return scene_root


func _make_bench() -> Node3D:
	var scene_root := _new_visual_root("BenchVisual")
	_add_box(scene_root, "Seat", Vector3(0, 0.72, 0), Vector3(2.4, 0.24, 0.72), _materials["wood"])
	_add_box(scene_root, "Back", Vector3(0, 1.25, 0.31), Vector3(2.4, 0.72, 0.18), _materials["wood"], Vector3(-4, 0, 0))
	_add_box(scene_root, "LegLeft", Vector3(-0.86, 0.35, 0), Vector3(0.22, 0.7, 0.52), _materials["wood"])
	_add_box(scene_root, "LegRight", Vector3(0.86, 0.35, 0), Vector3(0.22, 0.7, 0.52), _materials["wood"])
	_add_box(scene_root, "Brace", Vector3(0, 0.32, 0), Vector3(1.8, 0.16, 0.18), _materials["wood"])
	return scene_root


func _make_display_pedestal() -> Node3D:
	var scene_root := _new_visual_root("DisplayPedestal")
	_add_box(scene_root, "Base", Vector3(0, 0.12, 0), Vector3(1.05, 0.24, 1.05), _materials["stone"])
	_add_box(scene_root, "Body", Vector3(0, 0.52, 0), Vector3(0.72, 0.68, 0.72), _materials["stone"])
	_add_box(scene_root, "Top", Vector3(0, 0.91, 0), Vector3(0.95, 0.16, 0.95), _materials["cliff"])
	return scene_root


func _make_wood_pickup() -> Node3D:
	var scene_root := _new_visual_root("WoodPickupVisual")
	_add_cylinder(scene_root, "LogA", Vector3(0, 0, 0), 0.17, 0.2, 0.82, _materials["wood"], Vector3(0, 0, 90))
	_add_cylinder(scene_root, "LogB", Vector3(0.02, 0.17, 0.18), 0.15, 0.18, 0.72, _materials["wood"], Vector3(8, 25, 86))
	_add_cylinder(scene_root, "LogC", Vector3(-0.04, 0.15, -0.18), 0.14, 0.17, 0.68, _materials["wood"], Vector3(-6, -18, 94))
	return scene_root


func _make_stone_pickup() -> Node3D:
	var scene_root := _new_visual_root("StonePickupVisual")
	_add_box(scene_root, "StoneA", Vector3(-0.2, 0, 0), Vector3(0.46, 0.34, 0.42), _materials["stone"], Vector3(8, 18, 12))
	_add_box(scene_root, "StoneB", Vector3(0.23, 0.04, 0.08), Vector3(0.38, 0.42, 0.36), _materials["stone"], Vector3(-10, -22, 8))
	_add_box(scene_root, "StoneC", Vector3(0.05, -0.03, -0.28), Vector3(0.32, 0.28, 0.3), _materials["cliff"], Vector3(12, 35, -7))
	return scene_root


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
