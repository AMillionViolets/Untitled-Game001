extends state
class_name enemystate

var player: = CharacterBody2D

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	
