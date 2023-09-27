extends Node2D

@export var heal_amount = -150#Negative values heal

@onready var animationPlayer = $AnimationPlayer
var global_destination = Vector2.ZERO
var originPoint = Vector2.ZERO
var cooldown_begin = false
# Called when the node enters the scene tree for the first time.
func _ready():
	animationPlayer.play("heal_effect")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	global_position = globals.player.global_position
	
func cost():

	var paid = EnergyPointContainer.lose_energy(2)
	if(paid):
		print("Player able to pay for " + self.name)
	else:
		print("Player un-able to pay for " + self.name)
	return paid 

func heal():
	globals.player.update_healthbar(heal_amount)
