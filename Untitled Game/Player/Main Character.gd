extends CharacterBody2D


@export var SPEED = 200.0


@onready var sprite_2d = $Sprite2D
@onready var collision_shape_2d = $"Weapon Node/Weapon/CollisionShape2D"
@onready var weapon = $"Weapon Node/Weapon"
@onready var weapon_node = $"Weapon Node"
 
@export var inventory: Inventory




#very basic attack script will neeed to be updated to handle abilities and multiples kinds of attack
func _unhandled_input(event): 
		if event.is_action_pressed("Mouse1"):
			weapon.attack()




func _physics_process(_delta):
	# y axis movement 
	var directiony = Input.get_axis("up", "down")
	if directiony:
		velocity.y = directiony * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)

	# Get the input direction and handle the movement/deceleration.
	var directionx = Input.get_axis("left", "right")
	if directionx:
		velocity.x = directionx * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)


	move_and_slide()
	

	if directionx>0:
			sprite_2d.scale.x=-1
			weapon_node.scale.x=-1
	elif directionx<0:
			sprite_2d.scale.x=1
			weapon_node.scale.x=1
		
			




func _on_hitbox_component_area_entered(area):
	if area.has_method("collect_gold"):
		area.collect_gold(inventory)
		
	if area.has_method("collect"):
		area.collect(inventory)
	
