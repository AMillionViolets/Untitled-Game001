extends Area2D

@export var projectile: PackedScene
@export var Attack_damage :=10
@export var projectileSpeed := 1000
@export var projectileRange := 1000


@onready var shooting_point = $"Shooting Point"
@onready var animation_player = $AnimationPlayer



func attack():
	var ROCK = projectile
	animation_player.play("Sling Shot ")
	var new_bullet = ROCK.instantiate()
	new_bullet.attack_damage=Attack_damage
	new_bullet.SPEED = projectileSpeed
	new_bullet.RANGE = projectileRange
	new_bullet.global_position = shooting_point.global_position
	new_bullet.global_rotation = shooting_point.global_rotation
	shooting_point.add_child(new_bullet)

