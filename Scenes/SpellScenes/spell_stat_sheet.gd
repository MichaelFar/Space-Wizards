extends Node2D
#Unlike the player and enemy stat sheet, this one is only concerning the zap_spell
#This pattern will continue for all spells added

@export var knockback_strength = 400
@export var damage = 200
@export var poise_damage = 200

var parent = null
func _ready():
	post_initialize()


func post_initialize():
	parent = get_parent()

func get_stats():
	return [knockback_strength, damage, poise_damage]



