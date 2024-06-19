extends CharacterBody2D

@onready var sprite_2d = $Sprite2D

func _physics_process(_delta):
	move_and_slide()
	if velocity.x>0:
			sprite_2d.flip_h = false
	elif velocity.x<0:
			sprite_2d.flip_h = true
			
			
				
	

