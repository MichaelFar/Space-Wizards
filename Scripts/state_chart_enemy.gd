extends CharacterBody2D

#visual changers
@export var body_sprite : Sprite2D
@export var StateChart : StateChart
@export var emoteContainer : Node2D
@export var animationPlayer : AnimationPlayer
#timer references
@export var aggrotimer : Timer
@export var idletimer : Timer
@export var lostplayertimer : Timer
@export var spritefliptimer : Timer
@export var attacktimer : Timer
#navigation
@export var navAgent : NavigationAgent2D
@export var rayCastContainer : CharacterBody2D
#attack nodes
@export var AttackContainer : Node2D
@export var attackArea : Area2D
#basic stats
@export var sightArea : Area2D
@export var max_speed = 200.0
@export var acceleration = 90.0
var aggro_target = 3.0# time in seconds that the enemy will take to become aggro
var player = null
var current_chosen_point = Vector2.ZERO
var current_travel_points = []
var sight_radius = 0.0
var times_entered_wander = 0
var in_range = false
func _ready():
	sight_radius = get_sight_radius()
	player = globals.player
	
	
func get_sight_radius():
	return sightArea.get_children()[0].shape.radius
	
func _on_area_2d_area_entered(area):
	
	if(area.get_parent() == player):
		current_chosen_point = globals.player.global_position
		StateChart.send_event("player_entered")
		spritefliptimer.stop()
		aggrotimer.start()
		
		
func _on_area_2d_area_exited(area):
	
	if(area.get_parent() == player):
		
		StateChart.send_event("player_exited")
		current_chosen_point = globals.player.global_position
		spritefliptimer.stop()
		
		
func _on_observing_state_physics_processing(delta):
	
	body_sprite.scale.x = 1.0 * sign(player.global_position.x - global_position.x)#Look at player on x-axis

func _on_timer_timeout():#aggrotimer timeout
	
	StateChart.send_event("is_aggro")
	
func _on_aggro_state_entered():
	animationPlayer.play("walk")
	emoteContainer.play_emote("exclaim")
	#StateChart.send_event("player_entered")
	

func _on_wander_state_state_physics_processing(delta):#Wander state
	var target_distance = 10
	move_to_target()
	if (global_position.distance_to(current_chosen_point) <= target_distance):
		StateChart.send_event("back_to_rest")
	else:
		
		move_and_slide()

func get_travel_points():
	var travel_points = []
	var valid_points = []
	
	valid_points = get_parent().validpoints
	
	for i in valid_points:
		if i.distance_to((floor(global_position))) <= floor(sight_radius):
			travel_points.append(i)
			#print("Added " + str(i) + " to travel points")
			
	#parent.get_dimensions(travel_points)
	return travel_points


func _on_wander_state_state_entered():#Wander State Entered
	times_entered_wander += 1
	if(times_entered_wander == 1):
		current_travel_points = get_travel_points()
	
	animationPlayer.play("walk")
	emoteContainer.play_emote("")
	current_chosen_point = choose_point()
	
func choose_point():
	
	var randomPoint = RandomNumberGenerator.new()
	var chosen_point = Vector2.ZERO
	var travel_points = current_travel_points
	var valid_points = get_parent().validpoints
	chosen_point = travel_points[randomPoint.randi_range(0, travel_points.size() - 1)]
	
	if((chosen_point) not in valid_points):
		
		travel_points = get_travel_points()
		chosen_point = travel_points[randomPoint.randi_range(0, travel_points.size() - 1)]
		
	return chosen_point

func _on_idle_state_state_entered():
	idletimer.start()
	aggrotimer.stop()
	animationPlayer.play("idle")
	emoteContainer.play_emote("")
	

func _on_idletimer_timeout():
	StateChart.send_event("idled_enough")

func move_to_target():
	var direction = current_chosen_point
	
	navAgent.target_position = direction
	rayCastContainer.supplied_direction = (navAgent.get_next_path_position()  - floor(global_position)).normalized()
	body_sprite.scale.x = 1.0 * sign(current_chosen_point.x - global_position.x)
	velocity = velocity.move_toward(rayCastContainer.suggestedVector * max_speed, acceleration)


func _on_observing_state_state_entered():
	animationPlayer.play("idle")
	
	emoteContainer.play_emote("question")
	
	spritefliptimer.stop()
	
	lostplayertimer.stop()
	

func _on_aggro_state_physics_processing(delta):
	
	var target_distance = 10
	
	current_chosen_point = globals.player.global_position
	
	move_to_target()
	
	move_and_slide()

func _on_lostplayertimer_timeout():
	StateChart.send_event("back_to_rest")
	spritefliptimer.stop()


func _on_lost_player_state_state_entered():
	animationPlayer.play("idle")
	emoteContainer.play_emote("question")
	spritefliptimer.start()
	lostplayertimer.start()
	

func _on_spritefliptimer_timeout():
	
	body_sprite.scale.x = body_sprite.scale.x * -1.0
	

func _on_aggro_state_exited():
	StateChart.send_event("lost_player")

func _on_lost_player_state_state_physics_processing(delta):
	if(spritefliptimer.is_stopped() && animationPlayer.current_animation != "walk"):
		spritefliptimer.start()


func _on_attack_radius_area_entered(area):
	print("Area entering attack radius " + area.name)
	StateChart.send_event("in_attack_range")
	#attackArea.get_children()[0].disabled = true


func _on_interim_state_state_entered():
	StateChart.send_event("is_aggro")


func _on_attack_state_state_entered():
	animationPlayer.play("attack_1") # This can be changed to dynamically choose the appropriate attack
	AttackContainer.orient_attack(globals.player.global_position)
	in_range = true#HERE!!!!


func set_attack_delay(delay):
	print("Delay sent is " + str(delay))
	attacktimer.wait_time = delay
	attacktimer.start()
	

func _on_attacktimer_timeout():#Occurs when the enemy is done with their attack
	if (in_range):
		StateChart.send_event("in_attack_range")



func _on_attack_radius_area_exited(area):
	in_range = false
