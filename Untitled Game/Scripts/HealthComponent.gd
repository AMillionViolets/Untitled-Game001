extends Node2D
class_name HealthComponent1

@export var MAX_HEALTH := 10
var health : float 

func _ready():
	health=MAX_HEALTH
	
func damage(attack: Attack):
	health-=attack.attack_damage
	
	if health <= 0:
		get_parent().queue_free()

