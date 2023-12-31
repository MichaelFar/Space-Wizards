extends CharacterBody2D


@export var max_speed = 900
@export var acceleration = 1400
@export var global_destination = Vector2.ZERO
@export var target_distance = 20 #As the speed of the projectile increases, so too will this need to increase

var spell_cooldown = 20
@export var cool_down_denominator = 1 #Divided by frame rate to determine cooldown length. 2 = half second, 3 = 1/3rd second, etc
var cooldown_begin = true

@onready var spell_stat_sheet = $spell_stat_sheet
@onready var icon_reference = $IconReference
@export var zap_particle : GPUParticles2D
var originPoint = Vector2.ZERO
var currentGlobalVector = Vector2.ZERO
var vectorDifference = Vector2.ZERO
var previousGlobalVector = Vector2.ZERO
var destination = Vector2.ZERO#In global reference
var frame = 0
var hit_enemy = null
#Frame coords for the spell icon
var hframes = 16
var vframes = 28
var current_frame = 8

@export var shouldHit = false
# Called when the node enters the scene tree for the first time.

func _enter_tree():
	pass
	#cooldown_begin = true
func _ready():
	
	post_initialize()

func post_initialize():
	#Need to send energy container to this node, parent is scene root
	global_position = originPoint 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	frame +=1
	var frame_rate = 1/delta
	spell_cooldown = frame_rate / cool_down_denominator
	
	if(frame/1 == 1 || $AnimationPlayer.current_animation != 'hit'):
		
		$AnimationPlayer.play("travel")
		
	destination = transform.x
	
	if(global_position.distance_to(global_destination) < target_distance || shouldHit):
	
		$AnimationPlayer.play('hit')
		rotation = 0
		
		if(!shouldHit):
			zap_particle.reparent(globals.currentLevel)
			zap_particle.particle_timer_on = true
			global_position = global_destination
		elif(hit_enemy != null):
			#zap_particle.process_material.emission_sphere_radius = hit_enemy.body_sprite.region_rect.size.x
			zap_particle.reparent(hit_enemy)
			zap_particle.particle_timer_on = true
			global_position = hit_enemy.global_position - hit_enemy.body_sprite.offset
			
		#shouldHit = false
	elif($AnimationPlayer.current_animation != 'hit'):
		
		look_at(global_destination)
		velocity = destination * max_speed
		move_and_slide()
	
func _on_spell_hit_box_body_entered(body):
	if(body is TileMap):
		shouldHit = true

func _on_spell_hit_box_area_entered(area):
	var areaParent = area.get_parent()
	if(area.name == 'Hurtbox'):
		if(areaParent.has_method('node_type')):
			if (areaParent.node_type() != 'player'):
				shouldHit = true
				hit_enemy = areaParent
	
func cost():#This is used in spell_container to tell if the player has enough energy to cast the spell
	#All spells must have this function, regardless of cost. If the cost is nothing, return true
	var paid = EnergyPointContainer.lose_energy(1)
	print("paid is " + str(paid))
	if(paid):
		
		print("Player able to pay for " + self.name)
	return paid 


	
