extends Node2D

@export var attack_resource_loader : ResourcePreloader
@export var attack_point = Marker2D

var selected_attack_index = SnailAttacks.BASIC

var attack_resource_list := []

signal current_attack_delay

enum SnailAttacks {
	BASIC,
	MULTISLASH
}

func _ready():
	attack_resource_list = attack_resource_loader.get_resource_list()
	connect("current_attack_delay", get_parent().set_attack_delay)
func orient_attack(target_vector = Vector2(0,0)):
	look_at(target_vector)
	var attack_instance = attack_resource_loader.get_resource(attack_resource_list[selected_attack_index])
	attack_instance = attack_instance.instantiate()
	call_deferred("add_child",attack_instance)
	attack_instance.position = attack_point.position
	attack_instance.attacker_id = get_parent()
	
	current_attack_delay.emit(attack_instance.animation_length)
