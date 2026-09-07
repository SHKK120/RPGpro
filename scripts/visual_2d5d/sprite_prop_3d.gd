@tool
class_name SpriteProp3D
extends Node3D

@export var asset_config: AssetConfig2D5D
@export var tint := Color.WHITE

@onready var visual_root := get_node_or_null("VisualRoot") as Node3D
@onready var sprite := get_node_or_null("VisualRoot/Sprite3D") as Sprite3D
@onready var collision_proxy := get_node_or_null("CollisionProxy") as CollisionProxy3D


func _ready() -> void:
	apply_config()


func apply_config() -> void:
	if asset_config == null or sprite == null or visual_root == null:
		return
	sprite.texture = asset_config.texture
	sprite.pixel_size = asset_config.pixel_size
	sprite.modulate = tint
	sprite.shaded = false
	sprite.billboard = _billboard_mode(asset_config.facing_mode)
	var size := asset_config.visual_world_size()
	visual_root.position = Vector3(
		(0.5 - asset_config.ground_pivot.x) * size.x,
		asset_config.ground_pivot.y * size.y,
		0.0
	)
	sprite.position.y = -size.y * 0.5
	_update_shadow(size)
	if collision_proxy != null:
		collision_proxy.apply_config(asset_config)


func _update_shadow(size: Vector2) -> void:
	var shadow := get_node_or_null("GroundShadow") as MeshInstance3D
	if shadow == null:
		shadow = MeshInstance3D.new()
		shadow.name = "GroundShadow"
		add_child(shadow)
	shadow.visible = asset_config.optional_shadow
	if not shadow.visible:
		return
	var plane := PlaneMesh.new()
	plane.size = Vector2(maxf(0.45, size.x * 0.62), maxf(0.28, size.x * 0.22))
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.025, 0.04, 0.035, 0.42)
	material.albedo_texture = load("res://assets/art/green_coast_2d5d_v01/sprites/soft_shadow.svg")
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	plane.material = material
	shadow.mesh = plane
	shadow.position = Vector3.ZERO + Vector3.UP * 0.012


func _billboard_mode(mode: AssetConfig2D5D.FacingMode) -> BaseMaterial3D.BillboardMode:
	match mode:
		AssetConfig2D5D.FacingMode.BILLBOARD:
			return BaseMaterial3D.BILLBOARD_ENABLED
		AssetConfig2D5D.FacingMode.Y_BILLBOARD:
			return BaseMaterial3D.BILLBOARD_FIXED_Y
		_:
			return BaseMaterial3D.BILLBOARD_DISABLED
