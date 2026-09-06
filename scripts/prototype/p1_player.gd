extends CharacterBody3D

@export var move_speed: float = 4.0
@export_node_path("Camera3D") var camera_path: NodePath

var _movement_camera: Camera3D


func _ready() -> void:
	_movement_camera = get_node_or_null(camera_path) as Camera3D
	if _movement_camera == null:
		push_error("P1 player requires a Camera3D assigned to camera_path; horizontal movement is disabled.")


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_direction := Vector3.ZERO

	if _movement_camera != null:
		var camera_right := _movement_camera.global_transform.basis.x
		camera_right.y = 0.0
		camera_right = camera_right.normalized()

		var camera_forward := -_movement_camera.global_transform.basis.z
		camera_forward.y = 0.0
		camera_forward = camera_forward.normalized()

		move_direction = camera_right * input_vector.x + camera_forward * -input_vector.y
		if move_direction.length_squared() > 1.0:
			move_direction = move_direction.normalized()

	velocity.x = move_direction.x * move_speed
	velocity.z = move_direction.z * move_speed

	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity += get_gravity() * delta

	move_and_slide()
