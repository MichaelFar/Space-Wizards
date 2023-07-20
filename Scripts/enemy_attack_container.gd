extends CharacterBody2D


var attackPlayer = null
var supplied_player_position = Vector2.ZERO

func _ready():
	
	attackPlayer = $AttackPlayer
	
func _physics_process(delta):
	
	if(attackPlayer.current_animation != ''):
		if(attackPlayer.current_animation_position == 0 && attackPlayer.current_animation_length != 0):
			self.look_at(supplied_player_position)
			
func play_attack():
	attackPlayer.play('enemy_attack_smear')
