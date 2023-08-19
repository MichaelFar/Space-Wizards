extends Node2D

var raycastChildren = []
var debug = false

var suggestedVector = Vector2.ZERO
@onready var supplied_direction = get_parent().playerPreviousPosition
# Called when the node enters the scene tree for the first time.
var interest_array = []
var danger_array = []
var relevant_raycasts = []
var final_interest = []
var frame = 0
var frameRate = 0
func _ready():
	raycastChildren = set_raycast_children()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#look_at(supplied_direction)
	frameRate = get_parent().frameRate
	
	if frame % 2 == 0:	
		set_relevant_directions()
		set_interest()
		set_danger()
	suggestedVector = get_suggested_vector()
	debug = false
	#Uncomment for debugging raycasts
#	if(Input.is_action_just_pressed('relevant_raycasts')):
#		debug_raycasts()
	relevant_raycasts = []
	frame +=1
	
func set_raycast_children():
	var raycast_children = []
	for i in get_children():
		if 'RayTarget' in i.name:
			raycast_children.append(i)
			interest_array.append(0.0)
			danger_array.append(0.0)
			
			
	return raycast_children

func set_supplied_direction(newDirection):
	supplied_direction = newDirection

func get_suggested_vector():
	var suggested_vector = Vector2.ZERO
	
	var index = 0
	final_interest.resize(interest_array.size())
	for i in interest_array:
		
		final_interest[index] = clampf(interest_array[index] - danger_array[index], -1.0, 1.0)
		if debug:
			print("final_interest has added " + str(final_interest[index]) + " to " + raycastChildren[index].name)
		index += 1
	index = 0
	for i in interest_array:
		
		suggested_vector += (raycastChildren[index].position) * final_interest[index]
		index += 1
	if debug:
		print("supplied_direction is " + str(supplied_direction) + " and suggested_vector is " + str(suggested_vector.normalized()))
		for i in final_interest:
			print("Ray " + raycastChildren[final_interest.find(i)].name + " has interest " + str(i))
	return suggested_vector.normalized()

func set_danger():# Sets danger based on if the raycasts are colliding or not
	# More complex behavior can be had by making this function have more conditions and having the danger value be more values
	var space_state = get_world_2d().direct_space_state
	
	var collidingVectorsIndexes = []
	
	for i in raycastChildren:
		
		var distance = position.distance_to(i.position)
		var query = PhysicsRayQueryParameters2D.create(global_position, i.global_position)
		#query.exclude.append(get_parent().get_rid())
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.collision_mask = 4

		#print("Collision mask of the raycast is " + str(query.collision_mask))
		var result = space_state.intersect_ray(query)
		#print("Result is " + str(result))
		if(result):
			collidingVectorsIndexes.append(raycastChildren.find(i))
			
			var d = position.normalized().dot(i.global_position)
			danger_array[raycastChildren.find(i)] = ((position.distance_to(i.position)) / (distance)) #Danger set to relative distance to collider (usually less than 1.0)
			#danger_array[raycastChildren.find(i)] = 1.0 #All collisions set to danger 1.0 (max danger)
			if(debug):
				print((str(position.distance_to(result.collider.position)) + " is the distance between parent and target"))
				print(raycastChildren[raycastChildren.find(i)].name + " now has danger value " + str(danger_array[raycastChildren.find(i)]))
		else:
			danger_array[raycastChildren.find(i)] = 0.0
			
	return collidingVectorsIndexes


func set_relevant_directions():
	
	for i in raycastChildren:
		
		if absf(rad_to_deg((i.position.normalized()).angle_to(supplied_direction))) <= 90.0:
			relevant_raycasts.append(i)
		#print(str(rad_to_deg(i.target_position.angle_to(supplied_direction))))
				


func set_interest():
	# Set interest in each slot based on world direction
	var index = 0
	for i in interest_array:
		var d = raycastChildren[index].position.normalized().dot(supplied_direction)
		interest_array[index] = maxf(0.0, d)
		if debug:
			print("Set the interest of " + raycastChildren[index].name + " to " + str(interest_array[index]))
		
		index += 1

func debug_raycasts():
	
	var index = 0
	print("I am " + str(get_parent().name) + " and supplied_direction is " + str(supplied_direction) + " and relevant raycasts are ")
	for i in relevant_raycasts:
		print(i.name + ":" 
		+ str(i.position) 
		+ " " +str(rad_to_deg(i.position.angle_to(supplied_direction))) + ": ,")
	print("The interest array is set to: ")
	for i in interest_array:
		print(raycastChildren[index].name + ": " + str(final_interest[index]))
		index += 1
	print("And suggested vector is " + str(suggestedVector))
	debug = true
	index = 0
