extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0



@onready var sprite_2d = $Sprite2D
@onready var sprite_2d2 = $"Weapon Node/Weapon/Sprite2D"
@onready var animation_player = $"Weapon Node/Weapon/AnimationPlayer"
@onready var collision_shape_2d = $"Weapon Node/Weapon/CollisionShape2D"
@onready var weapon = $"Weapon Node/Weapon"
@onready var weapon_node = $"Weapon Node"


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _unhandled_input(event): 
		if event.is_action_pressed("Mouse1"):
			weapon.attack()

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

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
		
			
