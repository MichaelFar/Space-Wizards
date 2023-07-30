extends Node

@export var damage: float = 100
@export var knockback_strength: float = 250
@export var max_health: float = 1000
@export var acceleration = 450 #Multiplied by delta
@export var friction = 250 #Multiplied by delta
@export var max_speed = 150 # NOT multiplied by delta
@export var attack_movement = 400 #Multiplied by delta


signal player_stats


	
func update_specs(newDamage = 200.0, newKnockback = 250.0):
	damage = newDamage
	knockback_strength = newKnockback
		

func _ready():
	post_initialize()
	
func post_initialize():
	set_equipped_weapon("broom")
	

func set_equipped_weapon(weapon = "broom"):
	var weapons_dict = {"broom": 
							 {
							  "knockback": knockback_strength, 
							  "damage": damage
							 }
							}
	knockback_strength = weapons_dict[weapon]["knockback"]
	damage = weapons_dict[weapon]["damage"]
	player_stats.emit(knockback_strength, damage)
#Holds values specific to one attack




