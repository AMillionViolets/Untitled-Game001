extends Area2D

var SPEED
var RANGE


var traveled_distance = 0
func _physics_process(delta):


	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * SPEED * delta
		
	traveled_distance += SPEED * delta
	if traveled_distance > RANGE:
		queue_free()
		
		
var attack_damage := 0



#Coliding with enemies 
func _on_area_entered(area: Area2D):
		queue_free()
		if area.has_method("damage"):
				var hitbox : HitboxComponent = area
				var attack = Attack.new()
				attack.attack_damage = attack_damage
				hitbox.damage(attack)



#handles tileset base collision 
func _on_body_entered(_body):
	queue_free()
