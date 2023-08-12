extends Node2D

#Root container node script
#Navigation Area and the Exclusion zone MUST be located at (0,0) or the points will not be correct and the ai will choose erroneous coordinates
#Calculates a list of valid points once as well as player position and delivers to the ai
#Also contains debug commands like escaping


@onready var inclusionZone = $InclusionZone
@onready var exclusion_zone = $ExclusionZone

@onready var playerNode = $Player
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
var currentDifficulty = 0

enum {
	EASY,
	MEDIUM,
	HARD
}

func _ready():
	
	var inclusion_area = get_dimensions(inclusionZone.polygon)
	get_exclusion_children()
	validpoints = get_valid_points(inclusion_area[0], inclusion_area[1])
	enemyScene = preload("res://Scenes/enemy_test.tscn")
	
	get_enemy_children()
	
func _process(_delta):
	frame += 1
	if(Input.is_action_pressed("escape")):
		get_tree().quit()
	elif(Input.is_action_pressed("restart")):
		get_tree().reload_current_scene()
	
	if(Input.is_action_just_pressed("Easy")):
		currentDifficulty = EASY
		apply_difficulty()
	if(Input.is_action_just_pressed("Medium")):
		currentDifficulty = MEDIUM
		apply_difficulty()
	if(Input.is_action_just_pressed("Hard")):
		currentDifficulty = HARD
		apply_difficulty()
	playerPosition = playerNode.position
	if(Input.is_action_just_pressed("SpawnEnemyDemo")):
		spawn_enemy()
	
	noReservedPoints = !(true in reservedAttackPoints)
	
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
	validPoints.resize((_max.x * _max.y))
	print("The size of valid points is " + str(validPoints.size()))
	var geometry = Geometry2D
	var index = 0
	
	for i in exclusionDimensions:
		for j in range(_max.x):
			for k in range(_max.y):
				#if(index != validPoints.size()):
				if(validPoints[index] != Vector2(j,k)):
					if(!geometry.is_point_in_polygon(Vector2(j, k), i) && j > _min.x && k > _min.y):
						validPoints[index] = Vector2(j,k)
					
				index += 1	
		index = 0
	var temp_points = []
	
	for i in range(validPoints.size()):
		if(!validPoints[i] == null):
			temp_points.append(validPoints[i])
	
	validPoints = temp_points
	
	print("The size of valid points is " + str(validPoints.size()))
	
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

func spawn_enemy():
	
	var random = RandomNumberGenerator.new()
	var enemy = enemyScene.instantiate()
	enemy.global_position = Vector2(400, 200)
	add_child(enemy)
	
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
				
			MEDIUM:
				i.stat_sheet.damage = 150
				i.stat_sheet.knockback_strength = 125
			HARD:
				i.stat_sheet.damage = 200
				i.stat_sheet.knockback_strength = 150
