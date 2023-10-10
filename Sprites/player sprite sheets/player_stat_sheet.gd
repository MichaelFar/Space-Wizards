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

var originalDamage = damage

var originalKnockback = knockback_strength

var originalPoiseDamage = poise_damage
signal player_stats

func update_specs(newDamage = damage, newKnockback = knockback_strength, newPoiseDamage = poise_damage):
	
	damage = newDamage
	knockback_strength = newKnockback
	poise_damage = newPoiseDamage

func restore_specs():
	
	damage = originalDamage
	knockback_strength = originalKnockback
	poise_damage = originalPoiseDamage
	
func _ready():
	post_initialize()
	
func post_initialize():
	set_equipped_weapon("broom")
	
func set_equipped_weapon(weapon = "broom"): #
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

func send_stats():#Called when the melee_attack animation plays 
	player_stats.emit(knockback_strength, damage, poise_damage, parry_poise_damage)
	print("Sent stats to enemy")
