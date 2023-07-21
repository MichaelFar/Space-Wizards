extends Node
#To add new attack specs(for when an enemy has multiple attacks with different values),
#make a new node like this one and place it within the attack container.
#The name must be in the format 'attackname_attack_specs'
#DO NOT CHANGE THE '_attack_specs' portion of the name 
#update_specs may be called to change these values
#Values may be changed in the inspector


@export var damage: float = 100
@export var knockback_strength: float = 250
	
func update_specs(newDamage = 100.0, newKnockback = 250.0):
	damage = newDamage
	knockback_strength = newKnockback
		

#Holds values specific to one attack




