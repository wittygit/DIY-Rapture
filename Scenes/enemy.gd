extends RigidBody3D
class_name Enemy

@onready var player : Player = %CharacterBody3D
@onready var animation_player = $AnimationPlayer
@onready var area_3d = $Area3D

var speed : float = 10
var direction : Vector3
var is_withered : bool = false
var isInArea: bool = false
var target_pos : Vector3 
var RAY_LENGTH: float = 100

func _ready():
	contact_monitor = true
	max_contacts_reported = 1
	
func _physics_process(delta):
	direction = player.position - position
	direction = direction.normalized()
	if !is_withered:
		var hit : Dictionary = raycast()
		if hit:
			if hit.collider is Player:
				print (hit.collider)
		constant_force = direction*speed
		
func Wither(seconds : float):
	is_withered = true
	constant_force = -constant_force;
	animation_player.play("wither",0.25)
	await get_tree().create_timer(seconds).timeout
	animation_player.play("chasing", 0.25)
	is_withered = false
	
func _on_body_entered(body):
	if body is Player:
		get_tree().change_scene_to_file("res://Scenes/death.tscn")
		
func raycast() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var origin = global_position
	var end = position - direction * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	
	return space_state.intersect_ray(query)
