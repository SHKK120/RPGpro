class_name AssetConfig2D5D
extends Resource

enum VisualType {
	BILLBOARD_VEGETATION,
	DIRECTIONAL_ACTOR,
	FIXED_ANGLE_STRUCTURE,
	HYBRID_STRUCTURE,
	SIMPLE_3D_FOUNDATION,
}

enum FacingMode {
	BILLBOARD,
	Y_BILLBOARD,
	FIXED_ANGLE,
	DIRECTIONAL_4,
	DIRECTIONAL_8,
}

enum CollisionType {
	NONE,
	BOX,
	CAPSULE,
	CYLINDER,
}

@export var visual_type: VisualType = VisualType.BILLBOARD_VEGETATION
@export var facing_mode: FacingMode = FacingMode.Y_BILLBOARD
@export var texture: Texture2D
@export var sprite_frames: SpriteFrames
@export_range(0.0001, 0.1, 0.0001) var pixel_size := 0.005
@export_range(0.05, 10.0, 0.01) var uniform_scale := 1.0
@export var ground_pivot := Vector2(0.5, 1.0)
@export var collision_type: CollisionType = CollisionType.NONE
@export var collision_size := Vector3.ONE
@export var collision_offset := Vector3.ZERO
@export var optional_shadow := true
@export var navigation_obstacle := false


func visual_world_size() -> Vector2:
	if texture == null:
		return Vector2.ZERO
	return Vector2(texture.get_width(), texture.get_height()) * pixel_size * uniform_scale


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if texture == null and sprite_frames == null:
		errors.append("texture or sprite_frames is required")
	if pixel_size <= 0.0:
		errors.append("pixel_size must be positive")
	if uniform_scale <= 0.0:
		errors.append("uniform_scale must be positive")
	if ground_pivot.x < 0.0 or ground_pivot.x > 1.0 or ground_pivot.y < 0.0 or ground_pivot.y > 1.0:
		errors.append("ground_pivot must stay within normalized image bounds")
	if collision_type != CollisionType.NONE and (collision_size.x <= 0.0 or collision_size.y <= 0.0 or collision_size.z <= 0.0):
		errors.append("collision_size must be positive")
	return errors
