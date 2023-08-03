extends Node

@export var damage = 100
@export var knockback_strength = 250
@export var max_health = 1000
@export var max_poise = 100
@export var poise_recovery = 3
@export var knockback_resistance = 0.0

signal pirate_grunt_stats
var current_attack = "attack1"
var attacks_array = ["attack1"] 
var next_attack = null
#A signal is emitted at the moment of attack to the player that will have: attack name, knockback strength, damage
#An array of dictionary keys is necessary for accessing independent attacks (does not follow a combo)
#The enemy may have multiple attacks, each attack's respective stats are in a dictionary
var attacks_dict = {}

	
func update_specs(newDamage = 200.0, newKnockback = 250.0):
	damage = newDamage
	knockback_strength = newKnockback
		

func _ready():
	post_initialize()
	
	
func post_initialize():
	
	set_attack("attack1")
	notify_property_list_changed()

func set_attack(attack = "attack1"):
	
	attacks_dict = {"attack1": 
						 {
						  "knockback": knockback_strength, 
						  "damage": damage,
						  "followup": null#If an attack is part of a combo, the next attack is a key within the current attacks_dict
						 }
						}
	knockback_strength = attacks_dict[attack]["knockback"]
	damage = attacks_dict[attack]["damage"]
	next_attack = attacks_dict[attack]["followup"]
	current_attack = attack
	#pirate_grunt_stats.emit(knockback_strength, damage)
#Holds values specific to one attack





