extends CharacterBody2D


@export var max_speed = 300
@export var acceleration = 500
@export var global_destination = Vector2.ZERO

@onready var spell_stat_sheet = $spell_stat_sheet
var originPoint = Vector2.ZERO
var currentGlobalVector = Vector2.ZERO
var vectorDifference = Vector2.ZERO
var previousGlobalVector = Vector2.ZERO
var destination = Vector2.ZERO#In global reference
var frame = 0
var EnergyPointContainer = null
@export var shouldHit = false
# Called when the node enters the scene tree for the first time.

func _ready():
	
	post_initialize()

func post_initialize():
	#Need to send energy container to this node, parent is scene root
	global_position = originPoint 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	frame +=1
	
	if(frame/1 == 1 || $AnimationPlayer.current_animation != 'hit'):
		
		$AnimationPlayer.play("travel")
	
	destination = global_destination - global_position
	
	if(global_position.distance_to(destination + global_position) < 5 || shouldHit):
	
		$AnimationPlayer.play('hit')
		rotation = 0
		if(!shouldHit):
			global_position = global_destination# - vectorDifference
		shouldHit = false
	elif($AnimationPlayer.current_animation != 'hit'):
		
		look_at(global_destination)
		position = position.move_toward(destination * max_speed, delta * acceleration)# - vectorDifference
	

func _on_spell_hit_box_body_entered(body):
	if(body.has_method('node_type')):
		if !(body.node_type() == 'player'):
			shouldHit = true
	else:
		shouldHit = true
	print(str(body))
		
