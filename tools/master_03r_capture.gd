extends SceneTree

const SCENES := {
	"assembly": "res://scenes/reference/master_03r_assembly_validation.tscn",
	"gameplay": "res://scenes/reference/master_03r_gameplay_validation.tscn",
}


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var mode := "assembly"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--master03r-scene="):
			mode = argument.get_slice("=", 1)
	if not SCENES.has(mode):
		push_error("Unknown MASTER-03R capture mode: %s" % mode)
		quit(2)
		return
	root.size = Vector2i(1440, 900)
	var packed := load(SCENES[mode]) as PackedScene
	if packed == null:
		push_error("Could not load validation scene: %s" % SCENES[mode])
		quit(3)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	for _frame in range(12):
		await process_frame
	var output := "res://art/review/master_03r_%s.png" % mode
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/review"))
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		# Headless uses the dummy renderer. Automated screenshots are produced by
		# running this same script with --write-movie and the ANGLE renderer.
		print("MASTER03R_CAPTURE_FRAME_READY mode=%s" % mode)
		quit()
		return
	var error := viewport_texture.get_image().save_png(ProjectSettings.globalize_path(output))
	if error != OK:
		push_error("Capture failed: %s (%s)" % [output, error])
		quit(4)
		return
	print("MASTER03R_CAPTURE_OK mode=%s path=%s size=%s" % [mode, output, root.size])
	quit()
