extends CharacterBody2D

#Copy and paste the below variables into new spells


var spell_cooldown = 0
var cool_down_denominator = 0.5
var cooldown_begin = false
var destination = Vector2.ZERO
var global_destination = Vector2.ZERO
var originPoint = Vector2.ZERO
###############################

@export var animationPlayer : AnimationPlayer
var frame = 0

func _ready():
	global_position = globals.player.global_position
	
	
func _physics_process(delta):
	frame += 1
	if(frame == 1):
		animationPlayer.play("gust")
	
	
func cost():
	return true
