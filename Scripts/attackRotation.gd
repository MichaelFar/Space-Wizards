extends CharacterBody2D

var attackPlayer = null
var playerSpriteTree = null
var animationState = null
var playerNode = null
var attack_specs_objects = []
var currentDamage = 0
var currentKnockbackStrength = 0
var currentStatNode = ''

func _ready():
	
	playerNode = get_parent()
	attackPlayer = $AttackSpritePlayer 
	playerSpriteTree = $"../PlayerSpriteAnimTree"
	animationState = playerSpriteTree.get("parameters/playback")
	get_all_attack_specs()
	set_new_attack_specs('broom')
	
func _physics_process(delta):
	
	if(attackPlayer.current_animation != ''):
		if(attackPlayer.current_animation_position == 0 && attackPlayer.current_animation_length != 0):
			self.look_at(get_global_mouse_position())
			playerSpriteTree.set("parameters/IdleBlend/blend_position", playerNode.get_local_mouse_position())
			animationState.travel("IdleBlend")
	print('Damage is ' + str(currentDamage))
	
func get_all_attack_specs():#Get attack spec scripts
	
	for i in get_children():
		if '_attack_specs' in i.name:
			print('Adding specs ' + i.name)
			attack_specs_objects.append(i)
			
func set_new_attack_specs(objectName = 'broom'):#Given an object (weapon name string) get the stats
	
	for i in attack_specs_objects:
		if objectName in i.name:
			currentDamage = i.damage
			currentKnockbackStrength = i.knockback_strength
			currentStatNode = i
			break
	
