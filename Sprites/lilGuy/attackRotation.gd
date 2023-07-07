extends CharacterBody2D


func _ready():
	pass


func _physics_process(delta):
	
	self.look_at(get_global_mouse_position())
