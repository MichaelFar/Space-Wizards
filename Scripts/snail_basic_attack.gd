extends CharacterBody2D

@export var AttackPlayer : AnimationPlayer
func _ready():
	AttackPlayer.play("attack")
