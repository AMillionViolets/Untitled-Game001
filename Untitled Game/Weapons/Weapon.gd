extends Area2D
@onready var shooting_point = $"Shooting Point"
@onready var animation_player = $AnimationPlayer



func attack():
	const ROCK = preload("res://Weapons/rock(bullet).tscn")
	animation_player.play("Sling Shot ")
	var new_bullet = ROCK.instantiate()
	new_bullet.global_position = shooting_point.global_position
	new_bullet.global_rotation = shooting_point.global_rotation
	shooting_point.add_child(new_bullet)

