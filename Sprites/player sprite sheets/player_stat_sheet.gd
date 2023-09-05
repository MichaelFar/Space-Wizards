extends Node

@export var damage: float = 100
@export var knockback_strength: float = 250
@export var max_health: float = 1000
@export var acceleration = 450 #Multiplied by delta
@export var friction = 250 #Multiplied by delta
@export var max_speed = 150 # NOT multiplied by delta
@export var attack_movement = 400 #Multiplied by delta
@export var poise_damage = -10.0
@export var parry_poise_damage = -100.0
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
							  "damage": damage,
							  "poise_damage": poise_damage
							 }
							}
	knockback_strength = weapons_dict[weapon]["knockback"]
	damage = weapons_dict[weapon]["damage"]
	#player_stats.emit(knockback_strength, damage)
#Holds values specific to one attack
func set_equipped_spell(spell = 'zap'):
	var spells_dict = {"zap": 
							 {
							  "knockback": knockback_strength, 
							  "damage": damage,
							  "poise_damage": poise_damage
							 }
							}
	return spells_dict[spell]

func spell_behavior_router():
	#Certain spells are attacks while others are not, meaning spell behavior has to be selected for
	#I imagine that spells cannot fit into a 1 size fits all format like attacks theoretically can be, so we need a driver for spell behavior
	pass
func _process(_delta):
	player_stats.emit(knockback_strength, damage, poise_damage, parry_poise_damage)



