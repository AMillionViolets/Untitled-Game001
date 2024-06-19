extends Node2D
@export var projectile: PackedScene
@export var Attack_damage :=10
@export var AttackRange := 100
@export var projectileSpeed := 1000
@export var projectileRange := 1000
@export var rateofFire := .5


@onready var shooting_point = self
@onready var fire_rate_control = $FireRateControl


var player: CharacterBody2D 



func _physics_process(_delta):
	look_at(player.global_position) 


func _ready():
	fire_rate_control.set_wait_time(rateofFire)
	player = get_tree().get_first_node_in_group("Player")
	

func attack():
	var disttotarget = abs(player.global_position.length() - self.global_position.length())
	if disttotarget < AttackRange:
		var new_bullet = projectile.instantiate()
		new_bullet.attack_damage=Attack_damage
		new_bullet.SPEED = projectileSpeed
		new_bullet.RANGE = projectileRange
		new_bullet.global_position = shooting_point.global_position
		new_bullet.global_rotation = shooting_point.global_rotation
		shooting_point.add_child(new_bullet)
	else:
		pass


func _on_timer_timeout():
	attack()
