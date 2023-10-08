extends CharacterBody2D

#Copy and paste the below variables into new spells


var spell_cooldown = 0
var cool_down_denominator = 0.5
var cooldown_begin = false
var destination = Vector2.ZERO
var global_destination = Vector2.ZERO
var originPoint = Vector2.ZERO
###############################

@export var spell_stat_sheet = Node2D
@export var electric_child_1 = Sprite2D
@export var electric_child_2 = Sprite2D
@export var electric_child_3 = Sprite2D
var target_distance = 20
var shouldHit = false
var max_speed = 900
var acceleration = 18000

var hit_enemy = null#ID of enemy hit
var hit_enemy_shader = null#Shader of hit enemy
var hit_frames = 0
var frame = 0
var effect_active = false

func _ready():
	
	post_initialize()

func post_initialize():
	#Need to send energy container to this node, parent is scene root
	global_position = originPoint 
	
func _physics_process(delta):
	frame +=1
	var frame_rate = 1/delta
	spell_cooldown = frame_rate / cool_down_denominator
	
	if(frame/1 == 1 || $AnimationPlayer.current_animation != 'hit'):
		
		$AnimationPlayer.play("travel")
		
	destination = global_destination - global_position
	destination = destination.normalized()
	
	if(is_instance_valid(hit_enemy)):
		if(hit_enemy.hit_with_broom):
			hit_enemy.update_poise_bar(-150.0)
			hit_enemy.update_healthbar(200)
			hit_enemy.material = hit_enemy.originalShader
			globals.player.stat_sheet.send_stats()
			queue_free()
	
	if(shouldHit):
	
		$AnimationPlayer.play('hit')
		rotation = 0
		
		if(is_instance_valid(hit_enemy)):
			velocity = Vector2.ZERO
			global_position = hit_enemy.global_position
			hit_frames += 1
			
			if(hit_frames / frame_rate >= 30):
				
				hit_enemy.material = hit_enemy.originalShader
				print("Set enemy shader back to default")
				queue_free()
		else:
			queue_free()
	else:
		
		look_at(global_destination)
		velocity = velocity.move_toward(destination * max_speed, delta * acceleration)
		if(global_destination.distance_to(global_position) < target_distance):
			queue_free()
	
	move_and_slide()
	
func cost():
	return true

func _on_spell_hit_box_body_entered(body):
	if(body is TileMap && !is_instance_valid(hit_enemy)):
		queue_free()

func _on_spell_hit_box_area_entered(area):
	var areaParent = area.get_parent()
	if(area.name == 'Hurtbox'):
		if(areaParent.has_method('node_type')):
			if (areaParent.node_type() != 'player'):
				shouldHit = true
				hit_enemy = areaParent
				if(hit_enemy.material == material):
					
					shouldHit = false
					
				hit_enemy_shader = hit_enemy.originalShader
				hit_enemy.material = material
				
				





