extends state
class_name idle 

var player : CharacterBody2D
@export var enemy: CharacterBody2D
@export var move_speed:= 10
@export var followat := 500

var move_direction: Vector2
var wandertime: float 

func wander_randomize():
	move_direction = Vector2(randf_range(-1,1),randf_range(-1,1)).normalized()
	wandertime = randf_range(1,3)

func enter():
	player = get_tree().get_first_node_in_group("Player")
	wander_randomize()
	

func update(delta: float):
	if wandertime > 0:
		wandertime -= delta
	else:
		wander_randomize()

func physics_update(_delta: float): 
	var disttoplayer = abs(player.global_position.length() - enemy.global_position.length())
	if enemy:
		enemy.velocity = move_direction * move_speed
		
	if disttoplayer < followat:
		transitoned.emit(self,"follow")
	
