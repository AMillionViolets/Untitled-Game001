extends CharacterBody2D

@onready var main_character = %"Main Character"


func _physics_process(delta):
	var direction = global_position.direction_to(main_character.global_position)
	velocity = direction * 300.0
	move_and_slide()
