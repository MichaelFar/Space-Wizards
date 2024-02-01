extends Area2D
var attacker_id = null

var animation_length := 0.0
@export var AttackPlayer : AnimationPlayer

func _ready():

	AttackPlayer.play("attack")
	animation_length = AttackPlayer.get_animation(AttackPlayer.current_animation).length
	print("Animation length is " +str(animation_length))
