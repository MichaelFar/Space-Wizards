extends Node2D

#Root container node script
#Navigation Area and the Exclusion zone MUST be located at (0,0) or the points will not be correct and the ai will choose erroneous coordinates
#Calculates a list of valid points once as well as player position and delivers to the ai
#Also contains debug commands like escaping


@onready var exclusion_zone = $ExclusionZone

@onready var playerNode = $Player
@onready var navRegion = $NavigationRegion2D
var playerPosition = Vector2.ZERO
var validpoints = []
var enemyChildren = []
var playerAttackPoints = []
var reservedAttackPoints = []
var exclusionAreas = []
var exclusionDimensions = []
var frame = 0
var noReservedPoints = false
var enemyScene = 0
var playerScene = 0
var currentDifficulty = 0
var debug = false
var navOutline = null
var playerStartPos = Vector2.ZERO
var enemyStartPositions = []
enum {
	EASY,
	MEDIUM,
	HARD
}

func _ready():
	
	navOutline = navRegion.navigation_polygon.get_outline(0)
	var inclusion_area = get_dimensions(navOutline)
	
	#print(" min " + str(inclusionZone.shape.get_rect().position + inclusionZone.global_position) + "; max : " + str(inclusionZone.shape.get_rect().size + inclusionZone.global_position))
	get_exclusion_children()
	validpoints = get_valid_points(inclusion_area[0], inclusion_area[1])
	enemyScene = preload("res://Scenes/enemy_test.tscn")
	playerScene = preload("res://Scenes/player.tscn")
	
	
	get_enemy_children()
	for i in enemyChildren:
		enemyStartPositions.append(i.global_position)
		
	playerStartPos = playerNode.global_position
	

func _process(_delta):
	frame += 1
	debug = false
	if(Input.is_action_pressed("escape")):
		get_tree().quit()
	elif(Input.is_action_pressed("restart")):
		simple_restart()
	
	if(Input.is_action_just_pressed("Easy")):
		currentDifficulty = EASY
		apply_difficulty()
	if(Input.is_action_just_pressed("Medium")):
		currentDifficulty = MEDIUM
		apply_difficulty()
	if(Input.is_action_just_pressed("Hard")):
		currentDifficulty = HARD
		apply_difficulty()
	if(playerNode != null):
		playerPosition = playerNode.position
	if(Input.is_action_just_pressed("SpawnEnemyDemo")):
		spawn_scene(enemyScene)
	if(Input.is_action_just_pressed("relevant_raycasts")):
		debug = true
	
	noReservedPoints = !(true in reservedAttackPoints)
	
	if(debug):
		print("Outline 0 of nav region is " + str(navRegion.navigation_polygon.get_outline(0)))
	
func get_dimensions(vertices):
	var xArray = []
	var yArray = []
	for i in vertices:
		xArray.append(i.x)
		yArray.append(i.y)
	xArray.sort()
	yArray.sort()
	
	return [Vector2(xArray[0], yArray[0]), Vector2(xArray[xArray.size() - 1], yArray[yArray.size() - 1])]
# Called every frame. 'delta' is the elapsed time since the previous frame.

func get_valid_points(_min, _max):
	
	var validPoints = []
	#validPoints.resize((_max.x * _max.y))
	print("The value of _max.x is " + str(_max.x) + " and the value of _max.y is " + str(_max.y))
	print("The size of valid points is " + str(validPoints.size()))
	var geometry = Geometry2D
	var index = 0
	#print("Range for max x is " + str(range(_max.x)))
	#print("Range for max y is " + str(range(_max.y)))
	
#	for i in exclusionDimensions:
#		for j in range(_max.x):
#			for k in range(_max.y):
#				#if(index != validPoints.size()):
#				if(validPoints[index] != Vector2(j,k)):
#					if(!geometry.is_point_in_polygon(Vector2(j, k), i) && j > _min.x && k > _min.y):
#						validPoints[index] = Vector2(j,k)
#
#				index += 1	
#		index = 0
		
	for j in range(_max.x):
			for k in range(_max.y):
				#if(index != validPoints.size()):
				
				if(geometry.is_point_in_polygon(Vector2(j, k), navOutline)):
					validPoints.append(Vector2(j,k))
					#print("Added " + str(Vector2(j,k)) + " to validpoints")
	
	
	for i in validPoints:
		if i == null:
			print("Null found at " + str(validPoints.find(i)))
	index = 0
	for i in exclusionDimensions:
		print(str(i))
		for j in validPoints:
			
			if(geometry.is_point_in_polygon(j, i)):
				validPoints[validPoints.find(j)] = Vector2(1000000,1000000)
	var temp_points = []
	#print("Range for valid points is " + str(range(validPoints.size())))
	for i in validPoints:
		if(i.x < _max.x && i.y < _max.y):
			temp_points.append(i)
			index += 1
	#print("Range for temp points is " + str(range(validPoints.size())))
	#get_dimensions(temp_points)
	
	#print("The size of temp_points is " + str(temp_points.size()))
	validPoints = temp_points
	
	#print("The size of valid points is " + str(validPoints.size()))
	
	return validPoints
	
func compare_floats(a, b):
	return abs(a - b) < 0.000001
		

func compare_float_vectors(a, b):
	return abs(a - b) < Vector2(0.000001,0.000001)
		

func get_exclusion_children():
	for i in get_children():
		if 'ExclusionZone' in i.name:
			exclusionAreas.append(i)
			print("Added " + i.name + " to exclusion zones")
	for i in exclusionAreas:
		exclusionDimensions.append(i.get_children()[0].polygon)
		print("Exclusion polygon vertices for " + i.name + " are " + str(i.get_children()[0].polygon))

func spawn_scene(scene, randompoint = Vector2.ZERO):
	
	var random = RandomNumberGenerator.new()
	var node = scene.instantiate()
	if(!randompoint):
		node.global_position = validpoints[random.randi_range(0, validpoints.size() - 1)]
	else:
		node.global_position = randompoint
	add_child(node)
	return node
func get_enemy_children():
	
	enemyChildren = []
	
	for i in get_children():
		if i.has_method('node_type'):
			if(i.type == 'enemy_test'):
				enemyChildren.append(i)
				
func apply_difficulty():
	
	get_enemy_children()
	for i in enemyChildren:
		match currentDifficulty:
			EASY:
				i.stat_sheet.damage = 75
				i.stat_sheet.knockback_strength = 50
				i.stat_sheet.knockback_resistance = 0.0
				
			MEDIUM:
				i.stat_sheet.damage = 150
				i.stat_sheet.knockback_strength = 125
				i.stat_sheet.knockback_resistance = 25.0
				
			HARD:
				i.stat_sheet.damage = 200
				i.stat_sheet.knockback_strength = 150
				i.stat_sheet.knockback_resistance = 50.0

func simple_restart():
	get_enemy_children()
	for i in enemyChildren:
		i.queue_free()
	
	if(playerNode == null):
		playerNode = spawn_scene(playerScene, playerStartPos)
		playerNode.velocity = Vector2.ZERO
	else:
		playerNode.global_position = playerStartPos
		playerNode.update_healthbar(-10000)
	for i in enemyStartPositions:
		spawn_scene(enemyScene, i)
