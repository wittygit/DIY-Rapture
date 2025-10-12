extends CharacterBody3D
class_name Player
@onready var crucifix_pivot = $Tripod/crucifixPivot

@onready var crucifix : Crucifix = $Tripod/crucifixPivot/crucifix

@onready var crucifix_active_pos = $Tripod/crucifixActivePos
var crucifix_base_pos : Vector3
@onready var console: Console = $"../../Console"

@export var sens : Vector2 = Vector2(3, 2)

@export var maxCamTilt : float = 50
@export var minCamTilt : float = -50
@export var crucifix_snapiness : float = 8
@export var crucifix_speed : float = 6
@export var look_snapiness : float = 5

@onready var tripod = $Tripod
@onready var cam = $Tripod/Camera3D

const FOV_MULT: float = 1.5
var gravity : Vector3 = Vector3(0,-9.8,0)
var speed : float = 4
var walking_speed: float = 4
var crucifixing_speed : float = 1.5
var is_moving : bool = false
var is_crucifixing : bool = false

var bobFreq = 2
var bobAmp = 0.06
var bobTime: float = 0
var baseFov = 80

var messages = ["The Rapture begins.","Alas, I have been Foresaken.","I must ascend through the darkness to reach The Light.","Climb to the fifth floor to Rapture yourself and rejoin your Order.", "Use the left button to move forward and hold the right button to defend yourself."]
var current_message = 0
var message_duration : float = 6
var time : float = 0
var crucifix_global_goal_rot : Vector3 = Vector3.FORWARD

var look_force : Vector2

const RAY_LENGTH : float = 2

func _ready():
	crucifix_base_pos = crucifix_pivot.position


func _physics_process(delta):
	time += delta
	if time > message_duration:
		if current_message<messages.size():
			console.SendMessage(messages[current_message], message_duration, Color.BLACK)
			current_message+=1
			time = 0

	
	
	handleInput()
	crucifix_global_goal_rot.y += look_force.x*delta*sens.x
	crucifix_global_goal_rot.x += -look_force.y*delta*sens.y
	
	crucifix_global_goal_rot.x = clamp(crucifix_global_goal_rot.x, deg_to_rad(minCamTilt), deg_to_rad(maxCamTilt))
	
	aimCrucifix(delta)
	aimHead(delta)
	
	if not is_on_floor():
		velocity += gravity * delta

	if Input.is_action_pressed("exit"):
		get_tree().quit()

	var direction
	if (is_moving): direction = (transform.basis * Vector3.FORWARD).normalized()
	else:
		direction = Vector3.ZERO
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2)
		 
	#bob time!!!!!
	bobTime += delta * velocity.length() * float(is_on_floor()) # basically the bool in a float will give 0 or 1 super clever solution by LegionGames
	cam.transform.origin = head_bob(bobTime)
	
	#fov stuff
	var clampedVelocity = clamp (velocity.length(), 0.5, speed * 2)
	var targetFov = baseFov + FOV_MULT * clampedVelocity
	cam.fov = lerp(cam.fov, targetFov, delta * 7)
	
	move_and_slide()

func head_bob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bobFreq) * bobAmp
	pos.x = cos(time * bobFreq/2) * bobAmp
	return pos
	

func handleInput():
	look_force.x = Input.get_axis("lookRight", "lookLeft")
	look_force.y = Input.get_axis("lookUp", "lookDown")
	
	if Input.is_action_pressed("forward"):
		is_moving = true
	else:
		is_moving = false
	if Input.is_action_pressed("crucifix"):
		is_crucifixing = true
	else:
		is_crucifixing = false


func aimCrucifix(delta):
	crucifix_pivot.global_rotation.y = (lerp_angle(crucifix_pivot.global_rotation.y,crucifix_global_goal_rot.y, crucifix_snapiness*delta))
	crucifix.global_rotation.x = (lerp_angle(crucifix.global_rotation.x, crucifix_global_goal_rot.x, crucifix_snapiness*delta))
	
	if (is_crucifixing):
		crucifix_pivot.position = (lerp(crucifix_pivot.position, crucifix_active_pos.position, crucifix_snapiness * delta))
		crucifix.beamStrength = (lerp(crucifix.beamStrength,1.0, crucifix_snapiness * delta))
		cam.fov = (lerp(cam.fov,baseFov/10., crucifix_snapiness/3 *delta))
		speed = crucifixing_speed
	else:
		crucifix_pivot.position = (lerp(crucifix_pivot.position, crucifix_base_pos, crucifix_snapiness*delta))
		crucifix.beamStrength = (lerp(crucifix.beamStrength,0.0, crucifix_snapiness * delta))
		cam.fov = (lerp(cam.fov,float(baseFov), crucifix_snapiness * delta))
		speed = walking_speed

func aimHead(delta : float):
	global_rotation.y = (lerp_angle(global_rotation.y ,crucifix_global_goal_rot.y, look_snapiness*delta))
	cam.global_rotation.x = (lerp_angle(cam.global_rotation.x, crucifix_global_goal_rot.x, look_snapiness*delta))

func raycast() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var origin = crucifix.global_position
	var end = origin -crucifix.get_global_transform().basis.z*RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	
	return space_state.intersect_ray(query)
	
