extends Area2D
var attack_damage := 10

func _on_hitbox_area_entered(area):
		if area.has_method("damage"):
				var hitbox : HitboxComponent = area
				var attack = Attack.new()
				attack.attack_damage = attack_damage
				hitbox.damage(attack)
