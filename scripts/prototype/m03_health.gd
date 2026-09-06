extends Node

signal health_changed(current_health: float, max_health: float)
signal damaged(amount: float, current_health: float)
signal died

@export var max_health := 100.0
var current_health := 100.0


func _ready() -> void:
	current_health = max_health


func configure(value: float) -> void:
	max_health = maxf(value, 1.0)
	current_health = max_health
	health_changed.emit(current_health, max_health)


func damage(amount: float) -> float:
	if amount <= 0.0 or current_health <= 0.0:
		return 0.0
	var applied := minf(amount, current_health)
	current_health -= applied
	damaged.emit(applied, current_health)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		died.emit()
	return applied


func heal(amount: float) -> float:
	if amount <= 0.0 or current_health <= 0.0:
		return 0.0
	var before := current_health
	current_health = minf(current_health + amount, max_health)
	if not is_equal_approx(before, current_health):
		health_changed.emit(current_health, max_health)
	return current_health - before


func restore_full() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func is_dead() -> bool:
	return current_health <= 0.0
