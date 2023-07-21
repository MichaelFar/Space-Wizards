extends Node

@export var damage: float = 200
@export var knockback_strength: float = 250
	
func update_specs(newDamage = 200.0, newKnockback = 250.0):
	damage = newDamage
	knockback_strength = newKnockback
		

#Holds values specific to one attack




