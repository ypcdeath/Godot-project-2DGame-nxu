extends HBoxContainer

@export var stats: Stats

@onready var health_bar: TextureProgressBar = $VBoxContainer/HealthBar
@onready var eased_health_bar: TextureProgressBar = $VBoxContainer/HealthBar/EasedHealthBar
@onready var energy_bar: TextureProgressBar = $VBoxContainer/EnergyBar

func _ready() -> void:
	if not stats:
		stats = Game.player_stats
	
	stats.health_changed.connect(update_health)
	update_health(true)

	stats.energy_changed.connect(update_energy)
	update_energy()
	
func update_health(skip_anim := false) -> void:
	var pencentage := stats.health / float(stats.max_health) 
	health_bar.value = pencentage
	
	if skip_anim:
		eased_health_bar.value = pencentage
	else:
		create_tween().tween_property(eased_health_bar,"value",pencentage,0.3)
	
func update_energy() -> void:
	var pencentage := stats.energy / stats.max_energy 
	energy_bar.value = pencentage
