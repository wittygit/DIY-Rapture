extends RigidBody3D
class_name Enemy


@onready var player : Player = $/root/Main/ColorRect/SubViewport/Player

@onready var animation_player = $AnimationPlayer

var speed : float = 10
var direction : Vector3
var look_direction : Vector3
var is_withered : bool = false
var isInArea: bool = false
var target_pos : Vector3 
var RAY_LENGTH: float = 100
var distance : float
var targetPos : Vector3
var raycastDistance = 400

@onready var sizzle: AudioStreamPlayer = $AudioStreamPlayer

func _ready():
	targetPos = position
	contact_monitor = true
	max_contacts_reported = 1
	
func _physics_process(delta):
	if !is_withered: apply_central_force(direction * speed)
	else: apply_central_force(-direction * speed)
	if linear_velocity.length() > speed:
		linear_velocity = linear_velocity.normalized() * speed
	if randf_range(0,1)>.05:return
	if player:
		distance = player.global_position.distance_squared_to(global_position)
		look_direction = (player.global_position+Vector3(0,.5,0) - global_position).normalized()
	if !is_withered:
		if distance<raycastDistance:
			var hit : Dictionary = raycast()
			if hit:
				if hit.collider is Player:
					print (hit.collider)
					targetPos = hit.position
			direction = (targetPos - global_position).normalized()
	
		
func Wither(seconds : float):
	if is_withered: return
	is_withered = true
	sizzle.play()
	#constant_force = -constant_force;
	animation_player.play("wither",0.25)
	await get_tree().create_timer(seconds).timeout
	animation_player.play("chasing", 0.25)
	is_withered = false

var hit : bool = false
func _on_body_entered(body):
	if body is Player:
		hit = true
		body.Damage(look_direction)



func raycast() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var origin = global_position+ Vector3(0, .5, 0)
	var end = origin+look_direction * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self]
	
	return space_state.intersect_ray(query)


func _on_body_exited(body: Node) -> void:
	if body is Player:
		hit = false
