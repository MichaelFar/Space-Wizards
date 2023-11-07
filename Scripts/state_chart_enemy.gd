extends CharacterBody2D

var player = null
@export var body_sprite : Sprite2D

var aggro_target = 3.0# time in seconds that the enemy will take to become aggro

func _on_area_2d_area_entered(area):
	
	$StateChart.send_event("player_entered")
	player = area.get_parent()

func _on_area_2d_area_exited(area):
	$StateChart.send_event("player_exited")


func _on_observing_state_physics_processing(delta):
	body_sprite.scale.x = 1.0 * sign(player.global_position.x - global_position.x)#Look at player on x-axis
