extends Node2D

@export var attack_resource_loader : ResourcePreloader
@export var attack_point = Marker2D

var selected_attack_index = SnailAttacks.BASIC

var attack_resource_list := []

enum SnailAttacks {
	BASIC,
	MULTISLASH
}

func _ready():
	attack_resource_list = attack_resource_loader.get_resource_list()
	
func orient_attack(target_vector = Vector2(0,0)):
	look_at(target_vector)
	scale.x = sign(target_vector.x) * 1.0
	var attack_instance = attack_resource_loader.get_resource(attack_resource_list[selected_attack_index])
	attack_instance = attack_instance.instantiate()
	call_deferred("add_child",attack_instance)
	attack_instance.position = attack_point.position
	attack_instance.attacker_id = get_parent()
