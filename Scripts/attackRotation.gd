extends CharacterBody2D

var attackPlayer = null
var playerSpriteTree = null
var animationState = null
var playerNode = null
var attack_specs_objects = []
var currentDamage = 0
var currentKnockbackStrength = 0
var currentStatNode = ''
var smearChildren = []
var parryDirection = Vector2.ZERO

var soundChildren = []

func _ready():
	
	playerNode = get_parent()
	attackPlayer = $AttackSpritePlayer 
	playerSpriteTree = $"../PlayerSpriteAnimTree"
	animationState = playerSpriteTree.get("parameters/playback")
	
	get_all_attack_specs()
	set_new_attack_specs('broom')
	get_sound_children()
	for i in get_children():
		
		if '_smear' in i.name:
			
			print("Added " + i.name + " to smearChildren")
			smearChildren.append(i)
	
func _physics_process(delta):
	
	if(attackPlayer.current_animation != ''):
		
		if(attackPlayer.current_animation_position == 0 && attackPlayer.current_animation_length != 0):
			
			self.look_at(get_global_mouse_position())
			if(parryDirection != Vector2.ZERO):
				self.look_at(parryDirection)
			playerSpriteTree.set("parameters/IdleBlend/blend_position", playerNode.get_local_mouse_position())
			animationState.travel("IdleBlend")
	
	
func get_sound_children():
	
	soundChildren = []
	
	for i in get_children():
		
		if i is AudioStreamPlayer:
			print("Appended: " + i.name)
			soundChildren.append(i)
			
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
	
func abort_animation():
	
	attackPlayer.stop()
	print("Number of smear children is " + str(smearChildren.size()))
	
	for i in smearChildren:
		i.visible = false
		print("Current smear child is " + i.name)
		if(i.get_children()):
			for j in i.get_node("AttackHitBox").get_children():
				print("Hitbox " + j.name + " disabled")
				j.disabled = true
			
func play_hit():
	#soundChildren[0].seek(soundChildren[0].stream.get_length())
	print("sound: " + soundChildren[0].name + " will be stopped" )
	soundChildren[0].stop()
	soundChildren[0].get_node('broom_hit_snd').play()

func zero_parry_direction():
	parryDirection = Vector2.ZERO
