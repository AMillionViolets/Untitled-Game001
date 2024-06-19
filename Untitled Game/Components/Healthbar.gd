extends ProgressBar
class_name HealthComponent
@onready var damagebar = $Damagebar
@onready var timer = $Timer

@export var MAX_HEALTH := 10 
var health : float 

#sets the starting vlaues for the health and damage bars 
func _ready():
	health=MAX_HEALTH
	max_value = MAX_HEALTH
	value = health
	damagebar.max_value = MAX_HEALTH
	damagebar.value = health
	
	
	#the only way entities should be taking damage is through attack functions
func damage(attack: Attack):
	health-=attack.attack_damage
	value = health
	timer.start()
	
	if health <= 0:
		get_parent().queue_free()





func _on_timer_timeout():
	damagebar.value = health
