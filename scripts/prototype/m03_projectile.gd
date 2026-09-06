extends CharacterBody3D

var _controller: Node
var _player: CharacterBody3D
var _direction := Vector3.ZERO
var _speed := 7.0
var _damage := 10.0
var _lifetime := 4.0


func configure(controller: Node, player: CharacterBody3D, start: Vector3, target: Vector3, damage: float, speed: float, exceptions: Array) -> void:
	_controller = controller
	_player = player
	global_position = start
	_direction = (target - start).normalized()
	_damage = damage
	_speed = speed
	for exception in exceptions:
		if exception is PhysicsBody3D:
			add_collision_exception_with(exception)


func _physics_process(delta: float) -> void:
	_lifetime -= delta
	if _lifetime <= 0.0 or _controller == null or not bool(_controller.call("is_combat_active")):
		queue_free()
		return
	var collision := move_and_collide(_direction * _speed * delta)
	if collision == null:
		return
	if collision.get_collider() == _player:
		_controller.call("damage_player", _damage, global_position)
	queue_free()
