extends Area2D
@onready var animation_player = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func attack():
	animation_player.play("Sling Shot ")
