extends Node2D


@onready var navigationRegion = $NavigationRegion2D
@onready var exclusion_zone = $ExclusionZone#Get sibling
# Called when the node enters the scene tree for the first time.
@onready var playerNode = $Player
var playerPosition = Vector2.ZERO
var validpoints = []

func _ready():
	var inclusion_area = get_dimensions(navigationRegion.navigation_polygon.get_vertices())
	var inclusion_area_min = inclusion_area[0]
	var inclusion_area_max = inclusion_area[1]
	validpoints = get_valid_points(inclusion_area_min, inclusion_area_max)

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
	var polygon = exclusion_zone.get("polygon")

	for i in range(_max.x):
		for j in range(_max.y):
			if(!geometry.is_point_in_polygon(Vector2(i, j), polygon) && i > _min.x && j > _min.y):
				validPoints.append(Vector2(i,j))
			

	return validPoints
	
func _process(_delta):
	if(Input.is_action_pressed("escape")):
		get_tree().quit()
	playerPosition = playerNode.position
