extends CharacterBody2D


var attackPlayer = null
var supplied_player_position = Vector2.ZERO
var attack_specs_objects = []
var currentDamage = 0
var currentKnockbackStrength = 0
var currentStatNode = ''


func _ready():
	
	attackPlayer = $AttackPlayer
	get_all_attack_specs()
	set_new_attack_specs()
func _physics_process(delta):
	
	if(attackPlayer.current_animation != ''):
		if(attackPlayer.current_animation_position == 0 && attackPlayer.current_animation_length != 0):
			self.look_at(supplied_player_position)
			
func play_attack():
	attackPlayer.play('enemy_attack_smear')


func get_all_attack_specs():#Get attack spec scripts
	
	for i in get_children():
		if '_attack_specs' in i.name:
			print('Adding specs ' + i.name)
			attack_specs_objects.append(i)
			
func set_new_attack_specs(objectName = '1'):#Given an object (weapon name string) get the stats
	
	for i in attack_specs_objects:
		if objectName in i.name:
			currentDamage = i.damage
			currentKnockbackStrength = i.knockback_strength
			currentStatNode = i
			break
