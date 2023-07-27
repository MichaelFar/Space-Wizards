extends CharacterBody2D


var attackPlayer = null
var supplied_player_position = Vector2.ZERO
var attack_specs_objects = []
var currentDamage = 0
var currentKnockbackStrength = 0
var currentStatNode = ''
var smearChildren = []
@onready var enemy_id = get_parent()

func _ready():
	
	attackPlayer = $AttackPlayer
	get_all_attack_specs()
	set_new_attack_specs()
	for i in get_children():
		
		if '_smear' in  i.name:
			print("Appended " + i.name)
			smearChildren.append(i)
	
func _physics_process(delta):
	
	if(attackPlayer.current_animation != ''):
		if(attackPlayer.current_animation_position == 0 && attackPlayer.current_animation_length != 0):
			self.look_at(supplied_player_position)
			if(supplied_player_position.x < global_position.x):
				for i in smearChildren:
					i.flip_v = true
					i.set('offset', Vector2(0, 22))
			else:
				for i in smearChildren:
					i.flip_v = false
					i.set('offset', Vector2(0, 0))
			
func play_attack():
	attackPlayer.play('enemy_attack_smear')


func get_all_attack_specs():#Get attack spec scripts
	
	for i in get_children():
		if '_attack_specs' in i.name:
			print('Adding specs ' + i.name)
			attack_specs_objects.append(i)
		elif i is Sprite2D:
			i.get_child(0).get_child(0).set("disabled", true)
			
func set_new_attack_specs(objectName = '1'):#Given an object (weapon name string) get the stats
	
	for i in attack_specs_objects:
		if objectName in i.name:
			currentDamage = i.damage
			currentKnockbackStrength = i.knockback_strength
			currentStatNode = i
			break

func abort_animation():
	attackPlayer.stop()
	for i in smearChildren:
		i.visible = false
		
		for j in i.get_node("enemy_attack_hitbox").get_children():
			print("Hitbox " + j.name + " disabled")
			j.disabled = true
