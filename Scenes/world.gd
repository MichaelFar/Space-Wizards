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

signal spawned_enemy
enum {
	EASY,
	MEDIUM,
	HARD
}

func _ready():
	
	navOutline = navRegion.navigation_polygon.get_outline(0)
	var inclusion_area = get_dimensions(navOutline)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
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
	if(Input.is_action_just_released("fullscreen")):
		if(DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)	
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


func get_valid_points(_min, _max):
	
	var validPoints = []
	print("The value of _max.x is " + str(_max.x) + " and the value of _max.y is " + str(_max.y))
	print("The size of valid points is " + str(validPoints.size()))
	var geometry = Geometry2D
		
	for j in range(_max.x):
			for k in range(_max.y):
				
				if(geometry.is_point_in_polygon(Vector2(j, k), navOutline)):
					validPoints.append(Vector2(j,k))
			
	for i in validPoints:
		if i == null:
			print("Null found at " + str(validPoints.find(i)))
	
	for i in exclusionDimensions:
		print(str(i))
		for j in validPoints:
			
			if(geometry.is_point_in_polygon(j, i)):
				validPoints[validPoints.find(j)] = Vector2(1000000,1000000)
	var temp_points = []
	
	for i in validPoints:
		if(i.x < _max.x && i.y < _max.y):
			temp_points.append(i)
	
	validPoints = temp_points
	
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
	get_enemy_children()
	
	return node
	
func get_enemy_children():
	
	enemyChildren = []
	
	for i in get_children():
		if i.has_method('node_type'):
			if(i.type == 'enemy_test'):
				enemyChildren.append(i)
				spawned_enemy.emit(i)
				
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
		playerNode.velocity = Vector2.ZERO
		playerNode.global_position = playerStartPos
		playerNode.update_healthbar(-(playerNode.max_health))#Sets the health to max
	for i in enemyStartPositions:
		spawn_scene(enemyScene, i)

