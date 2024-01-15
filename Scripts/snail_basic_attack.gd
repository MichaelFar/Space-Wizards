extends CharacterBody2D
var attacker_id = null
@export var AttackPlayer : AnimationPlayer
func _ready():
	AttackPlayer.play("attack")
