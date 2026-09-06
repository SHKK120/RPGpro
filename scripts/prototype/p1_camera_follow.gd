extends Camera3D

@export var follow_response: float = 10.0
@export_node_path("Node3D") var target_path: NodePath

var _target: Node3D
var _horizontal_offset := Vector2.ZERO
var _fixed_height := 0.0


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D
	_fixed_height = global_position.y
	if _target == null:
		push_error("P1-3 camera requires a Node3D assigned to target_path; camera follow is disabled.")
		set_process(false)
		return

	_horizontal_offset = Vector2(
		global_position.x - _target.global_position.x,
		global_position.z - _target.global_position.z,
	)


func _process(delta: float) -> void:
	var target_position := Vector3(
		_target.global_position.x + _horizontal_offset.x,
		_fixed_height,
		_target.global_position.z + _horizontal_offset.y,
	)
	var follow_weight := 1.0 - exp(-maxf(follow_response, 0.0) * delta)

	if global_position.distance_squared_to(target_position) <= 0.000001:
		global_position = target_position
	else:
		global_position = global_position.lerp(target_position, follow_weight)
