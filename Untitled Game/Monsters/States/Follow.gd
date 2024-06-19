extends state
class_name follow

var player : CharacterBody2D

@export var enemy: CharacterBody2D
@export var move_speed:= 10
@export var idleat:= 250
func enter():
	player = get_tree().get_first_node_in_group("Player")
	
func physics_update(_delta:float):
	var direction = player.global_position - enemy.global_position
	
	if direction.length() > 25:
		enemy.velocity = direction.normalized() * move_speed
		
	if direction.length() > idleat:
		transitoned.emit(self, "idle")
	
