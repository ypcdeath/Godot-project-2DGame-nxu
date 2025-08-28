class_name Stats
extends Node

signal health_changed
signal energy_changed

@export var max_health: int = 5
@export var max_energy: float = 10
@export var energy_regen: float = 0.8

@onready var health: int = max_health:
	set(v):
		v = clampi(v,0,max_health)
		if health == v:
			return
		else: 
			health = v
			health_changed.emit()
			
@onready var energy: float = max_energy:
	set(v):
		v = clampf(v,0,max_energy)
		if energy == v:
			return
		else: 
			energy = v
			energy_changed.emit()
			
func _process(delta: float) -> void:
	energy += energy_regen * delta
	
	
func to_dict() -> Dictionary:
	return {
		max_health = max_health,
		max_energy = max_energy,
		health = health,
	}
	
func from_dict(dict: Dictionary) -> void:
	max_health = dict.max_health
	max_energy = dict.max_energy
	health = dict.health
