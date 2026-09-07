extends SceneTree

const GAME_SCENE := preload("res://scenes/prototype/green_coast_m02.tscn")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var mode := "home"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--master03-view="):
			mode = argument.trim_prefix("--master03-view=")
	var game := GAME_SCENE.instantiate()
	root.add_child(game)
	current_scene = game
	for index in range(4):
		await process_frame
	game.call("_start_new_game")
	await process_frame
	var player := game.get_node("Player") as CharacterBody3D
	var camera := game.get_node("Camera") as Camera3D
	camera.set_process(false)
	var camera_position := Vector3(0, 9.5, 15.5)
	var target := Vector3(0, 0.6, 4.0)
	match mode:
		"home":
			player.global_position = Vector3(0, 1, 5.5)
			camera_position = Vector3(-1.2, 4.9, 11.0)
			target = Vector3(0.8, 1.0, 1.8)
		"cliff":
			player.global_position = Vector3(-3.0, 1, -6.4)
			camera_position = Vector3(-5.8, 4.8, 0.2)
			target = Vector3(-1.0, 0.55, -9.5)
		"ruins":
			player.global_position = Vector3(4.6, 1, -0.6)
			camera_position = Vector3(1.2, 4.9, 5.4)
			target = Vector3(8.5, 1.0, -3.2)
		"beach":
			player.global_position = Vector3(0, 1, -9.2)
			camera_position = Vector3(-4.2, 4.3, -3.0)
			target = Vector3(-1.0, -0.45, -17.5)
		"vista":
			player.global_position = Vector3(0, 1, -10.6)
			camera_position = Vector3(0, 4.6, -4.2)
			target = Vector3(0, -0.15, -25.0)
		"overview":
			player.global_position = Vector3(0, 1, 5.5)
			camera_position = Vector3(8.0, 28.0, 29.0)
			target = Vector3(5.0, 0.0, -1.5)
		"boss":
			game.set("_first_combat_loop_completed", true)
			game.call("_apply_m04_world_state")
			player.global_position = Vector3(18.0, 1, 2.5)
			camera_position = Vector3(16.0, 10.0, 12.5)
			target = Vector3(23.0, 0.8, 2.5)
	camera.fov = 52.0
	camera.global_transform = Transform3D(Basis.IDENTITY, camera_position).looking_at(target, Vector3.UP)
	for index in range(10):
		await process_frame
	print("MASTER03_CAPTURE_OK view=" + mode)
	quit(0)
