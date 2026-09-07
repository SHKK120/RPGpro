@tool
class_name DirectionalSpriteActor3D
extends Node3D

const DIRECTIONS_8 := [&"s", &"sw", &"w", &"nw", &"n", &"ne", &"e", &"se"]
const DIRECTIONS_4 := [&"s", &"w", &"n", &"e"]

@export var asset_config: AssetConfig2D5D
@export var animation_state := &"idle"
@export var facing_vector := Vector3(0, 0, 1)

@onready var animated_sprite := get_node_or_null("VisualRoot/AnimatedSprite3D") as AnimatedSprite3D
@onready var fallback_sprite := get_node_or_null("VisualRoot/FallbackSprite3D") as Sprite3D


func _ready() -> void:
	apply_config()
	set_facing(facing_vector)


func apply_config() -> void:
	if asset_config == null:
		return
	if animated_sprite != null:
		animated_sprite.sprite_frames = asset_config.sprite_frames
		animated_sprite.pixel_size = asset_config.pixel_size
		animated_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		animated_sprite.shaded = false
		animated_sprite.visible = asset_config.sprite_frames != null
	if fallback_sprite != null:
		fallback_sprite.texture = asset_config.texture
		fallback_sprite.pixel_size = asset_config.pixel_size
		fallback_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		fallback_sprite.shaded = false
		fallback_sprite.visible = asset_config.sprite_frames == null and asset_config.texture != null
		if asset_config.texture != null:
			fallback_sprite.position.y = asset_config.texture.get_height() * asset_config.pixel_size * asset_config.uniform_scale * 0.5
	var proxy := get_node_or_null("CollisionProxy") as CollisionProxy3D
	if proxy != null:
		proxy.apply_config(asset_config)


func set_facing(direction: Vector3) -> StringName:
	var flat := Vector2(direction.x, direction.z)
	if flat.length_squared() < 0.0001:
		flat = Vector2(facing_vector.x, facing_vector.z)
	else:
		facing_vector = Vector3(flat.x, 0, flat.y).normalized()
	var eight_way := asset_config != null and asset_config.facing_mode == AssetConfig2D5D.FacingMode.DIRECTIONAL_8
	var names := DIRECTIONS_8 if eight_way else DIRECTIONS_4
	var angle := fposmod(atan2(-flat.x, flat.y), TAU)
	var index := int(round(angle / TAU * names.size())) % names.size()
	var suffix: StringName = names[index]
	_play_direction(animation_state, suffix)
	return suffix


func _play_direction(state: StringName, suffix: StringName) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var candidate := StringName("%s_%s" % [state, suffix])
	if animated_sprite.sprite_frames.has_animation(candidate):
		animated_sprite.play(candidate)
		return
	# Four-direction fallback for an eight-direction request.
	var fallback_suffix := _cardinal_fallback(suffix)
	var fallback := StringName("%s_%s" % [state, fallback_suffix])
	if animated_sprite.sprite_frames.has_animation(fallback):
		animated_sprite.play(fallback)


func _cardinal_fallback(direction: StringName) -> StringName:
	match direction:
		&"sw", &"se": return &"s"
		&"nw", &"ne": return &"n"
		_: return direction
