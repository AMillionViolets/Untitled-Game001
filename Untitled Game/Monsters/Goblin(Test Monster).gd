extends CharacterBody2D

@onready var main_character = %"Main Character"
@export var MAX_HEALTH := 10
var health : float 

func _ready():
	health=MAX_HEALTH

func _physics_process(delta):
	var direction = global_position.direction_to(main_character.global_position)
	velocity = direction * 1500.0 *delta
	move_and_slide()

func damage(attack: Attack):
	print("damage taaken")
	health-=attack.attack_damage
	
	if health <= 0:
		get_parent().queue_free()
