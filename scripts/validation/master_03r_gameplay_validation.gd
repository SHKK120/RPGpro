extends Master03RValidationBase

const ACTOR_SCENE := preload("res://scenes/visual_2d5d/directional_sprite_actor_3d.tscn")

@export var move_speed := 4.2
var player: CharacterBody3D
var move_target := Vector3.ZERO
var has_move_target := false


func _ready() -> void:
	build_validation_world(true)
	_build_player()


func _physics_process(_delta_time: float) -> void:
	if player == null:
		return
	if has_move_target:
		var target_delta := move_target - player.global_position
		target_delta.y = 0.0
		if target_delta.length() < 0.12:
			player.velocity.x = 0.0
			player.velocity.z = 0.0
			has_move_target = false
		else:
			var planar_velocity := target_delta.normalized() * move_speed
			player.velocity.x = planar_velocity.x
			player.velocity.z = planar_velocity.z
			var actor := player.get_node("DirectionalSpriteActor3D") as DirectionalSpriteActor3D
			actor.set_facing(planar_velocity)
	else:
		player.velocity.x = 0.0
		player.velocity.z = 0.0
	player.velocity.y = 0.0
	player.move_and_slide()
	# This small validation scene tests horizontal click movement and proxy blocking.
	# Production height/ramp motion remains owned by the preserved 3D gameplay layer.
	player.position.y = 0.92


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var origin := validation_camera.project_ray_origin(event.position)
		var direction := validation_camera.project_ray_normal(event.position)
		if absf(direction.y) > 0.0001:
			var distance := -origin.y / direction.y
			if distance > 0.0:
				set_move_target(origin + direction * distance)


func set_move_target(target: Vector3) -> void:
	move_target = Vector3(clampf(target.x, -8.0, 8.0), 0.92, clampf(target.z, -9.0, 9.0))
	has_move_target = true


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0.8, 0.92, -6.6)
	player.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	player.collision_layer = 1
	player.collision_mask = 2
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.7
	shape.shape = capsule
	player.add_child(shape)
	var actor := ACTOR_SCENE.instantiate() as DirectionalSpriteActor3D
	actor.name = "DirectionalSpriteActor3D"
	actor.position.y = -0.92
	actor.asset_config = load("res://assets/art/green_coast_2d5d_v01/configs/directional_marker.tres")
	player.add_child(actor)
	add_child(player)
	actor.apply_config()
