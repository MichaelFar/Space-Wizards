extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_enemy_id():
	return get_parent().get_parent().get_parent()#Vomiting in my mouth
