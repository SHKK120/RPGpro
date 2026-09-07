@tool
class_name CollisionProxy3D
extends StaticBody3D

@export var collision_type: AssetConfig2D5D.CollisionType = AssetConfig2D5D.CollisionType.NONE
@export var collision_size := Vector3.ONE
@export var collision_offset := Vector3.ZERO
@export var proxy_enabled := true


func _init() -> void:
	# Keep visual proxy bodies separate from the terrain physics layer. Production
	# actors can combine both masks; the validation actor isolates proxy blocking.
	collision_layer = 2
	collision_mask = 0


func _ready() -> void:
	rebuild()


func apply_config(config: AssetConfig2D5D) -> void:
	collision_type = config.collision_type
	collision_size = config.collision_size
	collision_offset = config.collision_offset
	rebuild()


func rebuild() -> void:
	var collision_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		add_child(collision_shape)
	collision_shape.position = collision_offset
	collision_shape.disabled = not proxy_enabled or collision_type == AssetConfig2D5D.CollisionType.NONE
	match collision_type:
		AssetConfig2D5D.CollisionType.BOX:
			var box := BoxShape3D.new()
			box.size = collision_size
			collision_shape.shape = box
		AssetConfig2D5D.CollisionType.CAPSULE:
			var capsule := CapsuleShape3D.new()
			capsule.radius = collision_size.x * 0.5
			capsule.height = maxf(collision_size.y, collision_size.x)
			collision_shape.shape = capsule
		AssetConfig2D5D.CollisionType.CYLINDER:
			var cylinder := CylinderShape3D.new()
			cylinder.radius = collision_size.x * 0.5
			cylinder.height = collision_size.y
			collision_shape.shape = cylinder
		_:
			collision_shape.shape = null
