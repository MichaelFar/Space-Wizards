extends Node2D

#Root container node script
#Navigation Area and the Exclusion zone MUST be located at (0,0) or the points will not be correct and the ai will choose erroneous coordinates
#Calculates a list of valid points once as well as player position and delivers to the ai
#Also contains debug commands like escaping


@onready var navigationRegion = $NavigationRegion2D
@onready var exclusion_zone = $ExclusionZone#Get sibling

@onready var playerNode = $Player
var playerPosition = Vector2.ZERO
var validpoints = []
var enemyChildren = []
var playerAttackPoints = []
var reservedAttackPoints = []
var exclusionArea = []

func _ready():
	
	var inclusion_area = get_dimensions(navigationRegion.navigation_polygon.get_vertices())
	exclusionArea = get_dimensions(exclusion_zone.polygon)
	validpoints = get_valid_points(inclusion_area[0], inclusion_area[1])
	playerNode.s_attack_points.connect(get_player_attack_points)
	
	for i in get_children():
		if 'Enemy_' in i.name:
			enemyChildren.append(i)
	
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
	
	var geometry = Geometry2D
	var polygon = exclusion_zone.polygon

	for i in range(_max.x):
		for j in range(_max.y):
			if(!geometry.is_point_in_polygon(Vector2(i, j), polygon) && i > _min.x && j > _min.y):
				validPoints.append(Vector2(i,j))
				
	return validPoints
	
func _process(_delta):
	
	if(Input.is_action_pressed("escape")):
		get_tree().quit()
	elif(Input.is_action_pressed("restart")):
		get_tree().reload_current_scene()
	playerPosition = playerNode.position
	

func get_player_attack_points(attack_points):
	
	playerAttackPoints = attack_points
	
	if(reservedAttackPoints.size() < playerAttackPoints.size()):
		reservedAttackPoints.resize(playerAttackPoints.size())
		for i in reservedAttackPoints:
			i = false

func compare_floats(a, b):
	if abs(a - b) < 0.000001:
		return true
	return false

func compare_float_vectors(a, b):
	if abs(a - b) < Vector2(0.000001,0.000001):
		return true
	return false

