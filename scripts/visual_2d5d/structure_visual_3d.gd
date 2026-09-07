@tool
class_name StructureVisual3D
extends SpriteProp3D

@export_range(-180.0, 180.0, 0.1) var fixed_yaw_degrees := 0.0


func apply_config() -> void:
	super.apply_config()
	if sprite != null:
		sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	rotation_degrees.y = fixed_yaw_degrees
